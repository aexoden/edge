#!/usr/bin/env python3
#
# Copyright (c) 2015 Jason Lynch <jason@calindora.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

import os
import re
import statistics
import sys

from collections import OrderedDict
from typing import Any, Optional, TextIO, Union

import numpy

from scipy import stats

import matplotlib
matplotlib.use('Agg')

import matplotlib.pyplot as plt  # noqa: E402

from matplotlib.font_manager import FontProperties  # noqa: E402

COLORS = [
    '#e6194B',
    '#3cb44b',
    '#ffe119',
    '#4363d8',
    '#f58231',
    '#911eb4',
    '#42d4f4',
    '#f032e6',
    '#bfef45',
    '#fabed4',
    '#469990',
    '#dcbeff',
    '#9A6324',
    '#fffac8',
    '#800000',
    '#aaffc3',
    '#808000',
    '#ffd8b1',
    '#000075',
    '#a9a9a9'
]


#
# Functions
#

def is_scripted(formation: int):
    if formation >= 220 and formation <= 256:
        return True
    elif formation >= 420 and formation <= 442:
        return True
    else:
        return False


def describe_formation(formation: int):
    formations = {
        42: 'Gargoyle x1, Cocktric x2',
        109: 'Centaur x1, IceBeast x2',
        111: 'Centaur x3',
        117: 'Carapace x2, Ice Liz x2',
        199: 'D.Machin x1',
        200: 'Grind Fight',
        220: 'Elements',
        221: 'CPU',
        222: 'D.Mist',
        223: 'Octomamm',
        224: 'Antlion',
        225: 'MomBomb',
        226: 'Milon',
        227: 'Milon Z',
        228: 'Baigan',
        229: 'Kainazzo',
        231: 'Dark Elf',
        232: 'Magus Sisters',
        234: 'Valvalis',
        235: 'FloatEye (intro)',
        237: 'Officer x1, Soldier x3',
        239: 'WaterHag',
        240: 'Imp Cap. x3',
        242: 'Karate',
        243: 'Golbez (Tellah)',
        245: 'Raven (intro)',
        246: 'D.Knight',
        247: 'General x1, Fighter x2',
        248: 'Weeper x1, WaterHag x1, Imp Cap. x1',
        249: 'Gargoyle x1',
        250: 'Guard x2',
        254: 'Q.Eblan/K.Eblan',
        255: 'Rubicant',
        256: 'Dark Imp x3',
        344: 'Arachne x1',
        345: 'Arachne x2',
        409: 'Red D. x1',
        423: 'Calbrena',
        425: 'Dr. Lugae/Balnab',
        435: 'Zemus',
        437: 'Dr. Lugae',
        438: 'Golbez',
        439: 'Zeromus',
        451: 'FlameDog',
    }

    return formations[formation] if formation in formations else 'Formation #{}'.format(formation)


