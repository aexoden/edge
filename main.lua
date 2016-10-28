--------------------------------------------------------------------------------
-- Copyright (c) 2015 Jason Lynch <jason@calindora.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

CONFIG = {}

-- Specify a specific route to run. Set this to nil to choose a random route.
CONFIG.ROUTE = nil

-- Specify the encounter seed to run against. Set to nil to choose a random seed.
CONFIG.ENCOUNTER_SEED = nil

-- Specify a number to do a specific run. Set this value to nil to do random runs.
CONFIG.SEED = nil

-- Automatically do continuous runs by restarting after completion.
CONFIG.AUTOMATIC = false

-- Enable/Disable LiveSplit integration (requires luasocket and LiveSplit)
CONFIG.LIVESPLIT = false

-- Automatically create save states at the beginning of each battle.
CONFIG.SAVESTATE = false

-- Do an extended ending at the end of the run (for streaming purposes)
CONFIG.EXTENDED_ENDING = false

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

local battle = require "ai.battle"
local bridge = require "util.bridge"
local dialog = require "util.dialog"
local input = require "util.input"
local log = require "util.log"
local menu = require "action.menu"
local sequence = require "ai.sequence"
local walk = require "action.walk"

FULL_RUN = emu.framecount() == 1
INITIALIZED = false

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function _get_version()
	local file = io.popen("git describe --tags --dirty", "r")
	local version = string.match(string.match(file:read('*all'), "%S.*"), ".*%S")

	if version == "" then
		return "v0.0.6"
	else
		return version
	end
end

local function _set_route()
	ROUTES = {"no64-excalbur"}

	if CONFIG.ROUTE then
		return CONFIG.ROUTE
	else
		return ROUTES[math.random(#ROUTES)]
	end
end

local function _set_encounter_seed()
	if CONFIG.ENCOUNTER_SEED then
		return CONFIG.ENCOUNTER_SEED
	else
		return math.random(0, 255)
	end
end

local function _set_seed()
	local seed = CONFIG.SEED

	if not seed then
		math.randomseed(os.time())
		math.random()
		math.random()
		math.random()
		seed = math.random(0, 2147483646)
	end

	if SEED and CONFIG.AUTOMATIC and CONFIG.SEED ~= nil then
		seed = SEED + 1
	end

	math.randomseed(seed)
	math.random()
	math.random()
	math.random()

	return seed
end

local function _reset()
	ROUTE = _set_route()
	ENCOUNTER_SEED = _set_encounter_seed()
	SEED = _set_seed()

	log.reset()

	log.log("Edge Final Fantasy IV Speed Run Bot")
	log.log("-----------------------------------")
	log.log(string.format("Version: %s", _get_version()))

	if FULL_RUN then
		log.log("Beginning Full Run")
		log.log(string.format("Route: %s", ROUTE))
		log.log(string.format("Encounter Seed: %d", ENCOUNTER_SEED))
		log.log(string.format("RNG Seed: %d", SEED))
	else
		log.log("Beginning Test Mode")
	end

	bridge.reset()
	menu.reset()
	walk.reset()

	dialog.reset()
	battle.reset()

	sequence.reset()

	INITIALIZED = true
end

--------------------------------------------------------------------------------
-- Main Loop
--------------------------------------------------------------------------------

while true do
	if emu.framecount() == 1 or not INITIALIZED then
		FULL_RUN = emu.framecount() == 1
		_reset()
	end

	dialog.cycle()

	if not battle.cycle() and sequence.is_active() then
		sequence.cycle()
	end

	if sequence.is_end() then
		log.log("Rebooting...")
		client.reboot_core()
	end

	bridge.cycle()
	input.cycle()
	emu.frameadvance()
end