def format_time(frames: float):
    seconds = frames / 60.0988
    return '{:.0f}:{:02.0f}:{:05.2f}'.format(seconds // 3600, (seconds // 60) % 60, seconds % 60)


def get_battle_data(logs: list['Log'], classified: bool = False, strat: bool = True, agility: bool = False):
    battles: OrderedDict[str, Any] = OrderedDict()

    for log in logs:
        for battle in log.battles:
            if battle['result'].startswith('Victory') or battle['result'].startswith('Perished') or battle['result'].startswith('Stalemate'):
                key = '{:03}'.format(battle['formation'])

                if strat and battle['strat']:
                    key = '{}-{}'.format(key, battle['strat'])

                if key not in battles:
                    if classified:
                        battles[key] = {}
                    else:
                        battles[key] = {'formation': battle['formation'], 'strat': battle['strat'] if strat else set([battle['strat']]) if battle['strat'] else set(), 'count': 0, 'data': [] if strat or not battle['strat'] else {}}

                if classified:
                    if agility:
                        subkey = (battle['type'], ' '.join(map(str, battle['enemy_agility'])), battle['party_agility'])
                    else:
                        subkey = (battle['type'], ' '.join(map(str, battle['enemy_agility'])), battle['party_formation'])

                    if subkey not in battles[key]:
                        battles[key][subkey] = {'formation': battle['formation'], 'strat': battle['strat'] if strat else set([battle['strat']]), 'count': 0, 'data': [] if strat or not battle['strat'] else {}}

                    battles[key][subkey]['count'] += 1

                    if not strat and battle['strat'] and battle['strat'] not in battles[key][subkey]['strat']:
                        battles[key][subkey]['strat'].add(battle['strat'])

                    if not strat and battle['strat'] and battle['strat'] not in battles[key][subkey]['data']:
                        battles[key][subkey]['data'][battle['strat']] = []

                    if 'success' in battle:
                        if 'success' not in battles[key][subkey]:
                            battles[key][subkey]['success'] = 0
                        battles[key][subkey]['success'] += 1

                    if battle['result'].startswith('Victory') or battle['result'].startswith('Stalemate'):
                        if strat or (not strat and not battle['strat']):
                            battles[key][subkey]['data'].append(battle['frames'])
                        else:
                            battles[key][subkey]['data'][battle['strat']].append(battle['frames'])
                else:
                    battles[key]['count'] += 1

                    if not strat and battle['strat'] and battle['strat'] not in battles[key]['strat']:
                        battles[key]['strat'].add(battle['strat'])

                    if not strat and battle['strat'] and battle['strat'] not in battles[key]['data']:
                        battles[key]['data'][battle['strat']] = []

                    if 'success' in battle:
                        if 'success' not in battles[key]:
                            battles[key]['success'] = 0
                        battles[key]['success'] += 1

                    if battle['result'].startswith('Victory') or battle['result'].startswith('Stalemate'):
                        if strat or (not strat and not battle['strat']):
                            battles[key]['data'].append(battle['frames'])
                        else:
                            battles[key]['data'][battle['strat']].append(battle['frames'])

    return battles


def get_split_data(logs: list['Log'], cumulative: bool = True):
    splits: dict[str, list[int]] = {}

    for log in logs:
        for split, data in log.splits.items():
            if split not in splits:
                splits[split] = []

            if cumulative:
                splits[split].append(data['total'])
            else:
                splits[split].append(data['current'])

    return splits


def get_seed_data(logs: list['Log']):
    seeds: dict[str, dict[int, dict[str, Any]]] = {}

    for log in logs:
        if log.route not in seeds:
            seeds[log.route] = {}

        if log.step_seed not in seeds[log.route]:
            seeds[log.route][log.step_seed] = {'data': [], 'best_splits': {}, 'battles': 0, 'back_attack_count': 0}

        if log.success:
            seeds[log.route][log.step_seed]['data'].append(log.frames)
            seeds[log.route][log.step_seed]['battles'] += log.random_battle_count
            seeds[log.route][log.step_seed]['back_attack_count'] += log.back_attack_count

            for split in log.splits:
                if split not in seeds[log.route][log.step_seed]['best_splits'] or log.splits[split]['current'] < seeds[log.route][log.step_seed]['best_splits'][split]:
                    seeds[log.route][log.step_seed]['best_splits'][split] = log.splits[split]['current']

    return seeds


def get_sum_of_best(logs: list['Log']):
    seeds = get_seed_data(logs)
    splits: dict[str, int] = {}

    for route in seeds.values():
        for data in route.values():
            for split, value in data['best_splits'].items():
                if split not in splits or value < splits[split]:
                    splits[split] = value

    return sum(splits.values())


#
# Classes
#

class Log(object):
    def __init__(self, filename: str):
        self._battles: list[dict[str, Any]] = []
        self._splits: dict[str, dict[str, int]] = {}
        self._success: bool = False
        self._frames: Optional[int] = None
        self._route: Optional[str] = None
        self._rng_seed = None
        self._step_seed = None
        self._last_frame = None
        self._reset_for_time = False
        self._reset_for_chocobo = False
        self._reset_for_fireclaw = False
        self._reset_for_shield = False
        self._version: Optional[str] = None

        self._parse_file(filename)

        if self._route == 'paladin':  # type: ignore
            final_split = 'Paladin'
        else:
            final_split = 'Zeromus Death'

        if final_split in self._splits:
            self._success = True
            self._frames = self._splits[final_split]['total']

    @property
    def back_attack_count(self):
        return sum([1 if x['type'] in ['Back Attack', 'Surprised'] and not x['scripted'] else 0 for x in self._battles])

    @property
    def random_battle_count(self):
        return sum([1 if not x['scripted'] else 0 for x in self._battles])

    @property
    def battles(self):
        return self._battles

    @property
    def frames(self):
        if self._frames is not None:
            return self._frames
        else:
            return -1

    @property
    def max_frame(self):
        return max([x['total'] for x in self._splits.values()]) if len(self._splits) > 0 else 0

    @property
    def last_frame(self):
        if self._last_frame is not None:
            return self._last_frame
        else:
            return -1

    @property
    def route(self):
        if self._route is not None:
            return self._route
        else:
            return 'None'

    @property
    def splits(self):
        return self._splits

    @property
    def valid(self):
        return self._last_frame is not None

    @property
    def success(self):
        return self._success

    @property
    def rng_seed(self):
        return self._rng_seed

    @property
    def step_seed(self):
        if self._step_seed is not None:
            return self._step_seed
        else:
            return -1

    @property
    def non_battle_frames(self):
        if self.frames is not None:
            return self.frames - sum([x['frames'] for x in self._battles])
        else:
            return None

    @property
    def result(self):
        assert(self.last_frame is not None)

        if self.success:
            assert(self.frames is not None)
            return format_time(self.frames)
        elif self._reset_for_time:
            return 'Ragequit because of bad time after {} ({})'.format(sorted(self._splits.items(), key=lambda x: x[1]['total'])[-1][0], format_time(self.last_frame))
        elif self._reset_for_chocobo:
            return 'Ragequit because of bad yellow chocobo ({})'.format(format_time(self.last_frame))
        elif self._reset_for_fireclaw:
            return 'Ragequit because of failed FireClaw dupe ({})'.format(format_time(self.last_frame))
        elif self._reset_for_shield:
            return 'Ragequit because of failed shield dupe ({})'.format(format_time(self.last_frame))
        elif len(self._battles) > 0 and self._battles[-1]['result'].startswith('Perished'):
            return 'Died to {} ({})'.format(describe_formation(self._battles[-1]['formation']), format_time(self.last_frame))
        else:
            return 'Unknown Failure ({})'.format(format_time(self.last_frame))

    @property
    def version(self):
        return self._version

    def _parse_file(self, filename: str):
        with open(filename) as f:
            current_battle: dict[str, Any] = {}
            base_frame = None
            last_split = None

            for line in f:
                line_type, fields = self._parse_line(line.strip())

                if not fields:
                    continue

                if base_frame is not None:
                    self._last_frame = int(fields['frame']) - base_frame

                if line_type == 'split':
                    if fields['split'] == 'Start':
                        base_frame = int(fields['frame'])
                        last_split = base_frame
                    else:
                        assert(base_frame is not None and last_split is not None)
                        self._splits[fields['split']] = {'current': int(fields['frame']) - last_split, 'total': int(fields['frame']) - base_frame}
                        last_split = int(fields['frame'])
                elif line_type == 'route':
                    self._route = fields['route']
                elif line_type == 'rng_seed':
                    self._rng_seed = int(fields['seed'])
                elif line_type == 'step_seed':
                    self._step_seed = int(fields['seed'])
                elif line_type == 'version':
                    self._version = fields['version']
                elif line_type == 'reset_for_time':
                    self._reset_for_time = True
                elif line_type == 'reset_for_chocobo':
                    self._reset_for_chocobo = True
                elif line_type == 'reset_for_fireclaw':
                    self._reset_for_fireclaw = True
                elif line_type == 'reset_for_shield':
                    self._reset_for_shield = True
                elif line_type == 'battle_start':
                    if current_battle:
                        print('WARNING: A new battle has started without finishing the previous one while parsing {}'.format(filename))

                    current_battle = {
                        'formation': int(fields['formation']),
                        'type': fields['type'],
                        'strat': 'default',
                        'scripted': is_scripted(int(fields['formation'])),
                        'party_level': None if fields['party_level'] == '-' else int(fields['party_level']),
                        'enemy_level': None if fields['enemy_level'] == '-' else int(fields['enemy_level']),
                    }
                elif line_type == 'battle_action':
                    if current_battle['formation'] == 226 and current_battle['strat'] == 'carrot':
                        if fields['action'].endswith('Carrot') and 'Enemy #0' in fields['result']:
                            current_battle['success'] = True
                    elif current_battle['formation'] == 227 and current_battle['strat'] == 'trashcan':
                        if fields['action'].endswith('TrashCan') and 'Enemy #0' in fields['result']:
                            current_battle['success'] = True
                elif line_type == 'battle_strat':
                    current_battle['strat'] = fields['strat']
                elif line_type == 'battle_enemy_agility':
                    current_battle['enemy_agility'] = list(map(int, fields['agility'].split()))
                elif line_type == 'battle_party_formation':
                    current_battle['party_formation'] = fields['formation']
                elif line_type == 'battle_party_agility':
                    current_battle['party_agility'] = fields['agility']
                elif line_type == 'battle_stop':
                    current_battle['frames'] = int(fields['frames'])
                    current_battle['dropped_gp'] = int(fields['dropped_gp'])
                    current_battle['result'] = fields['result']
                    self._battles.append(current_battle)
                    current_battle = {}

    def _parse_line(self, line: str) -> tuple[Optional[str], Optional[dict[str, Union[str, Any]]]]:
        base_regex = '(?P<timestamp>.*) :: (?P<frame>.*) :: (?P<time>.*) :: (?P<game_time>.*) :: '

        regexes = {
            'battle_action': r'Action: (?P<actor>.*) (?P<action>(uses|casts|attacks) [^ ]*)( and (?P<result>(hits|misses|heals).*))?',
            'battle_start': r'Battle Start: (?P<description>.*) \((?P<formation>.*)/(?P<type>.*)/(?P<party_level>.*)/(?P<enemy_level>.*)\)',
            'battle_strat': r'Battle Strat: (?P<strat>.*)',
            'battle_enemy_agility': r'Enemy Agility: (?P<agility>.*)',
            'battle_party_formation': r'Party Formation: (?P<formation>.*)',
            'battle_party_agility': r'Party Agility: (?P<agility>.*)',
            'battle_stop': r'Battle Complete: (?P<description>.*) \((?P<formation>.*)/(?P<frames>.*) frames/(?P<dropped_gp>.*) GP dropped/(?P<result>.*)\)',
            'inventory': r'Inventory: .*',
            'route': r'Route: (?P<route>.*)',
            'rng_seed': r'RNG Seed: (?P<seed>.*)',
            'reset_for_time': r'Resetting for time...',
            'reset_for_chocobo': r'Resetting due to bad yellow chocobo...',
            'reset_for_fireclaw': r'Resetting due to failed FireClaw dupe...',
            'reset_for_shield': r'Resetting due to failed shield dupe...',
            'step_seed': r'Encounter Seed: (?P<seed>.*)',
            'sequence': r'Sequence: (?P<sequence>.*)',
            'split': r'Split: (?P<split>.*)',
            'version': r'Version: (?P<version>.*)',
            '_ignore': r'(Edge Final Fantasy IV|--------------------|Note:|Action: \(debug\)|Deciding|Kain action|Beginning Full Run|WARNING|Setting Initial Seed|Yellow Chocobo Coordinates|Current Glitch Floor|Rebooting|Load game screen|New Seed|Setting encounter seed|Detected|Zeromus has|Cecil|Do not have|Battle Menu|Party Experience)',
        }

        for line_type, regex in regexes.items():
            matches = re.match(base_regex + regex, line)

            if matches:
                return (line_type, matches.groupdict())

        print('UNRECOGNIZED LINE: {}'.format(line))
        return (None, None)


#
# Image Functions
#

def img_output_battle(f: str, key: str, data: dict[str, Any]):
    figure = plt.figure(figsize=(12.0, 4.8))
    figure.suptitle('{} Battle Time'.format(describe_formation(data['formation'])))

    axis_min = None
    axis_max = None

    if len(data['strat']) > 0:
        values = {}

        for strat, strat_data in data['data'].items():
            values[strat] = [x / 60.0988 for x in strat_data]
    else:
        values = {'Default Strat': [x / 60.0988 for x in data['data']]}

    mintmp = [min(x) for x in values.values() if len(x) > 0]
    maxtmp = [max(x) for x in values.values() if len(x) > 0]

    axis_min = min(mintmp) - 10 if len(mintmp) > 0 else 0
    axis_max = max(maxtmp) + 10 if len(maxtmp) > 0 else 300

    subplot = figure.add_subplot(111)
    axis = numpy.linspace(axis_min, axis_max)  # type: ignore

    for i, (strat, strat_data) in enumerate(values.items()):
        x = numpy.array(strat_data, dtype=float)  # type: ignore

        try:
            kde = stats.gaussian_kde(x)
        except Exception:
            kde = None

        subplot.plot(x, numpy.zeros(x.shape), '+', ms=20, color=COLORS[i % len(COLORS)])  # type: ignore

        if kde:
            subplot.plot(axis, kde(axis), '-', color=COLORS[i % len(COLORS)], label=strat)

    fontprop = FontProperties()
    fontprop.set_size('small')

    if len(data['strat']) > 0:
        box = subplot.get_position()
        subplot.set_position([box.x0, box.y0, box.width * 0.8, box.height])
        plt.legend(loc="center left", bbox_to_anchor=(1, 0.5), prop=fontprop)

    plt.xlabel("Battle Time (seconds)")  # type: ignore
    plt.ylabel("Probability")  # type: ignore
    plt.savefig(f)
    plt.close(figure)


def img_output_runs(f: str, logs: list['Log'], seed: Optional[int] = False):
    figure = plt.figure(figsize=(12.0, 4.8))
    figure.suptitle('Run Completion Times')

    axis_min = None
    axis_max = None

    values: dict[str, list[float]] = {}

    for log in logs:
        if seed:
            key = '{}-{}'.format(log.route, log.step_seed)
        else:
            key = log.route

        if log.success:
            if key not in values:
                values[key] = []

            values[key].append(log.frames * 655171 / 39375000)

    mintmp = [min(x) for x in values.values() if len(x) > 0]
    maxtmp = [max(x) for x in values.values() if len(x) > 0]

    axis_min = min(mintmp) - 10 if len(mintmp) > 0 else 0
    axis_max = max(maxtmp) + 10 if len(maxtmp) > 0 else 300

    subplot = figure.add_subplot(111)
    axis = numpy.linspace(axis_min, axis_max)  # type: ignore

    for i, (category, data) in enumerate(values.items()):
        x = numpy.array(data, dtype=float)  # type: ignore

        try:
            kde = stats.gaussian_kde(x)
        except Exception:
            kde = None

        subplot.plot(x, numpy.zeros(x.shape), '+', ms=20, color=COLORS[i % len(COLORS)])  # type: ignore

        if kde:
            subplot.plot(axis, kde(axis), '-', color=COLORS[i % len(COLORS)], label=category)

    fontprop = FontProperties()
    fontprop.set_size('small')

    box = subplot.get_position()
    subplot.set_position([box.x0, box.y0, box.width * 0.8, box.height])
    plt.legend(loc="center left", bbox_to_anchor=(1, 0.5), prop=fontprop)

    plt.xlabel("Run Time (seconds)")  # type: ignore
    plt.ylabel("Probability")  # type: ignore
    plt.savefig(f)
    plt.close(figure)


#
# HTML Functions
#

def html_output_header(f: TextIO):
    f.write('<!DOCTYPE html>\n')
    f.write('<html lang="en">\n')
    f.write('\t<head>\n')
    f.write('\t\t<meta charset="utf-8">\n')
    f.write('\t\t<title>Edge Log Analysis</title>\n')
    f.write('\t\t<link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">\n')
    f.write('\t\t<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.28.9/css/theme.bootstrap_3.min.css" integrity="sha256-kHFAS2GpR7DKNTb9SMX1aaoBxjLsZyeAX2Dh7h4UB1g=" crossorigin="anonymous" />\n')
    f.write('\t\t<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4=" crossorigin="anonymous"></script>\n')
    f.write('\t\t<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.28.9/js/jquery.tablesorter.min.js" integrity="sha256-kgWKzrQM9EptuijrOz9DZw4YTl/iEtgLzcfCB2WfV2I=" crossorigin="anonymous"></script>\n')
    f.write('\t\t<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.28.9/js/jquery.tablesorter.widgets.min.js" integrity="sha256-68t49lPEpa0S/ohrRPVYgcHaMn4HyOKfVomAVMAXNoM=" crossorigin="anonymous"></script>\n')
    f.write('\t\t<meta name="viewport" content="width=device-width, initial-scale=1">\n')
    f.write('\t\t<style type="text/css">\n')
    f.write('\t\t\t.bold { font-weight: bold; }\n')
    f.write('\t\t</style>\n')
    f.write('\t</head>\n')
    f.write('\t<body>\n')
    f.write('\t\t<div class="container">\n')
    f.write('\t\t\t<h1>Edge Log Analysis</h1>\n')
    f.write('\t\t\t<h2>Introduction</h2>\n')
    f.write('\t\t\t<p>This page is a statistical analysis of the log files generated by Edge, the Final Fantasy IV speed running bot.</p>\n')


def html_output_footer(f: TextIO):
    f.write('\t\t</div>\n')
    f.write('\t\t<script>\n')
    f.write('''$.extend($.tablesorter.themes.bootstrap, {table: 'table table-bordered table-striped'});''')
    f.write('\t\t\t$(document).ready(function()\n')
    f.write('\t\t\t\t{\n')
    f.write('''var options = {
        theme: "bootstrap",
        headerTemplate: "{content} {icon}",
        widgets: ["uitheme", "zebra"]
    };\n''')
    f.write('\t\t\t\t\t$("#seeds").tablesorter(options);\n')
    f.write('\t\t\t\t\t$("#runs").tablesorter(options);\n')
    f.write('\t\t\t\t}\n')
    f.write('\t\t\t);\n')
    f.write('\t\t</script>\n')
    f.write('\t</body>\n')
    f.write('</html>\n')


def html_output_basic_statistics(f: TextIO, logs: list[Log]):
    f.write('\t\t\t<h2>Basic Statistics</h2>\n')
    f.write('\t\t\t<dl class="dl-horizontal">\n')
    f.write('\t\t\t\t<dt>Number of Logs</dt><dd>{}</dd>\n'.format(len(logs)))
    if len([x for x in logs if x.success]) > 0:
        f.write('\t\t\t\t<dt>Best Time</dt><dd>{}</dd>\n'.format(format_time(min([x.frames for x in logs if x.success]))))
        f.write('\t\t\t\t<dt>Sum of Best</dt><dd>{}</dd>\n'.format(format_time(get_sum_of_best(logs))))
    f.write('\t\t\t</dl>\n')


def html_output_splits(f: TextIO, logs: list[Log]):
    splits = {}

    f.write('\t\t\t<h2>Splits</h2>\n')
    f.write('\t\t\t<table class="table table-striped">\n')
    f.write('\t\t\t\t<thead>\n')
    f.write('\t\t\t\t\t<tr>\n')
    f.write('\t\t\t\t\t\t<th>Split</th>\n')
    f.write('\t\t\t\t\t\t<th>Count</th>\n')
    f.write('\t\t\t\t\t\t<th>Minimum</th>\n')
    f.write('\t\t\t\t\t\t<th>Maximum</th>\n')
    f.write('\t\t\t\t\t\t<th>Median</th>\n')
    f.write('\t\t\t\t\t</tr>\n')
    f.write('\t\t\t\t</thead>\n')
    f.write('\t\t\t\t<tbody>\n')

    splits = get_split_data(logs, True)

    for split, data in sorted(splits.items(), key=lambda x: min(x[1])):
        f.write('\t\t\t\t\t<tr>\n')
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(split))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(len(data)))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(min(data))))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(max(data))))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(statistics.median(data))))
        f.write('\t\t\t\t\t</tr>\n')

    f.write('\t\t\t\t</tbody>\n')
    f.write('\t\t\t</table>\n')


def html_output_battles(f: TextIO, logs: list[Log]):
    f.write('\t\t\t<h2>Battles</h2>\n')
    f.write('\t\t\t<table class="table table-striped">\n')
    f.write('\t\t\t\t<thead>\n')
    f.write('\t\t\t\t\t<tr>\n')
    f.write('\t\t\t\t\t\t<th>Description</th>\n')
    f.write('\t\t\t\t\t\t<th>Strat</th>\n')
    f.write('\t\t\t\t\t\t<th>Count</th>\n')
    f.write('\t\t\t\t\t\t<th>Victory Rate</th>\n')
    f.write('\t\t\t\t\t\t<th>Success Rate</th>\n')
    f.write('\t\t\t\t\t\t<th>Minimum</th>\n')
    f.write('\t\t\t\t\t\t<th>Maximum</th>\n')
    f.write('\t\t\t\t\t\t<th>Median</th>\n')
    f.write('\t\t\t\t\t</tr>\n')
    f.write('\t\t\t\t</thead>\n')
    f.write('\t\t\t\t<tbody>\n')

    battles: OrderedDict[str, Any] = OrderedDict()
    ordering = {}
    index = 0

    for log in logs:
        for battle in log.battles:
            if battle['result'].startswith('Victory') or battle['result'].startswith('Perished') or battle['result'].startswith('Stalemate'):
                if battle['formation'] not in ordering:
                    ordering[battle['formation']] = index
                    index += 1

                key = '{:03}'.format(battle['formation'])

                if battle['strat']:
                    key = '{}-{}'.format(key, battle['strat'])

                if key not in battles:
                    battles[key] = {'formation': battle['formation'], 'strat': battle['strat'], 'data': [], 'count': 0, 'index': ordering[battle['formation']]}

                if 'success' in battle:
                    if 'success' not in battles[key]:
                        battles[key]['success'] = 0
                    battles[key]['success'] += battle['success']

                if battle['result'].startswith('Victory') or battle['result'].startswith('Stalemate'):
                    battles[key]['data'].append(battle['frames'])

                battles[key]['count'] += 1

    for key, data in sorted(battles.items(), key=lambda x: (x[1]['index'], x[1]['strat'])):
        f.write('\t\t\t\t\t<tr>\n')
        f.write('\t\t\t\t\t\t<td><a href="battles/{}.html">{}</a></td>\n'.format(key, describe_formation(data['formation'])))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(data['strat'] if data['strat'] else '-'))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(data['count']))
        f.write('\t\t\t\t\t\t<td>{:.3f}%</td>\n'.format(len(data['data']) * 100 / data['count']))

        if 'success' in data:
            f.write('\t\t\t\t\t\t<td>{:.3f}%</td>\n'.format(data['success'] * 100 / data['count']))
        else:
            f.write('\t\t\t\t\t\t<td>-</td>\n')

        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(min(data['data'])) if len(data['data']) > 0 else 'N/A'))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(max(data['data'])) if len(data['data']) > 0 else 'N/A'))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(statistics.median(data['data'])) if len(data['data']) > 0 else 'N/A'))
        f.write('\t\t\t\t\t</tr>\n')

    f.write('\t\t\t\t</tbody>\n')
    f.write('\t\t\t</table>\n')


def html_output_table(headers: list[str], rows: list[list[Any]]):
    f.write('\t\t\t<table class="table table-striped">\n')
    f.write('\t\t\t\t<thead>\n')
    f.write('\t\t\t\t\t<tr>\n')

    for header in headers:
        f.write('\t\t\t\t\t\t<th>{}</th>\n'.format(header))

    f.write('\t\t\t\t\t</tr>\n')
    f.write('\t\t\t\t</thead>\n')
    f.write('\t\t\t\t<tbody>\n')

    for row in rows:
        f.write('\t\t\t\t\t<tr>\n')

        for index, header in enumerate(headers):
            f.write('\t\t\t\t\t\t<td>{}</td>'.format(row[index]))

        f.write('\t\t\t\t\t</tr>\n')

    f.write('\t\t\t\t</tbody>\n')
    f.write('\t\t\t</table>\n')


def html_output_battle(f: TextIO, key: str, battle_data: dict[tuple[str, str, str], Any], agility_battle_data: dict[tuple[str, str, str], Any]):
    first_data = list(battle_data.values())[0]

    if 'strat' in first_data and first_data['strat']:
        f.write('\t\t\t<h2>Battle Data for {} using &quot;{}&quot; Strat</h2>\n'.format(describe_formation(first_data['formation']), first_data['strat']))
    else:
        f.write('\t\t\t<h2>Battle Data for {}</h2>\n'.format(describe_formation(first_data['formation'])))

    f.write('\t\t\t<h3>Time Graph</h3>\n')
    f.write('\t\t\t<p><img src="img/{}.png"></p>'.format(key))

    #
    # Battle Type Statistics
    #

    f.write('\t\t\t<h3>Battle Type Statistics</h3>\n')
    battle_type_data: dict[str, dict[str, Any]] = {}

    for (battle_type, _, _), data in sorted(battle_data.items()):
        if battle_type not in battle_type_data:
            battle_type_data[battle_type] = data
        else:
            battle_type_data[battle_type]['count'] += data['count']
            battle_type_data[battle_type]['data'].extend(data['data'])

            if 'success' in data:
                if 'success' not in battle_type_data[battle_type]:
                    battle_type_data[battle_type]['success'] = 0
                battle_type_data[battle_type]['success'] += data['success']

    headers = ['Battle Type', 'Battles', 'Successes', 'Deaths', 'Best Time', 'Worst Time', 'Median Time']
    rows: list[list[Any]] = []

    for battle_type, data in battle_type_data.items():
        if len(data['data']) > 0:
            minimum = format_time(min(data['data']))
            maximum = format_time(max(data['data']))
            median = format_time(statistics.median(data['data']))
        else:
            minimum = 'N/A'
            maximum = 'N/A'
            median = 'N/A'

        rows.append([
            battle_type,
            data['count'],
            data['success'] if 'success' in data else 'N/A',
            data['count'] - len(data['data']),
            minimum,
            maximum,
            median,
        ])

    html_output_table(headers, rows)

    #
    # Relative Speed Statistics
    #

    f.write('\t\t\t<h3>Relative Speed Statistics</h3>\n')
    battle_type_data = {}

    for (battle_type, enemy_agility_raw, party_agility_raw), data in sorted(agility_battle_data.items()):
        enemy_agility = [int(x) for x in enemy_agility_raw.split()]
        party_names: list[str] = []
        party_agility: list[Optional[int]] = []
        anchor_agility = None

        for slot in party_agility_raw.split('/'):
            slot = slot.strip()

            if slot.endswith('empty'):
                party_names.append(slot)
                party_agility.append(None)
            else:
                tokens = slot.split(':')

                if tokens[0].endswith('Cecil'):
                    anchor_agility = int(tokens[1])

                party_names.append(tokens[0])
                party_agility.append(int(tokens[1]))

        if anchor_agility is None:
            for slot in [2, 0, 4, 1, 3]:
                if not party_names[slot].endswith('empty'):
                    anchor_agility = party_agility[slot]
                    break

        assert(anchor_agility is not None)

        for index in range(len(enemy_agility)):
            enemy_agility[index] = max(1, anchor_agility * 5 // enemy_agility[index])

        for index in range(len(party_agility)):
            agility = party_agility[index]

            if agility is not None:
                party_agility[index] = max(1, anchor_agility * 5 // agility)

        key = '{}-{}-{}'.format(battle_type, '-'.join([str(x) for x in enemy_agility]), '-'.join([str(x) for x in party_agility]))

        if key not in battle_type_data:
            battle_type_data[key] = data
            battle_type_data[key]['battle_type'] = battle_type
            battle_type_data[key]['enemy_rs'] = ' '.join([str(x) for x in enemy_agility])

            party_agility_tokens: list[str] = []

            for index, name in enumerate(party_names):
                if name.endswith('empty'):
                    party_agility_tokens.append(name)
                else:
                    party_agility_tokens.append(':'.join([name, str(party_agility[index])]))

            battle_type_data[key]['party_rs'] = ' / '.join(party_agility_tokens)
        else:
            battle_type_data[key]['count'] += data['count']
            battle_type_data[key]['data'].extend(data['data'])

            if 'success' in data:
                if 'success' not in battle_type_data[battle_type]:
                    battle_type_data[battle_type]['success'] = 0
                battle_type_data[battle_type]['success'] += data['success']

    headers = ['Battle Type', 'Enemy Speed', 'Party Speed', 'Battles', 'Successes', 'Deaths', 'Best Time', 'Worst Time', 'Median Time']
    rows = []

    for key, data in sorted(battle_type_data.items()):
        if len(data['data']) > 0:
            minimum = format_time(min(data['data']))
            maximum = format_time(max(data['data']))
            median = format_time(statistics.median(data['data']))
        else:
            minimum = 'N/A'
            maximum = 'N/A'
            median = 'N/A'

        rows.append([
            data['battle_type'],
            data['enemy_rs'],
            data['party_rs'],
            data['count'],
            data['success'] if 'success' in data else 'N/A',
            data['count'] - len(data['data']),
            minimum,
            maximum,
            median,
        ])

    html_output_table(headers, rows)

    #
    # Full Statistics (Agility)
    #

    f.write('\t\t\t<h3>Full Statistics (Agility)</h3>\n')
    headers = ['Battle Type', 'Enemy Agility', 'Party Agility', 'Battles', 'Successes', 'Deaths', 'Best Time', 'Worst Time', 'Median Time']
    rows = []

    for (battle_type, enemy_agility_str, party_agility_str), data in agility_battle_data.items():
        if len(data['data']) > 0:
            minimum = format_time(min(data['data']))
            maximum = format_time(max(data['data']))
            median = format_time(statistics.median(data['data']))
        else:
            minimum = 'N/A'
            maximum = 'N/A'
            median = 'N/A'

        rows.append([
            battle_type,
            enemy_agility_str,
            party_agility_str,
            data['count'],
            data['success'] if 'success' in data else 'N/A',
            data['count'] - len(data['data']),
            minimum,
            maximum,
            median,
        ])

    html_output_table(headers, rows)

    #
    # Full Statistics (Level)
    #

    f.write('\t\t\t<h3>Full Statistics (Level)</h3>\n')
    headers = ['Battle Type', 'Enemy Agility', 'Party Agility', 'Battles', 'Successes', 'Deaths', 'Best Time', 'Worst Time', 'Median Time']
    rows = []

    for (battle_type, enemy_agility_str, party_agility_str), data in battle_data.items():
        if len(data['data']) > 0:
            minimum = format_time(min(data['data']))
            maximum = format_time(max(data['data']))
            median = format_time(statistics.median(data['data']))
        else:
            minimum = 'N/A'
            maximum = 'N/A'
            median = 'N/A'

        rows.append([
            battle_type,
            enemy_agility_str,
            party_agility_str,
            data['count'],
            data['success'] if 'success' in data else 'N/A',
            data['count'] - len(data['data']),
            minimum,
            maximum,
            median,
        ])

    html_output_table(headers, rows)


def html_output_seeds(f: TextIO, logs: list[Log]):
    f.write('\t\t\t<h2>Step Seeds</h2>\n')
    f.write('\t\t\t<table class="tablesorter-bootstrap" id="seeds">\n')
    f.write('\t\t\t\t<thead>\n')
    f.write('\t\t\t\t\t<tr>\n')
    f.write('\t\t\t\t\t\t<th>Route</th>\n')
    f.write('\t\t\t\t\t\t<th>Seed</th>\n')
    f.write('\t\t\t\t\t\t<th>Count</th>\n')
    f.write('\t\t\t\t\t\t<th>Back Attacks</th>\n')
    f.write('\t\t\t\t\t\t<th>Sum of Best</th>\n')
    f.write('\t\t\t\t\t\t<th>Minimum</th>\n')
    f.write('\t\t\t\t\t\t<th>Maximum</th>\n')
    f.write('\t\t\t\t\t\t<th>Median</th>\n')
    f.write('\t\t\t\t\t</tr>\n')
    f.write('\t\t\t\t</thead>\n')
    f.write('\t\t\t\t<tbody>\n')

    seeds = get_seed_data(logs)

    for route in seeds:
        for seed, data in sorted(seeds[route].items(), key=lambda x: statistics.median(x[1]['data']) if len(x[1]['data']) > 0 else 0):
            if len(data['data']) > 0:
                f.write('\t\t\t\t\t<tr>\n')
                f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(route))
                f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(seed))
                f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(len(data['data'])))
                f.write('\t\t\t\t\t\t<td>{} / {} ({:.3f}%)</td>\n'.format(data['back_attack_count'], data['battles'], data['back_attack_count'] * 100 / data['battles'] if data['battles'] > 0 else 100))
                f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(sum(data['best_splits'].values()))))
                f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(min(data['data']))))
                f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(max(data['data']))))
                f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(statistics.median(data['data']))))
                f.write('\t\t\t\t\t</tr>\n')

    f.write('\t\t\t\t</tbody>\n')
    f.write('\t\t\t</table>\n')


def html_output_run(f: TextIO, splits: dict[str, Any], battles: dict[str, Any], log: Log):
    f.write('\t\t\t<h2>Summary</h2>\n')
    f.write('\t\t\t\t<dl class="dl-horizontal">\n')
    f.write('\t\t\t\t\t<dt>Route</dt><dd>{}</dd>\n'.format(log.route))
    f.write('\t\t\t\t</dl>\n')

    f.write('\t\t\t<h2>Splits</h2>\n')
    f.write('\t\t\t<table class="table table-striped">\n')
    f.write('\t\t\t\t<thead>\n')
    f.write('\t\t\t\t\t<tr>\n')
    f.write('\t\t\t\t\t\t<th>Split</th>\n')
    f.write('\t\t\t\t\t\t<th>Cumulative Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Segment Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Best Segment Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Worst Segment Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Median Segment Time</th>\n')
    f.write('\t\t\t\t\t</tr>\n')
    f.write('\t\t\t\t</thead>\n')
    f.write('\t\t\t\t<tbody>\n')

    for split, data in sorted(log.splits.items(), key=lambda x: x[1]['total']):
        if data['current'] < sorted(splits[split])[int(len(splits[split]) * 0.3333)]:
            result_class = 'text-success'
        elif data['current'] < sorted(splits[split])[int(len(splits[split]) * 0.6667)]:
            result_class = 'text-warning'
        else:
            result_class = 'text-danger'

        f.write('\t\t\t\t\t<tr>\n')
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(split))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(data['total'])))
        f.write('\t\t\t\t\t\t<td class="{}">{}</td>\n'.format(result_class, format_time(data['current'])))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(min(splits[split]))))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(max(splits[split]))))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(statistics.median(splits[split]))))
        f.write('\t\t\t\t\t</tr>\n')

    f.write('\t\t\t\t</tbody>\n')
    f.write('\t\t\t</table>\n')

    f.write('\t\t\t<h2>Battles</h2>\n')
    f.write('\t\t\t<table class="table table-striped">\n')
    f.write('\t\t\t\t<thead>\n')
    f.write('\t\t\t\t\t<tr>\n')
    f.write('\t\t\t\t\t\t<th>Formation</th>\n')
    f.write('\t\t\t\t\t\t<th>Strat</th>\n')
    f.write('\t\t\t\t\t\t<th>Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Best Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Worst Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Median Time</th>\n')
    f.write('\t\t\t\t\t</tr>\n')
    f.write('\t\t\t\t</thead>\n')
    f.write('\t\t\t\t<tbody>\n')

    for data in log.battles:
        key = '{:03}'.format(data['formation'])

        if data['strat']:
            key = '{}-{}'.format(key, data['strat'])

        if key in battles and len(battles[key]['data']) > 0:
            if data['frames'] < sorted(battles[key]['data'])[int(len(battles[key]['data']) * 0.3333)]:
                result_class = 'text-success'
            elif data['frames'] < sorted(battles[key]['data'])[int(len(battles[key]['data']) * 0.6667)]:
                result_class = 'text-warning'
            else:
                result_class = 'text-danger'

            f.write('\t\t\t\t\t<tr>\n')
            f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(describe_formation(data['formation'])))
            f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(data['strat'] if data['strat'] else '-'))
            f.write('\t\t\t\t\t\t<td class="{}">{}</td>\n'.format(result_class, format_time(data['frames'])))
            f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(min(battles[key]['data']))))
            f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(max(battles[key]['data']))))
            f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(statistics.median(battles[key]['data']))))
            f.write('\t\t\t\t\t</tr>\n')

    f.write('\t\t\t\t</tbody>\n')
    f.write('\t\t\t</table>\n')


def html_output_runs(f: TextIO, logs: list[Log]):
    f.write('\t\t\t<h2>Runs</h2>\n')
    f.write('\t\t\t<table class="tablesorter-bootstrap" id="runs">\n')
    f.write('\t\t\t\t<thead>\n')
    f.write('\t\t\t\t\t<tr>\n')
    f.write('\t\t\t\t\t\t<th>Edge Version</th>\n')
    f.write('\t\t\t\t\t\t<th>Route</th>\n')
    f.write('\t\t\t\t\t\t<th>Step Seed</th>\n')
    f.write('\t\t\t\t\t\t<th>RNG Seed</th>\n')
    f.write('\t\t\t\t\t\t<th>Surprised/Back Attacks</th>\n')
    f.write('\t\t\t\t\t\t<th>Non-Battle Time</th>\n')
    f.write('\t\t\t\t\t\t<th>Result</th>\n')
    f.write('\t\t\t\t\t</tr>\n')
    f.write('\t\t\t\t</thead>\n')
    f.write('\t\t\t\t<tbody>\n')

    frames = [log.frames for log in logs if log.success]

    for log in sorted(logs, key=lambda x: x.frames if x.frames else (10 ** 8) - x.last_frame):
        if log.success:
            if log.frames < sorted(frames)[int(len(frames) * 0.3333)]:
                result_class = 'text-success'
            elif log.frames < sorted(frames)[int(len(frames) * 0.6667)]:
                result_class = 'text-warning'
            else:
                result_class = 'text-danger'
        else:
            result_class = 'text-danger bold'

        f.write('\t\t\t\t\t<tr>\n')
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(log.version))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(log.route))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(log.step_seed))
        f.write('\t\t\t\t\t\t<td><a href="runs/{}-{:03}-{:010}.html">{}</a></td>\n'.format(log.route, log.step_seed, log.rng_seed, log.rng_seed))
        f.write('\t\t\t\t\t\t<td data-text="{}">{} / {} ({:.3f}%)</td>\n'.format(log.back_attack_count / log.random_battle_count if log.random_battle_count > 0 else 100, log.back_attack_count, log.random_battle_count, log.back_attack_count * 100 / log.random_battle_count if log.random_battle_count > 0 else 100))
        f.write('\t\t\t\t\t\t<td>{}</td>\n'.format(format_time(log.non_battle_frames) if log.non_battle_frames else 'N/A'))
        f.write('\t\t\t\t\t\t<td data-text="{}" class="{}">{}</td>\n'.format(log.frames if log.frames else (10 ** 8) - log.last_frame, result_class, log.result))
        f.write('\t\t\t\t\t</tr>\n')

    f.write('\t\t\t\t</tbody>\n')
    f.write('\t\t\t</table>\n')

    f.write('\t\t\t<h2>Finished Runs Plot</h2>\n')
    f.write('\t\t\t<img src="img/runs.png">')

    f.write('\t\t\t<h2>Finished Seeds Plot</h2>\n')
    f.write('\t\t\t<img src="img/seeds.png">')


#
# Main Execution
#

logs: list[Log] = []

if not os.path.exists(sys.argv[1]):
    print('Output directory must exist.')
    sys.exit(1)

for filename in sys.argv[2:]:
    log = Log(filename)

    if log.valid:
        logs.append(log)
    else:
        print('WARNING: {} is not a valid log.'.format(filename))

with open(os.path.join(sys.argv[1], 'index.html'), 'w') as f:
    html_output_header(f)
    html_output_basic_statistics(f, logs)
    html_output_splits(f, logs)
    html_output_battles(f, logs)
    html_output_seeds(f, logs)
    html_output_runs(f, logs)
    html_output_footer(f)

splits = get_split_data(logs, False)
battles = get_battle_data(logs, False)

os.mkdir(os.path.join(sys.argv[1], 'img'))
os.mkdir(os.path.join(sys.argv[1], 'runs'))

img_output_runs(os.path.join(sys.argv[1], 'img', 'runs.png'), logs)
img_output_runs(os.path.join(sys.argv[1], 'img', 'seeds.png'), logs, True)

for log in logs:
    with open(os.path.join(sys.argv[1], 'runs', '{}-{:03}-{:010}.html'.format(log.route, log.step_seed, log.rng_seed)), 'w') as f:
        html_output_header(f)
        html_output_run(f, splits, battles, log)
        html_output_footer(f)

battles = get_battle_data(logs, True)

os.mkdir(os.path.join(sys.argv[1], 'battles'))

agility_data = get_battle_data(logs, True, agility=True)

for key, data in battles.items():
    with open(os.path.join(sys.argv[1], 'battles', '{}.html'.format(key)), 'w') as f:
        html_output_header(f)
        html_output_battle(f, key, data, agility_data[key])
        html_output_footer(f)

battles = get_battle_data(logs, False, False)

os.mkdir(os.path.join(sys.argv[1], 'battles', 'img'))

for key, data in battles.items():
    if len(data['strat']) > 0:
        for strat in data['strat']:
            img_output_battle(os.path.join(sys.argv[1], 'battles', 'img', '{}-{}.png'.format(key, strat)), key, data)
    else:
        img_output_battle(os.path.join(sys.argv[1], 'battles', 'img', '{}.png'.format(key)), key, data)
