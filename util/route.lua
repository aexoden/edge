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

local _M = {}

local game = require "util.game"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _enabled = false

--------------------------------------------------------------------------------
-- Routes
--------------------------------------------------------------------------------

_M.routes = {}

--------------------------------------------------------------------------------
-- Split Data
--------------------------------------------------------------------------------

_M.splits = {
	["no64-excalbur"] = {
		["Start"]                  = 159,
		["Prologue"]               = 22120,
		["D.Mist"]                 = 36320,
		["Girl"]                   = 46357,
		["Officer/Soldiers"]       = 53877,
		["Tellah"]                 = 60796,
		["Octomamm"]               = 82360,
		["Edward"]                 = 93141,
		["Antlion"]                = 102295,
		["WaterHag"]               = 115416,
		["MomBomb"]                = 132313,
		["Dragoon"]                = 154281,
		["Twins"]                  = 177221,
		["Milon"]                  = 200729,
		["Milon Z."]               = 206368,
		["Paladin"]                = 212617,
		["Karate"]                 = 233920,
		["Baigan"]                 = 251526,
		["Kainazzo"]               = 256254,
		["Dark Elf"]               = 294430,
		["FlameDog"]               = 307010,
		["Magus Sisters"]          = 318090,
		["Valvalis"]               = 341426,
		["Calbrena"]               = 365986,
		["Golbez"]                 = 371923,
		["Dr.Lugae/Balnab"]        = 403690,
		["Dr.Lugae"]               = 409391,
		["Dark Imps"]              = 416112,
		["Edge"]                   = 448777,
		["K.Eblan/Q.Eblan"]        = 468418,
		["Rubicant"]               = 475645,
		["Lost the Dark Crystal!"] = 501735,
		["Big Whale"]              = 521259,
		["FuSoYa"]                 = 534318,
		["Grind Fight (start)"]    = 563645,
		["Grind Fight"]            = 578360,
		["Elements"]               = 587721,
		["CPU"]                    = 592244,
		["Lunar Subterrane"]       = 612173,
		["Lunar Core"]             = 627311,
		["Zemus"]                  = 639605,
		["Zeromus Death"]          = 665873,
	},
	["no64-rosa"] = {
		["Start"]                  = 185,
		["Prologue"]               = 22234,
		["D.Mist"]                 = 36865,
		["Girl"]                   = 46861,
		["Officer/Soldiers"]       = 54449,
		["Tellah"]                 = 61367,
		["Octomamm"]               = 83485,
		["Edward"]                 = 94285,
		["Antlion"]                = 103476,
		["WaterHag"]               = 116644,
		["MomBomb"]                = 133040,
		["Dragoon"]                = 155605,
		["Twins"]                  = 178507,
		["Milon"]                  = 201910,
		["Milon Z."]               = 207178,
		["Paladin"]                = 213118,
		["Karate"]                 = 234227,
		["Baigan"]                 = 252457,
		["Kainazzo"]               = 257209,
		["Dark Elf"]               = 296558,
		["FlameDog"]               = 310649,
		["Magus Sisters"]          = 321215,
		["Valvalis"]               = 345192,
		["Calbrena"]               = 369717,
		["Golbez"]                 = 375787,
		["Dr.Lugae/Balnab"]        = 406932,
		["Dr.Lugae"]               = 411412,
		["Dark Imps"]              = 418256,
		["Edge"]                   = 451898,
		["K.Eblan/Q.Eblan"]        = 472483,
		["Rubicant"]               = 480105,
		["Lost the Dark Crystal!"] = 498609,
		["Big Whale"]              = 515476,
		["FuSoYa"]                 = 524974,
		["Grind Fight (start)"]    = 551970,
		["Grind Fight"]            = 568403,
		["Elements"]               = 578576,
		["CPU"]                    = 586043,
		["Lunar Subterrane"]       = 607353,
		["Lunar Core"]             = 620726,
		["Zemus"]                  = 634921,
		["Zeromus Death"]          = 661931,
	},
	["nocw"] = {
		["Start"]                  = 185,
		["Prologue"]               = 22238,
		["D.Mist"]                 = 37061,
		["Girl"]                   = 47029,
		["Officer/Soldiers"]       = 54579,
		["Tellah"]                 = 61502,
		["Octomamm"]               = 84869,
		["Edward"]                 = 95677,
		["Antlion"]                = 104786,
		["WaterHag"]               = 117948,
		["MomBomb"]                = 134993,
		["Dragoon"]                = 158371,
		["Twins"]                  = 181553,
		["Milon"]                  = 205018,
		["Milon Z."]               = 211110,
		["Paladin"]                = 217061,
		["Karate"]                 = 238037,
		["Baigan"]                 = 258211,
		["Kainazzo"]               = 263265,
		["Dark Elf"]               = 301773,
		["FlameDog"]               = 315593,
		["Magus Sisters"]          = 326958,
		["Valvalis"]               = 350786,
		["Calbrena"]               = 383998,
		["Golbez"]                 = 389782,
		["Lost the Dark Crystal!"] = 395901,
		["FuSoYa"]                 = 399540,
		["Zemus"]                  = 413099,
		["Zeromus Death"]          = 427989,
	},
	["paladin"] = {
		["Start"]                  = 159,
		["Prologue"]               = 22124,
		["D.Mist"]                 = 36044,
		["Girl"]                   = 45241,
		["Officer/Soldiers"]       = 52537,
		["Tellah"]                 = 58790,
		["Octomamm"]               = 81981,
		["Edward"]                 = 92340,
		["Antlion"]                = 100727,
		["WaterHag"]               = 114720,
		["MomBomb"]                = 129671,
		["Dragoon"]                = 152137,
		["Twins"]                  = 174121,
		["Milon"]                  = 197797,
		["Milon Z."]               = 202950,
		["Paladin"]                = 209193,
	}
}

--------------------------------------------------------------------------------
-- Inventory Management
--------------------------------------------------------------------------------

_M.inventory = {
	["no64-excalbur"] = {},
	["no64-rosa"] = {},
	["nocw"] = {},
	["paladin"] = {},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.GIRL] = {
	{game.ITEM.HELM.TIARA,      nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CARROT,     nil, {4}, {}},
	{game.ITEM.ARMS.IRON,       nil, {8}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.OCTOMAMM] = {
	{game.ITEM.HELM.CAP,        nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CARROT,     nil, {4}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {6}, {}},
	{game.ITEM.ARMS.IRON,       nil, {8}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
	{game.ITEM.WEAPON.STAFF,    nil, {11}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.ANTLION] = {
	{game.ITEM.HELM.CAP,        nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CARROT,     nil, {4}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {6}, {}},
	{game.ITEM.ARMS.IRON,       nil, {8}, {}},
	{game.ITEM.ITEM.LIFE,         1, {9}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.MOMBOMB] = {
	{game.ITEM.HELM.CAP,        nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CARROT,     nil, {4}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {6}, {}},
	{game.ITEM.ARMS.IRON,       nil, {8}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
	{game.ITEM.ITEM.LIFE,         1, {43}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.GENERAL] = {
	{game.ITEM.HELM.CAP,        nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CARROT,     nil, {4}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {6}, {}},
	{game.ITEM.ARMS.IRON,       nil, {8}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
	{game.ITEM.ITEM.LIFE,         1, {43}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.WEEPER] = _M.inventory["no64-excalbur"][game.battle.FORMATION.GENERAL]
_M.inventory["no64-excalbur"][game.battle.FORMATION.GARGOYLE] = _M.inventory["no64-excalbur"][game.battle.FORMATION.GENERAL]
_M.inventory["no64-excalbur"][game.battle.FORMATION.DRAGOON] = _M.inventory["no64-excalbur"][game.battle.FORMATION.GENERAL]

_M.inventory["no64-excalbur"][game.battle.FORMATION.MILON] = {
	{game.ITEM.ITEM.CURE2,      nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.SHIELD.PALADIN,  nil, {2}, {}},
	{game.ITEM.ITEM.CARROT,     nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {6}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {9}, {}},
	{game.ITEM.RING.SILVER,     nil, {10}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
	{game.ITEM.ARMS.IRON,       nil, {14}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {15}, {}},
	{game.ITEM.HELM.TIARA,      nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {43}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.MILON] = {
	{game.ITEM.ITEM.CURE2,      nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CARROT,     nil, {2}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {4}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {5}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {6}, {}},
	{game.ITEM.HELM.GAEA,       nil, {7}, {}},
	{game.ITEM.ARMS.IRON,       nil, {8}, {}},
	{game.ITEM.RING.SILVER,     nil, {9}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.SHIELD.PALADIN,  nil, {12}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {14}, {}},
	{game.ITEM.ITEM.LIFE,         1, {15}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.MILON_Z] = {
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.SHIELD.PALADIN,  nil, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {6}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {9}, {}},
	{game.ITEM.RING.SILVER,     nil, {10}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
	{game.ITEM.ARMS.IRON,       nil, {14}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {15}, {}},
	{game.ITEM.HELM.TIARA,      nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {43}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.MILON_Z] = {
	{game.ITEM.WEAPON.DANCING,  nil, {0}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {1}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.ITEM.TRASHCAN,   nil, {4}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.SHIELD.PALADIN,  nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {9}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {14}, {}},
	{game.ITEM.ARMS.IRON,       nil, {16}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {17}, {}},
	{game.ITEM.ITEM.LIFE,         1, {19}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.D_KNIGHT] = {
	{game.ITEM.WEAPON.LEGEND,   nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.SHIELD.PALADIN,  nil, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {9}, {}},
	{game.ITEM.RING.SILVER,     nil, {10}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
	{game.ITEM.ARMS.IRON,       nil, {14}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {15}, {}},
	{game.ITEM.HELM.TIARA,      nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {43}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.D_KNIGHT] = {
	{game.ITEM.WEAPON.DANCING,  nil, {0}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {1}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.SHIELD.PALADIN,  nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {9}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {14}, {}},
	{game.ITEM.ARMS.IRON,       nil, {16}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {17}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.GUARDS] = {
	{game.ITEM.WEAPON.LEGEND,   nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {9}, {}},
	{game.ITEM.RING.SILVER,     nil, {10}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {11}, {}},
	{game.ITEM.ARMS.IRON,       nil, {14}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {15}, {}},
	{game.ITEM.HELM.TIARA,      nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {43}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.GUARDS] = {
	{game.ITEM.ITEM.CURE2,      nil, {1}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.SHIELD.PALADIN,  nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.ARMS.PALADIN,    nil, {9}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {10}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {14}, {}},
	{game.ITEM.ARMS.IRON,       nil, {16}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {17}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.KARATE] = _M.inventory["no64-excalbur"][game.battle.FORMATION.GUARDS]
_M.inventory["nocw"][game.battle.FORMATION.KARATE] = _M.inventory["nocw"][game.battle.FORMATION.GUARDS]

_M.inventory["no64-excalbur"][game.battle.FORMATION.BAIGAN] = {
	{game.ITEM.WEAPON.LEGEND,   nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ARMS.IRON,       nil, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {6}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.GAEA,       nil, {8}, {}},
	{game.ITEM.WEAPON.DANCING,    1, {9}, {}},
	{game.ITEM.RING.SILVER,     nil, {10}, {}},
	{game.ITEM.WEAPON.THUNDER,  nil, {11}, {}},
	{game.ITEM.ITEM.BARON,      nil, {14}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {15}, {}},
	{game.ITEM.HELM.TIARA,      nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {43}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.BAIGAN] = {
	{game.ITEM.ITEM.ETHER1,     nil, {0}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {1}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {2}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {4}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {7}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.HELM.TIARA,      nil, {13}, {}},
	{game.ITEM.ARMS.IRON,       nil, {14}, {}},
	{game.ITEM.WEAPON.CURE,      13, {10, 12, 15, 18}, {}},
	{game.ITEM.CLAW.ICECLAW,     57, {16}, {}},
	{game.ITEM.WEAPON.STAFF,      1, {17}, {}},
	{game.ITEM.CLAW.ICECLAW,     96, {19}, {}},
	{game.ITEM.WEAPON.CURE,      20, {20}, {}},
	{game.ITEM.CLAW.FIRECLAW,    68, {21}, {}},
	{game.ITEM.CLAW.THUNDER,      8, {22}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.KAINAZZO] = _M.inventory["no64-excalbur"][game.battle.FORMATION.BAIGAN]
_M.inventory["nocw"][game.battle.FORMATION.KAINAZZO] = _M.inventory["nocw"][game.battle.FORMATION.BAIGAN]

_M.inventory["no64-excalbur"][game.battle.FORMATION.DARK_ELF] = {
	{game.ITEM.WEAPON.THUNDER,  nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.HELM.GAEA,       nil, {11}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {12}, {}},
	{game.ITEM.ARMOR.PRISONER,  nil, {13}, {}},
	{game.ITEM.HELM.TIARA,      nil, {14}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {15}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.DARK_ELF] = {
	{game.ITEM.ITEM.ETHER1,     nil, {0}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {1}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {2}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {4}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {7}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.HELM.TIARA,      nil, {13}, {}},
	{game.ITEM.WEAPON.CURE,      13, {10, 12, 15, 18}, {}},
	{game.ITEM.CLAW.ICECLAW,     57, {16}, {}},
	{game.ITEM.WEAPON.STAFF,      1, {17}, {}},
	{game.ITEM.CLAW.ICECLAW,     96, {19}, {}},
	{game.ITEM.WEAPON.CURE,      20, {20}, {}},
	{game.ITEM.CLAW.FIRECLAW,    68, {21}, {}},
	{game.ITEM.CLAW.THUNDER,      8, {22}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.FLAMEDOG] = {
	{game.ITEM.ITEM.EARTH,      nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.HELM.GAEA,       nil, {11}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {12}, {}},
	{game.ITEM.ARMOR.PRISONER,  nil, {13}, {}},
	{game.ITEM.HELM.TIARA,      nil, {14}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {15}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.FLAMEDOG] = {
	{game.ITEM.ITEM.CURE2,      nil, {1}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {2}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {4}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {7}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {8}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.HELM.TIARA,      nil, {13}, {}},
	{game.ITEM.WEAPON.CURE,      13, {10, 12, 15, 18}, {}},
	{game.ITEM.CLAW.ICECLAW,     57, {16}, {}},
	{game.ITEM.WEAPON.STAFF,      1, {17}, {}},
	{game.ITEM.CLAW.ICECLAW,     96, {19}, {}},
	{game.ITEM.WEAPON.CURE,      20, {20}, {}},
	{game.ITEM.CLAW.FIRECLAW,    68, {21}, {}},
	{game.ITEM.CLAW.THUNDER,      8, {22}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.SISTERS] = {
	{game.ITEM.ITEM.EARTH,      nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.HELM.GAEA,       nil, {11}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {12}, {}},
	{game.ITEM.ARMOR.PRISONER,  nil, {13}, {}},
	{game.ITEM.HELM.TIARA,      nil, {14}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {15}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {16}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.SISTERS] = {
	{game.ITEM.ITEM.CURE2,      nil, {1}, {}},
	{game.ITEM.HELM.HEADBAND,   nil, {2}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.ARMOR.KARATE,    nil, {4}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {5}, {}},
	{game.ITEM.RING.SILVER,     nil, {6}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {7}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {8}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.HELM.TIARA,      nil, {13}, {}},
	{game.ITEM.WEAPON.CURE,      13, {10, 12, 15, 18}, {}},
	{game.ITEM.CLAW.ICECLAW,     57, {16}, {}},
	{game.ITEM.WEAPON.STAFF,      1, {17}, {}},
	{game.ITEM.CLAW.ICECLAW,     96, {19}, {}},
	{game.ITEM.WEAPON.CURE,      20, {20}, {}},
	{game.ITEM.CLAW.FIRECLAW,    68, {21}, {}},
	{game.ITEM.CLAW.THUNDER,      8, {22}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.VALVALIS] = {
	{game.ITEM.WEAPON.FIRE,     nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.HELM.GAEA,       nil, {6}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.TIARA,      nil, {8}, {}},
	{game.ITEM.ARMOR.PRISONER,  nil, {9}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {10}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {11}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {12}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.VALVALIS] = {
	{game.ITEM.WEAPON.FIRE,     nil, {0}, {}},
	{game.ITEM.CLAW.FIRECLAW,    68, {1}, {}},
	{game.ITEM.CLAW.THUNDER,      8, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {4}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {5}, {}},
	{game.ITEM.CLAW.ICECLAW,     96, {6}, {}},
	{game.ITEM.WEAPON.CURE,      20, {7}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.WEAPON.CURE,      13, {10, 12, 15, 18}, {}},
	{game.ITEM.CLAW.ICECLAW,     57, {16}, {}},
	{game.ITEM.WEAPON.STAFF,      1, {17}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.CALBRENA] = {
	{game.ITEM.WEAPON.FIRE,     nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.HELM.GAEA,       nil, {6}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.TIARA,      nil, {8}, {}},
	{game.ITEM.ARMOR.PRISONER,  nil, {9}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {10}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {11}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {12}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.GOLBEZ] = _M.inventory["no64-excalbur"][game.battle.FORMATION.CALBRENA]

_M.inventory["nocw"][game.battle.FORMATION.CALBRENA] = {
	{game.ITEM.WEAPON.FIRE,     nil, {0}, {}},
	{game.ITEM.CLAW.FIRECLAW,    68, {1}, {}},
	{game.ITEM.CLAW.THUNDER,      8, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {4}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {5}, {}},
	{game.ITEM.CLAW.ICECLAW,     96, {6}, {}},
	{game.ITEM.WEAPON.CURE,      20, {7}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.WEAPON.CURE,      13, {10, 12, 15, 18}, {}},
	{game.ITEM.CLAW.ICECLAW,     57, {16}, {}},
	{game.ITEM.WEAPON.STAFF,      1, {17}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["nocw"][game.battle.FORMATION.GOLBEZ] = {
	{game.ITEM.CLAW.FIRECLAW,    68, {1}, {}},
	{game.ITEM.CLAW.THUNDER,      8, {2}, {}},
	{game.ITEM.CLAW.ICECLAW,     96, {6}, {}},
	{game.ITEM.WEAPON.CURE,      20, {7}, {}},
	{game.ITEM.CLAW.FIRECLAW,   114, {11}, {}},
	{game.ITEM.WEAPON.CURE,      13, {0, 10, 12, 15}, {}},
	{game.ITEM.CLAW.ICECLAW,     57, {16}, {}},
	{game.ITEM.WEAPON.STAFF,      1, {17}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.LUGAE1] = {
	{game.ITEM.ITEM.DARKNESS,   nil, {0}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {1}, {}},
	{game.ITEM.CLAW.CATCLAW,    nil, {2}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {3}, {}},
	{game.ITEM.ARMOR.WIZARD,    nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {5}, {}},
	{game.ITEM.HELM.GAEA,       nil, {6}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {7}, {}},
	{game.ITEM.HELM.TIARA,      nil, {8}, {}},
	{game.ITEM.RING.RUNE,       nil, {9}, {}},
	{game.ITEM.WEAPON.CHANGE,   nil, {10}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {11}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {12}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.LUGAE2] = _M.inventory["no64-excalbur"][game.battle.FORMATION.LUGAE1]
_M.inventory["no64-excalbur"][game.battle.FORMATION.DARK_IMP] = _M.inventory["no64-excalbur"][game.battle.FORMATION.LUGAE1]

_M.inventory["no64-excalbur"][game.battle.FORMATION.EBLAN] = {
	{game.ITEM.ITEM.DARKNESS,   nil, {0}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {1}, {}},
	{game.ITEM.SHIELD.ICE,      nil, {2}, {}},
	{game.ITEM.WEAPON.BLIZZARD, nil, {3}, {}},
	{game.ITEM.WEAPON.ICEBRAND, nil, {4}, {}},
	{game.ITEM.ARMOR.WIZARD,    nil, {5}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {6}, {}},
	{game.ITEM.HELM.GAEA,       nil, {7}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {8}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {9}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {10}, {}},
	{game.ITEM.RING.RUNE,       nil, {11}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {13}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-rosa"][game.battle.FORMATION.EBLAN] = {
	{game.ITEM.ITEM.DARKNESS,   nil, {0}, {}},
	{game.ITEM.ITEM.ELIXIR,     nil, {1}, {}},
	{game.ITEM.SHIELD.ICE,      nil, {2}, {}},
	{game.ITEM.WEAPON.BLIZZARD, nil, {3}, {}},
	{game.ITEM.WEAPON.ICEBRAND, nil, {4}, {}},
	{game.ITEM.ARMOR.WIZARD,    nil, {5}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {6}, {}},
	{game.ITEM.HELM.GAEA,       nil, {7}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {8}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {9}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {10}, {}},
	{game.ITEM.RING.RUNE,       nil, {11}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {13}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.RUBICANT] = {
	{game.ITEM.ITEM.DARKNESS,   nil, {0}, {}},
	{game.ITEM.WEAPON.LEGEND,   nil, {1}, {}},
	{game.ITEM.ARMOR.WIZARD,    nil, {4}, {}},
	{game.ITEM.HELM.GAEA,       nil, {5}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {6}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {7}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {8}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {9}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {10}, {}},
	{game.ITEM.RING.RUNE,       nil, {11}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-rosa"][game.battle.FORMATION.RUBICANT] = {
	{game.ITEM.ITEM.DARKNESS,   nil, {0}, {}},
	{game.ITEM.ITEM.ELIXIR,     nil, {1}, {}},
	{game.ITEM.WEAPON.ICEBRAND, nil, {3}, {}},
	{game.ITEM.ARMOR.WIZARD,    nil, {4}, {}},
	{game.ITEM.HELM.GAEA,       nil, {5}, {}},
	{game.ITEM.ITEM.CURE2,      nil, {6}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {7}, {}},
	{game.ITEM.WEAPON.DANCING,  nil, {8}, {}},
	{game.ITEM.ITEM.ETHER1,     nil, {9}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {10}, {}},
	{game.ITEM.RING.RUNE,       nil, {11}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.ELEMENTS] = {
	{game.ITEM.WEAPON.EXCALBUR, nil, {0}, {}},
	{game.ITEM.ITEM.ELIXIR,     nil, {1}, {}},
	{game.ITEM.RING.STRENGTH,   nil, {2}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {3}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-rosa"][game.battle.FORMATION.ELEMENTS] = {
	{game.ITEM.ITEM.ELIXIR,     nil, {0}, {}},
	{game.ITEM.RING.STRENGTH,   nil, {1}, {}},
	{game.ITEM.ITEM.LIFE,       nil, {2}, {}},
	{game.ITEM.ITEM.HEAL,       nil, {3}, {}},
	{game.ITEM.WEAPON.ICEBRAND, nil, {4}, {}},
	{game.ITEM.ITEM.LIFE,         1, {25}, {}},
}

_M.inventory["no64-excalbur"][game.battle.FORMATION.CPU] = _M.inventory["no64-excalbur"][game.battle.FORMATION.ELEMENTS]
_M.inventory["no64-rosa"][game.battle.FORMATION.CPU] = _M.inventory["no64-rosa"][game.battle.FORMATION.ELEMENTS]

--------------------------------------------------------------------------------
-- Step Route Data
--------------------------------------------------------------------------------

_M.routes["no64-excalbur"] = {
	[0] = {
		["E30A000"] = 32, ["C200000"] = 1, ["C305500"] = 1, ["E309200"] = 56, ["E000201"] = 6, ["E310700"] = 24,
		["E30BD00"] = 16, ["C308F00"] = 1, ["E302600"] = 9, ["E310701"] = 4, ["E302402"] = 32, ["C30CA00"] = 1,
		["E30CD00"] = 78, ["C313800"] = 2, ["E305500"] = 3, ["E30B500"] = 1, ["C317500"] = 1,
	},
	[1] = {
		["C305500"] = 1, ["E000703"] = 2, ["E309200"] = 48, ["E302700"] = 11, ["E310700"] = 38, ["E30BD00"] = 48,
		["C308F00"] = 1, ["E302500"] = 5, ["E302600"] = 10, ["E310701"] = 12, ["E302402"] = 12, ["C30CA00"] = 1,
		["E30CD00"] = 78, ["E305500"] = 3, ["C317500"] = 1,
	},
	[2] = {
		["C200000"] = 1, ["C305500"] = 1, ["E309200"] = 16, ["E302700"] = 29, ["E309700"] = 14, ["E310700"] = 10,
		["E30BD00"] = 70, ["C308F00"] = 1, ["E302500"] = 5, ["E302600"] = 10, ["E310701"] = 19, ["E302402"] = 6,
		["C30CA00"] = 1, ["E30CD00"] = 48, ["E305500"] = 40, ["C317500"] = 1,
	},
	[3] = {
		["C305500"] = 1, ["E000703"] = 6, ["E302700"] = 29, ["E310700"] = 74, ["E302500"] = 5, ["E302600"] = 24,
		["E310701"] = 4, ["E308702"] = 1, ["E302402"] = 28, ["E317700"] = 2, ["E000701"] = 1, ["E305500"] = 55,
		["C317500"] = 1, ["C316B00"] = 1,
	},
	[4] = {
		["E317B00"] = 52, ["C316D00"] = 1, ["E309200"] = 76, ["E302700"] = 7, ["E309700"] = 20, ["E307B00"] = 82,
		["C307800"] = 1, ["C308F00"] = 1, ["C310700"] = 1, ["E302500"] = 23, ["E302600"] = 10, ["E310701"] = 4,
		["E302402"] = 4, ["E317501"] = 5, ["E30B500"] = 9, ["C317500"] = 1,
	},
	[5] = {
		["E30A000"] = 60, ["C200000"] = 1, ["C305500"] = 1, ["E302700"] = 15, ["E303D00"] = 2, ["E310700"] = 9,
		["E316800"] = 12, ["C303C00"] = 1, ["E302500"] = 23, ["E302600"] = 5, ["E310701"] = 48, ["E30C800"] = 4,
		["C30CA00"] = 1, ["E30CD00"] = 42, ["E305500"] = 57, ["C317500"] = 1,
	},
	[6] = {
		["C200000"] = 1, ["C305500"] = 1, ["E000703"] = 2, ["E302700"] = 13, ["E316500"] = 8, ["E307B00"] = 8,
		["E310700"] = 44, ["C307800"] = 1, ["E302500"] = 23, ["E302600"] = 9, ["E310701"] = 3, ["E312502"] = 6,
		["E30C800"] = 20, ["C30CA01"] = 1, ["C313800"] = 2, ["E305500"] = 9, ["C317500"] = 1,
	},
	[7] = {
		["C200000"] = 1, ["C305500"] = 1, ["E302700"] = 3, ["E309700"] = 108, ["E307B00"] = 20, ["E310700"] = 18,
		["E307B01"] = 26, ["C307800"] = 1, ["C307801"] = 1, ["E302500"] = 63, ["E302600"] = 34, ["E308702"] = 5,
		["E30C800"] = 2, ["C30CA01"] = 1, ["E200000"] = 6, ["E305500"] = 3, ["C317500"] = 1,
	},
	[8] = {
		["C200000"] = 1, ["C305500"] = 1, ["E309700"] = 112, ["E310700"] = 50, ["E30BD00"] = 14, ["E307000"] = 14,
		["E314400"] = 128, ["E302500"] = 45, ["E302600"] = 98, ["E30C800"] = 42, ["C30CA00"] = 1, ["E30CD00"] = 62,
		["E317700"] = 2, ["E305500"] = 3, ["C316B00"] = 1,
	},
	[9] = {
		["E30A000"] = 128, ["C200000"] = 1, ["C305500"] = 1, ["E309700"] = 102, ["E310700"] = 54, ["E305400"] = 102,
		["E30BD00"] = 15, ["E307400"] = 52, ["E302600"] = 10, ["E310701"] = 28, ["C30CA00"] = 1, ["E30CD00"] = 22,
		["E317700"] = 2, ["E305500"] = 55, ["C316B00"] = 1,
	},
	[10] = {
		["C200000"] = 1, ["E309200"] = 18, ["E302700"] = 3, ["E310700"] = 20, ["E305400"] = 8, ["C308F00"] = 1,
		["E302500"] = 51, ["E302600"] = 14, ["E310701"] = 8, ["E30C800"] = 1, ["C30CA00"] = 1, ["E30CD00"] = 112,
		["C30CA01"] = 1, ["E308700"] = 5, ["C317500"] = 1, ["E316B02"] = 4,
	},
	[11] = {
		["C305500"] = 1, ["E309200"] = 32, ["E307B00"] = 18, ["E305400"] = 12, ["E000202"] = 12, ["C307800"] = 1,
		["E316800"] = 2, ["C308F00"] = 1, ["C310700"] = 1, ["E302600"] = 30, ["E310701"] = 12, ["E312401"] = 6,
		["E30C800"] = 2, ["C30CA00"] = 1, ["E30CD00"] = 114, ["E305500"] = 5, ["C317500"] = 1,
	},
	[12] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["C305500"] = 1, ["E309200"] = 20, ["E309700"] = 14, ["E310700"] = 8,
		["E305400"] = 10, ["E30BD00"] = 32, ["C308F00"] = 1, ["E302500"] = 44, ["E302600"] = 22, ["E310701"] = 14,
		["C30CA00"] = 1, ["E30CD00"] = 100, ["C30CA01"] = 1, ["E305500"] = 13, ["C317500"] = 1,
	},
	[13] = {
		["E30A000"] = 72, ["C200000"] = 1, ["C305500"] = 1, ["E309200"] = 32, ["E310700"] = 128, ["E305400"] = 10,
		["C308F00"] = 1, ["E302500"] = 48, ["E100000"] = 40, ["E302600"] = 20, ["E310701"] = 122, ["E312501"] = 10,
		["C30CA01"] = 1, ["E200000"] = 20, ["E305500"] = 13, ["C317500"] = 1,
	},
	[14] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["E30A000"] = 44, ["C200000"] = 1, ["C305500"] = 1, ["E000703"] = 3,
		["E309200"] = 14, ["E316500"] = 78, ["E309700"] = 12, ["E305400"] = 56, ["E30BD00"] = 50, ["C308F00"] = 1,
		["C310700"] = 1, ["E302500"] = 3, ["E302600"] = 18, ["C30CA01"] = 1, ["C313800"] = 2, ["E305500"] = 17,
		["C317500"] = 1,
	},
	[15] = {
		["E317B00"] = 20, ["C316D00"] = 1, ["E30A000"] = 94, ["C200000"] = 1, ["C305500"] = 1, ["E000703"] = 2,
		["E309200"] = 52, ["E309700"] = 34, ["E310700"] = 8, ["E305400"] = 56, ["C308F00"] = 1, ["E310701"] = 96,
		["E30C800"] = 22, ["E305500"] = 127, ["E30B500"] = 9,
	},
	[16] = {
		["E317B00"] = 88, ["C316D00"] = 1, ["E30A000"] = 58, ["C200000"] = 1, ["C305500"] = 1, ["E000703"] = 1,
		["E309200"] = 14, ["E316500"] = 26, ["E310700"] = 10, ["E305400"] = 18, ["E30BD00"] = 40, ["C308F00"] = 1,
		["E302500"] = 71, ["E310701"] = 16, ["C30CA00"] = 1, ["E30CD00"] = 2, ["C30CA01"] = 1,
	},
	[17] = {
		["C200000"] = 1, ["E309200"] = 68, ["E316500"] = 28, ["E309700"] = 40, ["E310700"] = 21, ["E305400"] = 18,
		["E30BD00"] = 8, ["C308F00"] = 1, ["E302500"] = 73, ["E302600"] = 116, ["E310701"] = 6, ["E302402"] = 62,
		["C30CA00"] = 1, ["E30CD00"] = 6, ["C30CA01"] = 1,
	},
	[18] = {
		["E317B00"] = 78, ["C316D00"] = 1, ["C200000"] = 1, ["E309200"] = 4, ["E302700"] = 3, ["E316500"] = 76,
		["E310700"] = 28, ["E305400"] = 18, ["E30BD00"] = 38, ["C308F00"] = 1, ["E302600"] = 4, ["E310701"] = 90,
		["E30C800"] = 20, ["C30CA01"] = 1, ["C313800"] = 2, ["E316B01"] = 12,
	},
	[19] = {
		["E316D00"] = 4, ["E309200"] = 4, ["E302700"] = 3, ["E310700"] = 18, ["E305400"] = 18, ["E30BD00"] = 14,
		["C308F00"] = 1, ["E302600"] = 3, ["E310701"] = 4, ["E302402"] = 8, ["E30C800"] = 2, ["E30B500"] = 1,
	},
	[20] = {
		["C200000"] = 1, ["E309200"] = 2, ["E302700"] = 3, ["E305400"] = 18, ["C308F00"] = 1, ["E302600"] = 1,
		["E310701"] = 1, ["E308702"] = 1, ["E302402"] = 8, ["E000701"] = 1, ["E30B500"] = 5, ["C317500"] = 1,
		["E316B02"] = 6,
	},
	[21] = {
		["C200000"] = 1, ["E309200"] = 2, ["E302700"] = 3, ["E310700"] = 19, ["E305400"] = 18, ["C308F00"] = 1,
		["E302600"] = 1, ["E310701"] = 2, ["E308702"] = 1, ["C313800"] = 2, ["E000701"] = 1, ["E30BA00"] = 6,
		["E30B500"] = 1, ["E317600"] = 10,
	},
	[22] = {
		["C200000"] = 1, ["C305500"] = 1, ["E000703"] = 2, ["E302700"] = 3, ["E316500"] = 8, ["E310700"] = 16,
		["E302600"] = 10, ["E310701"] = 4, ["E308702"] = 1, ["E30C800"] = 14, ["C30CA01"] = 1, ["E30AC01"] = 2,
		["C313800"] = 2, ["E305500"] = 3, ["E30B500"] = 1,
	},
	[23] = {
		["E30A000"] = 24, ["C200000"] = 1, ["C305500"] = 1, ["E000703"] = 4, ["E309200"] = 2, ["E302700"] = 3,
		["E316500"] = 10, ["E309700"] = 14, ["E307B01"] = 128, ["E307400"] = 8, ["C308F00"] = 1, ["C307801"] = 1,
		["C310700"] = 1, ["E302500"] = 127, ["E302600"] = 7, ["C30CA01"] = 1, ["C313800"] = 1, ["E305500"] = 5,
	},
	[24] = {
		["E30A000"] = 10, ["C200000"] = 1, ["C305500"] = 1, ["E305400"] = 114, ["E30BD00"] = 8, ["E000200"] = 34,
		["E307400"] = 128, ["E302500"] = 10, ["E302600"] = 10, ["E310701"] = 12, ["C30CA01"] = 1, ["E317700"] = 8,
		["C313800"] = 2, ["E305500"] = 5, ["C316B00"] = 1,
	},
	[25] = {
		["E316700"] = 6, ["C200000"] = 1, ["C305500"] = 1, ["E302700"] = 2, ["E309700"] = 3, ["E305400"] = 114,
		["E000200"] = 34, ["E307400"] = 128, ["E302500"] = 10, ["E310701"] = 6, ["C30CA01"] = 1, ["E305500"] = 9,
		["E30B900"] = 4, ["E30B500"] = 1,
	},
	[26] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["C200000"] = 1, ["C305500"] = 1, ["E302700"] = 3, ["E309700"] = 12,
		["E305400"] = 114, ["E000200"] = 16, ["E307400"] = 128, ["E302500"] = 3, ["E302600"] = 16, ["E310701"] = 6,
		["E305500"] = 9, ["E30B900"] = 4,
	},
	[27] = {
		["E30A000"] = 28, ["C200000"] = 1, ["E302700"] = 5, ["E303D00"] = 10, ["E309700"] = 6, ["E307B00"] = 48,
		["E307B01"] = 26, ["C307800"] = 1, ["E30BD00"] = 94, ["E307400"] = 8, ["C307801"] = 1, ["C310700"] = 1,
		["C303C00"] = 1, ["E310701"] = 3, ["E30C800"] = 2, ["C30CA00"] = 1, ["E30CD00"] = 14,
	},
	[28] = {
		["E30A000"] = 2, ["C305500"] = 1, ["E302700"] = 2, ["E310700"] = 11, ["E30BD00"] = 22, ["E307400"] = 8,
		["E302600"] = 2, ["E310701"] = 26, ["E30C800"] = 42, ["C30CA00"] = 1, ["E30CD00"] = 30, ["E305500"] = 43,
		["E316A00"] = 20,
	},
	[29] = {
		["E316700"] = 20, ["C200000"] = 1, ["C305500"] = 1, ["E302700"] = 3, ["E310700"] = 11, ["E307400"] = 2,
		["E310702"] = 91, ["E302500"] = 19, ["E302600"] = 10, ["E310701"] = 33, ["E308501"] = 8, ["E30C800"] = 70,
		["C30CA01"] = 1, ["C313800"] = 2, ["E305500"] = 13,
	},
	[30] = {
		["C200000"] = 1, ["E302700"] = 3, ["E310700"] = 3, ["E305400"] = 8, ["E302500"] = 1, ["E302600"] = 10,
		["E310701"] = 4, ["E308702"] = 1, ["E30C800"] = 18, ["C313800"] = 2, ["E316C00"] = 8,
	},
	[31] = {
		["E317B00"] = 22, ["C316D00"] = 1, ["E30A000"] = 88, ["C200000"] = 1, ["E302700"] = 9, ["E305400"] = 8,
		["E307B01"] = 38, ["C307801"] = 1, ["E307E00"] = 20, ["C310700"] = 1, ["E308400"] = 8, ["E302500"] = 51,
		["E302600"] = 10, ["E310701"] = 3, ["E30B500"] = 7,
	},
	[32] = {
		["E317B00"] = 20, ["C316D00"] = 1, ["C305500"] = 1, ["E307B01"] = 32, ["E30BC00"] = 8, ["C310700"] = 1,
		["E305400"] = 8, ["E302500"] = 63, ["E302700"] = 21, ["C307801"] = 1, ["E302600"] = 20, ["E310701"] = 35,
		["E310702"] = 56, ["C200000"] = 1,
	},
	[33] = {
		["C305500"] = 1, ["E305500"] = 41, ["E309700"] = 42, ["C310700"] = 1, ["E305400"] = 60, ["E302500"] = 63,
		["E303D00"] = 34, ["E302700"] = 63, ["E302600"] = 54, ["C303C00"] = 1, ["E30C800"] = 8, ["E310701"] = 46,
		["C200000"] = 1,
	},
	[34] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["E30BD00"] = 6, ["C305500"] = 1, ["E307B01"] = 38, ["C317500"] = 1,
		["C310700"] = 1, ["E305400"] = 44, ["E302500"] = 30, ["C307801"] = 1, ["E302600"] = 32, ["E30CD00"] = 2,
		["C30CA00"] = 1, ["E310701"] = 6, ["C200000"] = 1, ["E316500"] = 28,
	},
	[35] = {
		["E317B00"] = 48, ["C316D00"] = 1, ["E305400"] = 6, ["E302700"] = 3, ["E302600"] = 1, ["C30CA01"] = 1,
		["E310700"] = 16, ["E30C800"] = 18, ["E310701"] = 3,
	},
	[36] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 5, ["C317500"] = 1, ["E305400"] = 6,
		["C30CA01"] = 1, ["E310700"] = 22, ["E312501"] = 12, ["E30B500"] = 11, ["E30C800"] = 2, ["E310701"] = 12,
		["C200000"] = 1, ["E316500"] = 10,
	},
	[37] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E30BD00"] = 50, ["C317500"] = 1, ["E309700"] = 8, ["E305400"] = 20,
		["C307800"] = 1, ["E30CD00"] = 62, ["C30CA00"] = 1, ["E310700"] = 41, ["E302402"] = 6, ["E310701"] = 40,
		["C200000"] = 1, ["E307B00"] = 16,
	},
	[38] = {
		["C305500"] = 1, ["E305500"] = 11, ["C310700"] = 1, ["C307800"] = 1, ["E307200"] = 20, ["E302600"] = 10,
		["E30CD00"] = 60, ["C30CA00"] = 1, ["E317501"] = 8, ["E30C800"] = 1, ["E310701"] = 58, ["E30A000"] = 16,
		["C200000"] = 1, ["E307B00"] = 46,
	},
	[39] = {
		["E316900"] = 22, ["C305500"] = 1, ["C317500"] = 1, ["C307800"] = 1, ["E307400"] = 22, ["E312801"] = 4,
		["E302600"] = 5, ["C30CA01"] = 1, ["E30B500"] = 1, ["E30C800"] = 12, ["C313800"] = 1, ["E310701"] = 8,
		["E310702"] = 1, ["C200000"] = 1, ["E307B00"] = 12,
	},
	[40] = {
		["E30BD00"] = 17, ["C305500"] = 1, ["E309700"] = 3, ["E302500"] = 4, ["E307000"] = 26, ["E309200"] = 10,
		["C30CA01"] = 1, ["C308F00"] = 1, ["E30C800"] = 16, ["C313800"] = 1, ["E310701"] = 8, ["E310702"] = 1,
		["C200000"] = 1, ["E316500"] = 10,
	},
	[41] = {
		["E200006"] = 6, ["C305500"] = 1, ["E305500"] = 7, ["E309700"] = 4, ["E302500"] = 30, ["E302700"] = 3,
		["C30CA01"] = 1, ["E317501"] = 8, ["E310700"] = 4, ["E30C800"] = 12, ["E310701"] = 4,
	},
	[42] = {
		["E30BD00"] = 3, ["C305500"] = 1, ["E305500"] = 11, ["E309700"] = 3, ["E302500"] = 10, ["E307400"] = 20,
		["C30CA01"] = 1, ["E310700"] = 4, ["E30B500"] = 1, ["E30C800"] = 12, ["C313800"] = 2, ["E310701"] = 14,
		["C200000"] = 1,
	},
	[43] = {
		["C316B00"] = 1, ["C305500"] = 1, ["E305500"] = 9, ["C317500"] = 1, ["E309700"] = 4, ["E302500"] = 27,
		["E307400"] = 2, ["E302700"] = 3, ["E317700"] = 8, ["E30B500"] = 1, ["E30C800"] = 28, ["C313800"] = 2,
		["E310701"] = 1, ["C200000"] = 1,
	},
	[44] = {
		["E316700"] = 34, ["C305500"] = 1, ["E305500"] = 15, ["E308702"] = 11, ["E302600"] = 22, ["E30C800"] = 26,
		["E310701"] = 124, ["E30A000"] = 46, ["C200000"] = 1,
	},
	[45] = {
		["E316700"] = 40, ["C305500"] = 1, ["E305500"] = 27, ["E309700"] = 4, ["E317600"] = 20, ["E302500"] = 29,
		["E302700"] = 55, ["E30CD00"] = 14, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 64, ["E316500"] = 36,
	},
	[46] = {
		["C316D00"] = 1, ["E30BD00"] = 50, ["E305400"] = 120, ["E307400"] = 38, ["E302700"] = 27, ["E302600"] = 15,
		["E309200"] = 16, ["C30CA01"] = 1, ["C308F00"] = 1, ["E30C800"] = 3, ["C200000"] = 1,
	},
	[47] = {
		["E307B01"] = 22, ["E309700"] = 32, ["C310700"] = 1, ["C307800"] = 1, ["E317600"] = 4, ["E302500"] = 48,
		["E307400"] = 2, ["C307801"] = 1, ["E30CD00"] = 56, ["E309200"] = 40, ["C30CA00"] = 1, ["C308F00"] = 1,
		["C313800"] = 1, ["E310702"] = 20, ["C200000"] = 1, ["E307B00"] = 64,
	},
	[48] = {
		["C305500"] = 1, ["E305500"] = 27, ["E302500"] = 37, ["E307400"] = 2, ["E302700"] = 5, ["E302600"] = 36,
		["E000501"] = 6, ["E30C800"] = 6, ["C313800"] = 1, ["E310701"] = 16, ["C200000"] = 1, ["E316500"] = 42,
	},
	[49] = {
		["C305500"] = 1, ["E308400"] = 6, ["E305500"] = 29, ["C310700"] = 1, ["E302500"] = 36, ["E307400"] = 2,
		["E302700"] = 5, ["E302600"] = 36, ["E30C800"] = 8, ["E310701"] = 46, ["C200000"] = 1, ["E316500"] = 2,
	},
	[50] = {
		["C305500"] = 1, ["E305500"] = 37, ["E309700"] = 28, ["E305400"] = 38, ["E302700"] = 3, ["E302600"] = 4,
		["E30C800"] = 9, ["C313800"] = 1, ["E310701"] = 16, ["E30A000"] = 40, ["C200000"] = 1, ["E316500"] = 2,
	},
	[51] = {
		["C305500"] = 1, ["E305500"] = 37, ["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 39, ["E302700"] = 3,
		["E302600"] = 12, ["E30CD00"] = 40, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E302402"] = 48, ["E30C800"] = 42,
		["C313800"] = 2, ["E316500"] = 6, ["E307B00"] = 18,
	},
	[52] = {
		["C305500"] = 1, ["E305500"] = 19, ["E309700"] = 24, ["E302500"] = 37, ["E302700"] = 3, ["E302600"] = 12,
		["E310700"] = 16, ["E30C800"] = 38, ["E310701"] = 16, ["C200000"] = 1, ["E316500"] = 2,
	},
	[53] = {
		["C316B00"] = 1, ["E302500"] = 60, ["E303D00"] = 48, ["E317700"] = 16, ["E302600"] = 52, ["E30CD00"] = 28,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["C303C00"] = 1, ["E310700"] = 21, ["E30C800"] = 7, ["C313800"] = 2,
		["E310701"] = 10, ["C200000"] = 1, ["E200005"] = 22,
	},
	[54] = {
		["E317B00"] = 10, ["C316D00"] = 1, ["C316B00"] = 1, ["E316800"] = 13, ["E302500"] = 36, ["E302700"] = 2,
		["E317700"] = 42, ["E302600"] = 7, ["E310700"] = 17, ["E302402"] = 16, ["E310701"] = 8,
	},
	[55] = {
		["C305500"] = 1, ["E305500"] = 3, ["E302500"] = 19, ["E302600"] = 7, ["E30CD00"] = 34, ["C30CA00"] = 1,
		["E000703"] = 2, ["E310700"] = 16, ["E30B500"] = 13, ["E30C800"] = 16, ["C313800"] = 2, ["E310701"] = 4,
		["C200000"] = 1,
	},
	[56] = {
		["E316D00"] = 24, ["E316800"] = 23, ["C305500"] = 1, ["E302500"] = 61, ["E302700"] = 58, ["E302600"] = 52,
		["E309200"] = 30, ["C30CA01"] = 1, ["E310700"] = 36, ["C308F00"] = 1, ["E310701"] = 4, ["E30A000"] = 4,
		["C200000"] = 1,
	},
	[57] = {
		["C305500"] = 1, ["E305500"] = 59, ["E302500"] = 57, ["E307000"] = 4, ["E302700"] = 51, ["E302600"] = 10,
		["E310700"] = 56, ["E310701"] = 5, ["E30A000"] = 6, ["C200000"] = 1, ["E316500"] = 26,
	},
	[58] = {
		["C305500"] = 1, ["E30BC00"] = 6, ["E305500"] = 7, ["E302500"] = 61, ["E302700"] = 63, ["E302400"] = 42,
		["E302600"] = 10, ["E309200"] = 2, ["E310700"] = 50, ["C308F00"] = 1, ["E310701"] = 6, ["E30A000"] = 6,
		["C200000"] = 1,
	},
	[59] = {
		["C305500"] = 1, ["E307B01"] = 64, ["E30BC00"] = 12, ["E302500"] = 30, ["E307000"] = 4, ["E302700"] = 27,
		["C307801"] = 1, ["E302600"] = 10, ["C30CA01"] = 1, ["E310700"] = 10, ["E302402"] = 18, ["E310701"] = 4,
		["E30A000"] = 20, ["C200000"] = 1,
	},
	[60] = {
		["E30BD00"] = 18, ["E309700"] = 2, ["E305400"] = 52, ["E302700"] = 9, ["E302600"] = 61, ["C30CA01"] = 1,
		["E310700"] = 26, ["E302402"] = 20, ["E310701"] = 6, ["C200000"] = 1, ["E316500"] = 36,
	},
	[61] = {
		["E30BD00"] = 6, ["C305500"] = 1, ["E305500"] = 3, ["E305400"] = 52, ["E308F00"] = 22, ["E302500"] = 49,
		["E302600"] = 14, ["E310700"] = 7, ["E316F00"] = 4, ["E310701"] = 8,
	},
	[62] = {
		["E316D00"] = 10, ["E305400"] = 52, ["E302500"] = 27, ["E302700"] = 5, ["E302600"] = 14, ["E307701"] = 22,
		["C30CA01"] = 1, ["E310700"] = 18, ["E310701"] = 8, ["E309C00"] = 10,
	},
	[63] = {
		["E309700"] = 78, ["E305400"] = 72, ["E302500"] = 58, ["E30CD00"] = 100, ["E309200"] = 6, ["C30CA00"] = 1,
		["C308F00"] = 1, ["E302402"] = 21, ["C313800"] = 2, ["C200000"] = 1, ["E316500"] = 46,
	},
	[64] = {
		["E30BD00"] = 13, ["C305500"] = 1, ["E305500"] = 81, ["E305400"] = 72, ["E302500"] = 43, ["E30CD00"] = 80,
		["C30CA00"] = 1, ["E302402"] = 46, ["E310701"] = 12, ["C200000"] = 1,
	},
	[65] = {
		["C305500"] = 1, ["E305500"] = 55, ["C317500"] = 1, ["E305400"] = 72, ["E302500"] = 58, ["E302600"] = 9,
		["E30CD00"] = 80, ["C30CA00"] = 1, ["E302402"] = 48, ["E310701"] = 12, ["C200000"] = 1,
	},
	[66] = {
		["C305500"] = 1, ["E305500"] = 3, ["E305400"] = 52, ["E302500"] = 35, ["E302700"] = 21, ["E307200"] = 20,
		["E302600"] = 9, ["E310700"] = 6, ["E30C800"] = 4, ["E310701"] = 4,
	},
	[67] = {
		["E317B00"] = 38, ["C316D00"] = 1, ["C305500"] = 1, ["E307B01"] = 24, ["E305400"] = 52, ["E302500"] = 58,
		["E302700"] = 9, ["E307200"] = 20, ["C307801"] = 1, ["E302600"] = 64, ["C30CA01"] = 1, ["E310700"] = 10,
		["E310701"] = 2,
	},
	[68] = {
		["E317B00"] = 50, ["C316D00"] = 1, ["E30BD00"] = 23, ["C305500"] = 1, ["E305500"] = 63, ["E305400"] = 16,
		["E307400"] = 26, ["E302700"] = 31, ["E302600"] = 64, ["E310700"] = 5, ["C200000"] = 1, ["E316500"] = 4,
	},
	[69] = {
		["E317B00"] = 40, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 39, ["E305400"] = 16, ["C307800"] = 1,
		["E307400"] = 26, ["E302700"] = 25, ["E302600"] = 22, ["C30CA01"] = 1, ["E310700"] = 34, ["E302402"] = 39,
		["C200000"] = 1, ["E307B00"] = 36,
	},
	[70] = {
		["E30BC00"] = 8, ["C317500"] = 1, ["E305400"] = 90, ["E302700"] = 11, ["E302600"] = 14, ["E309200"] = 2,
		["E310700"] = 28, ["C308F00"] = 1, ["E30C800"] = 24, ["C200000"] = 1,
	},
	[71] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["E316800"] = 4, ["E308400"] = 4, ["C317500"] = 1, ["E305400"] = 34,
		["E302500"] = 56, ["E302600"] = 6, ["E310700"] = 46, ["E30C800"] = 22, ["E310701"] = 4, ["C200000"] = 1,
	},
	[72] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 37, ["C317500"] = 1, ["E000201"] = 36,
		["E302700"] = 5, ["E302600"] = 47, ["E310700"] = 20, ["E30C800"] = 22, ["E310701"] = 4, ["E310702"] = 45,
		["C200000"] = 1,
	},
	[73] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 9, ["C317500"] = 1, ["E309700"] = 44,
		["E302700"] = 31, ["E302600"] = 10, ["E307E00"] = 3, ["E310700"] = 48, ["E30C800"] = 22, ["E310701"] = 7,
	},
	[74] = {
		["E317B00"] = 26, ["C316D00"] = 1, ["C316B00"] = 1, ["C305500"] = 1, ["E305500"] = 5, ["E309700"] = 10,
		["E302500"] = 3, ["E302700"] = 57, ["E317700"] = 2, ["E302600"] = 44, ["E309200"] = 4, ["E310700"] = 7,
		["C308F00"] = 1, ["C313800"] = 1, ["C200000"] = 1,
	},
	[75] = {
		["E30BD00"] = 49, ["C317500"] = 1, ["E305400"] = 74, ["E302500"] = 37, ["E307400"] = 72, ["E302700"] = 7,
		["E30CD00"] = 58, ["C30CA00"] = 1, ["E302402"] = 72, ["C313800"] = 2, ["C200000"] = 1,
	},
	[76] = {
		["E30BD00"] = 40, ["C305500"] = 1, ["E307B01"] = 14, ["C317500"] = 1, ["E305400"] = 62, ["E302500"] = 19,
		["E307400"] = 64, ["C307801"] = 1, ["E302600"] = 26, ["E30CD00"] = 56, ["E000200"] = 20, ["C30CA00"] = 1,
		["E302402"] = 52, ["C313800"] = 2, ["C200000"] = 1,
	},
	[77] = {
		["C317500"] = 1, ["C310700"] = 1, ["E305400"] = 52, ["C307800"] = 1, ["E302500"] = 56, ["E307400"] = 56,
		["E302600"] = 10, ["E30CD00"] = 56, ["E309200"] = 34, ["C30CA00"] = 1, ["C308F00"] = 1, ["E302402"] = 32,
		["E310701"] = 64, ["E307B00"] = 20,
	},
	[78] = {
		["E30BD00"] = 17, ["E307B01"] = 56, ["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 61, ["C307801"] = 1,
		["E30CD00"] = 64, ["E309200"] = 44, ["C30CA00"] = 1, ["C308F00"] = 1, ["E302402"] = 34, ["E310701"] = 46,
		["E30A000"] = 8, ["C200000"] = 1, ["E307B00"] = 62,
	},
	[79] = {
		["C316B00"] = 1, ["C305500"] = 1, ["E305500"] = 15, ["E309700"] = 64, ["E302500"] = 13, ["E302700"] = 37,
		["E317700"] = 32, ["E309200"] = 56, ["C30CA01"] = 1, ["C308F00"] = 1, ["E30C800"] = 24, ["E310702"] = 31,
		["C200000"] = 1, ["E316500"] = 52,
	},
	[80] = {
		["C305500"] = 1, ["E305500"] = 17, ["C317500"] = 1, ["E309700"] = 64, ["C310700"] = 1, ["C307800"] = 1,
		["E302500"] = 3, ["E302700"] = 37, ["E309200"] = 58, ["C308F00"] = 1, ["E30C800"] = 24, ["E310701"] = 6,
		["E30A000"] = 64, ["C200000"] = 1, ["E307B00"] = 4,
	},
	[81] = {
		["C305500"] = 1, ["E305500"] = 6, ["C317500"] = 1, ["E317600"] = 16, ["E302500"] = 6, ["E30CD00"] = 18,
		["E309200"] = 2, ["C30CA00"] = 1, ["E310700"] = 19, ["C308F00"] = 1, ["E302402"] = 14, ["C200001"] = 1,
		["E310701"] = 12, ["E316500"] = 10,
	},
	[82] = {
		["C305500"] = 1, ["E305500"] = 27, ["E309700"] = 42, ["E305400"] = 28, ["E100001"] = 22, ["E302700"] = 21,
		["E302600"] = 10, ["C30CA01"] = 1, ["E310700"] = 14, ["E312300"] = 10, ["E30C800"] = 23, ["C200000"] = 1,
	},
	[83] = {
		["C305500"] = 1, ["E305500"] = 25, ["E309700"] = 26, ["E302500"] = 39, ["E302700"] = 25, ["E302600"] = 12,
		["E000703"] = 28, ["E310700"] = 10, ["E302402"] = 2, ["E30C800"] = 30,
	},
	[84] = {
		["C305500"] = 1, ["E309700"] = 56, ["E305400"] = 24, ["E303D00"] = 4, ["E302600"] = 11, ["E309200"] = 64,
		["C303C00"] = 1, ["E314400"] = 36, ["C308F00"] = 1, ["E302402"] = 28, ["E310701"] = 30, ["E30A000"] = 64,
		["C200000"] = 1,
	},
	[85] = {
		["C316B00"] = 1, ["E30BD00"] = 10, ["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 4, ["C310700"] = 1,
		["E305400"] = 24, ["E302700"] = 9, ["E317700"] = 2, ["E302600"] = 20, ["E30CD00"] = 22, ["C30CA00"] = 1,
		["E30B500"] = 1, ["E30C800"] = 2, ["C200000"] = 1,
	},
	[86] = {
		["E317000"] = 2, ["C305500"] = 1, ["C317500"] = 1, ["E302500"] = 7, ["E302600"] = 8, ["E30CD00"] = 10,
		["C30CA00"] = 1, ["E310700"] = 19, ["E30BC01"] = 13, ["E312501"] = 14, ["E30C800"] = 10, ["E310701"] = 10,
	},
	[87] = {
		["C316B00"] = 1, ["C305500"] = 1, ["E305500"] = 7, ["C317500"] = 1, ["E302500"] = 7, ["E303D00"] = 2,
		["E302700"] = 37, ["E317700"] = 20, ["E302600"] = 44, ["C30CA01"] = 1, ["C303C00"] = 1, ["E302402"] = 12,
		["E310701"] = 42, ["C200000"] = 1, ["E316500"] = 34,
	},
	[88] = {
		["E317B00"] = 60, ["C316D00"] = 1, ["C317500"] = 1, ["E309700"] = 41, ["C307800"] = 1, ["E302700"] = 11,
		["E307300"] = 13, ["E310700"] = 8, ["E302402"] = 12, ["E30C800"] = 6, ["E310701"] = 4, ["C200000"] = 1,
		["E307B00"] = 32,
	},
	[89] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 21, ["C317500"] = 1, ["C307800"] = 1,
		["E302700"] = 49, ["E307200"] = 10, ["E307300"] = 3, ["E302600"] = 48, ["E000703"] = 16, ["E310700"] = 20,
		["C200001"] = 1, ["C313800"] = 2, ["C200000"] = 1, ["E307B00"] = 30,
	},
	[90] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["E30BD00"] = 30, ["C305500"] = 1, ["E305500"] = 3, ["C317500"] = 1,
		["E309700"] = 8, ["E307400"] = 24, ["E302600"] = 10, ["E30CD00"] = 4, ["C30CA00"] = 1, ["E310700"] = 10,
		["C200001"] = 1, ["C313800"] = 2, ["E310701"] = 8, ["C200000"] = 1,
	},
	[91] = {
		["E316B00"] = 8, ["C305500"] = 1, ["E305500"] = 61, ["C317500"] = 1, ["E309700"] = 64, ["E308702"] = 19,
		["E302700"] = 13, ["E302600"] = 9, ["E310700"] = 22, ["E30B500"] = 5, ["E30C800"] = 4, ["C200000"] = 1,
	},
	[92] = {
		["C305500"] = 1, ["E305500"] = 3, ["C317500"] = 1, ["E305400"] = 112, ["E317600"] = 14, ["E302500"] = 28,
		["E302600"] = 7, ["E310700"] = 38, ["E30C800"] = 3, ["C200000"] = 1,
	},
	[93] = {
		["E30BD00"] = 54, ["C305500"] = 1, ["E305500"] = 59, ["C317500"] = 1, ["E309700"] = 64, ["E302700"] = 43,
		["E302600"] = 25, ["E30CD00"] = 26, ["C30CA00"] = 1, ["E310700"] = 15, ["E30C800"] = 29, ["E310701"] = 46,
		["C200000"] = 1,
	},
	[94] = {
		["E317B00"] = 20, ["C316D00"] = 1, ["E30BD00"] = 20, ["C305500"] = 1, ["E305500"] = 7, ["C317500"] = 1,
		["E308000"] = 24, ["E302600"] = 14, ["E310700"] = 19, ["E302402"] = 40, ["E30C800"] = 12, ["E310701"] = 19,
	},
	[95] = {
		["E317000"] = 2, ["C305500"] = 1, ["E305500"] = 9, ["C317500"] = 1, ["E309700"] = 30, ["E303D00"] = 30,
		["E302700"] = 15, ["E302600"] = 44, ["E309200"] = 24, ["C303C00"] = 1, ["E310700"] = 22, ["C308F00"] = 1,
		["E30C800"] = 20, ["C313800"] = 2,
	},
	[96] = {
		["E317B00"] = 32, ["C316D00"] = 1, ["E316A00"] = 6, ["E30BD00"] = 34, ["E302600"] = 20, ["E30CD00"] = 50,
		["C30CA00"] = 1, ["E310700"] = 18, ["E302402"] = 16, ["E200003"] = 8, ["E310701"] = 16, ["C200000"] = 1,
	},
	[97] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["E30BD00"] = 38, ["E308702"] = 5, ["E302600"] = 12, ["E30CD00"] = 52,
		["C30CA00"] = 1, ["E310700"] = 22, ["E302402"] = 14, ["E200003"] = 4, ["E310701"] = 14, ["C200000"] = 1,
	},
	[98] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["E30BD00"] = 32, ["C305500"] = 1, ["E305500"] = 37, ["E308702"] = 3,
		["E303D00"] = 12, ["E302600"] = 42, ["C303C00"] = 1, ["E310700"] = 9, ["E200003"] = 10, ["E310701"] = 7,
		["C200000"] = 1,
	},
	[99] = {
		["C305500"] = 1, ["E305500"] = 37, ["C317500"] = 1, ["E308702"] = 3, ["E305400"] = 2, ["E303D00"] = 12,
		["E302600"] = 40, ["E30CD00"] = 56, ["C30CA00"] = 1, ["C303C00"] = 1, ["E302401"] = 44, ["E310700"] = 64,
		["E310701"] = 4,
	},
	[100] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["E30BD00"] = 34, ["C305500"] = 1, ["E305500"] = 37, ["E305400"] = 2,
		["C307800"] = 1, ["E303D00"] = 10, ["E302600"] = 6, ["C303C00"] = 1, ["E310700"] = 14, ["E30C800"] = 10,
		["C200000"] = 1, ["E307B00"] = 34,
	},
	[101] = {
		["E317B00"] = 24, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 37, ["E305400"] = 2, ["C307800"] = 1,
		["E303D00"] = 10, ["E302600"] = 6, ["C303C00"] = 1, ["E310700"] = 34, ["E302402"] = 24, ["E30C800"] = 14,
		["C313800"] = 2, ["E307B00"] = 34,
	},
	[102] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["E316900"] = 20, ["C305500"] = 1, ["E307B01"] = 12, ["E305500"] = 29,
		["C317500"] = 1, ["E305400"] = 20, ["E307400"] = 42, ["C307801"] = 1, ["E310700"] = 32, ["E302402"] = 40,
		["C30AC00"] = 1, ["E310701"] = 48,
	},
	[103] = {
		["E316700"] = 14, ["C305500"] = 1, ["E305500"] = 45, ["E309700"] = 17, ["E305400"] = 46, ["E317600"] = 12,
		["E312600"] = 8, ["E310700"] = 30, ["E302402"] = 34, ["E310701"] = 48, ["C200000"] = 1,
	},
	[104] = {
		["C305500"] = 1, ["E305500"] = 3, ["C317500"] = 1, ["E305400"] = 20, ["E302500"] = 9, ["E307400"] = 34,
		["E302700"] = 3, ["E309200"] = 2, ["E310700"] = 62, ["C308F00"] = 1, ["E302402"] = 32, ["E30C800"] = 14,
		["C313800"] = 2,
	},
	[105] = {
		["E317B00"] = 32, ["C316D00"] = 1, ["C317500"] = 1, ["E309700"] = 48, ["E305400"] = 26, ["E307400"] = 62,
		["E302700"] = 21, ["C30CA01"] = 1, ["E302402"] = 10, ["E30C800"] = 44, ["E310702"] = 31, ["C200000"] = 1,
		["E200000"] = 26,
	},
	[106] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["E316B01"] = 4, ["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 19,
		["E305400"] = 28, ["E307400"] = 18, ["E30CD00"] = 6, ["E309200"] = 4, ["C30CA00"] = 1, ["C308F00"] = 1,
		["C313800"] = 2, ["E310701"] = 6, ["C200000"] = 1, ["E316500"] = 12,
	},
	[107] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 2, ["C317500"] = 1, ["E302600"] = 5,
		["E000703"] = 2, ["E310700"] = 24, ["E30C800"] = 14, ["E310701"] = 8, ["E30A000"] = 16, ["C200000"] = 1,
		["E316500"] = 24,
	},
	[108] = {
		["E317B00"] = 64, ["C316D00"] = 1, ["E30BD00"] = 64, ["C317500"] = 1, ["E309700"] = 8, ["E308702"] = 1,
		["E305400"] = 26, ["E307400"] = 12, ["E302600"] = 16, ["C30CA01"] = 1, ["E310700"] = 16, ["C313800"] = 2,
		["E30A000"] = 12, ["C200000"] = 1,
	},
	[109] = {
		["E30BD00"] = 40, ["C305500"] = 1, ["C307800"] = 1, ["E307400"] = 42, ["E303D00"] = 18, ["E302700"] = 64,
		["E309200"] = 48, ["C303C00"] = 1, ["E310700"] = 18, ["C308F00"] = 1, ["E30C800"] = 30, ["C200000"] = 1,
		["E316500"] = 64, ["E307B00"] = 28,
	},
	[110] = {
		["C317500"] = 1, ["E309700"] = 26, ["E305400"] = 4, ["C307800"] = 1, ["E302500"] = 5, ["E307400"] = 34,
		["E302700"] = 63, ["E302600"] = 9, ["E309200"] = 34, ["C30CA01"] = 1, ["E310700"] = 15, ["C308F00"] = 1,
		["C313800"] = 2, ["E307B00"] = 24,
	},
	[111] = {
		["C305500"] = 1, ["E307B01"] = 32, ["C317500"] = 1, ["E309700"] = 22, ["E305400"] = 12, ["E307400"] = 26,
		["E302700"] = 63, ["C307801"] = 1, ["E302600"] = 10, ["E309200"] = 48, ["C30CA01"] = 1, ["C308F00"] = 1,
		["E302402"] = 18, ["E30C800"] = 28, ["C200000"] = 1,
	},
	[112] = {
		["C305500"] = 1, ["E305500"] = 13, ["C317500"] = 1, ["E309700"] = 44, ["E305400"] = 12, ["E302700"] = 47,
		["E302600"] = 38, ["E309200"] = 64, ["E310700"] = 4, ["C308F00"] = 1, ["E302402"] = 14, ["E30C800"] = 30,
		["C200000"] = 1,
	},
	[113] = {
		["C305500"] = 1, ["E305500"] = 11, ["E308702"] = 7, ["E305400"] = 12, ["E302700"] = 3, ["E302600"] = 10,
		["E000703"] = 1, ["E310700"] = 14, ["E302402"] = 46, ["E30C800"] = 42, ["C200000"] = 1,
	},
	[114] = {
		["E316B00"] = 18, ["C305500"] = 1, ["E305500"] = 20, ["C317500"] = 1, ["E308F00"] = 24, ["E302500"] = 24,
		["E302700"] = 50, ["E302600"] = 44, ["E309200"] = 128, ["C308F00"] = 1, ["C313800"] = 2, ["C200000"] = 1,
	},
	[115] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E316B01"] = 4, ["C317500"] = 1, ["E305400"] = 4, ["E302500"] = 5,
		["E30CD00"] = 2, ["C30CA00"] = 1, ["E310700"] = 5, ["E30B500"] = 1, ["C313800"] = 2, ["E310701"] = 6,
		["C200000"] = 1, ["E316500"] = 8,
	},
	[116] = {
		["C317500"] = 1, ["E302500"] = 10, ["E310700"] = 1, ["E30B500"] = 1, ["E30C800"] = 2, ["E310701"] = 4,
		["E100004"] = 6, ["C200000"] = 1,
	},
	[117] = {
		["E316D00"] = 2, ["E30BD00"] = 51, ["C305500"] = 1, ["E305500"] = 7, ["C317500"] = 1, ["E302500"] = 10,
		["E302700"] = 34, ["E309200"] = 4, ["C30CA01"] = 1, ["E310700"] = 12, ["C308F00"] = 1, ["E302402"] = 36,
		["E30C800"] = 40, ["C200000"] = 1,
	},
	[118] = {
		["E30BD00"] = 50, ["E200008"] = 22, ["C305500"] = 1, ["E305500"] = 11, ["C317500"] = 1, ["E302500"] = 10,
		["E302700"] = 34, ["E30CD00"] = 54, ["E309200"] = 2, ["C30CA00"] = 1, ["C308F00"] = 1, ["E30C800"] = 24,
		["C200001"] = 1, ["E310701"] = 3, ["C200000"] = 1,
	},
	[119] = {
		["E317B00"] = 38, ["C316D00"] = 1, ["C305500"] = 1, ["C317500"] = 1, ["E302700"] = 35, ["E302600"] = 10,
		["E30CD00"] = 12, ["E309200"] = 10, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 12, ["C308F00"] = 1,
		["E30C800"] = 12, ["C30AC00"] = 1, ["E30A000"] = 48, ["C200000"] = 1, ["E316500"] = 64,
	},
	[120] = {
		["E30BD00"] = 36, ["C305500"] = 1, ["E305500"] = 7, ["C317500"] = 1, ["E308702"] = 1, ["E302500"] = 1,
		["E302700"] = 61, ["E302400"] = 26, ["E302600"] = 24, ["E309200"] = 12, ["E310700"] = 19, ["C308F00"] = 1,
		["C200000"] = 1,
	},
	[121] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E317600"] = 6, ["E302500"] = 15, ["E302700"] = 23, ["E302600"] = 11,
		["E30CD00"] = 28, ["C30CA00"] = 1, ["E310700"] = 28, ["E310702"] = 36, ["C200000"] = 1, ["E316500"] = 58,
	},
	[122] = {
		["E316900"] = 4, ["C305500"] = 1, ["E305500"] = 37, ["C317500"] = 1, ["E309700"] = 18, ["E302700"] = 17,
		["E302600"] = 9, ["E309200"] = 34, ["C30CA01"] = 1, ["E310700"] = 17, ["C308F00"] = 1, ["E302402"] = 24,
		["E30C800"] = 14, ["C313800"] = 2, ["C200000"] = 1,
	},
	[123] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E316900"] = 18, ["C305500"] = 1, ["E307B01"] = 30, ["E305500"] = 36,
		["C317500"] = 1, ["E302500"] = 12, ["C307801"] = 1, ["E309200"] = 32, ["C30CA01"] = 1, ["E310700"] = 20,
		["C308F00"] = 1, ["E302402"] = 22, ["E30C800"] = 12, ["C313800"] = 2, ["C200000"] = 1,
	},
	[124] = {
		["E317B00"] = 10, ["C316D00"] = 1, ["E316B00"] = 12, ["E307B01"] = 20, ["C317500"] = 1, ["C307800"] = 1,
		["E307400"] = 54, ["E302700"] = 9, ["C307801"] = 1, ["E302600"] = 37, ["E302402"] = 16, ["E30C800"] = 11,
		["C200001"] = 1, ["C313800"] = 2, ["C200000"] = 1, ["E307B00"] = 12,
	},
	[125] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["C317500"] = 1, ["E309700"] = 50, ["E307400"] = 30, ["E302700"] = 3,
		["E302600"] = 36, ["E309200"] = 22, ["C30CA01"] = 1, ["E310700"] = 3, ["C308F00"] = 1, ["E30B500"] = 7,
		["E30C800"] = 26, ["C313800"] = 2, ["C200000"] = 1,
	},
	[126] = {
		["E30BD00"] = 34, ["E307400"] = 12, ["E307200"] = 18, ["E302600"] = 14, ["E000501"] = 18, ["E316C00"] = 6,
		["E30A800"] = 12, ["E316F00"] = 6, ["E310701"] = 6, ["C200000"] = 1,
	},
	[127] = {
		["E317B00"] = 64, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 127, ["C317500"] = 1, ["E309700"] = 71,
		["C310700"] = 1, ["E307400"] = 44, ["E309200"] = 102, ["C30CA01"] = 1, ["E302401"] = 45, ["C308F00"] = 1,
		["E30C800"] = 64, ["C313800"] = 2, ["C200000"] = 1,
	},
	[128] = {
		["E317B00"] = 36, ["C316D00"] = 1, ["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 72, ["E302500"] = 67,
		["E307400"] = 120, ["E302700"] = 67, ["E302600"] = 59, ["C30CA01"] = 1, ["E30C800"] = 73, ["C200000"] = 1,
	},
	[129] = {
		["C305500"] = 1, ["E305500"] = 19, ["C317500"] = 1, ["E309700"] = 18, ["E302500"] = 19, ["E307400"] = 30,
		["E302700"] = 2, ["E302600"] = 12, ["E310700"] = 6, ["E30C800"] = 26, ["C313800"] = 1, ["E310701"] = 28,
		["C200000"] = 1,
	},
	[130] = {
		["C305500"] = 1, ["E305500"] = 19, ["C317500"] = 1, ["E309700"] = 28, ["E302500"] = 19, ["E307400"] = 26,
		["E302700"] = 2, ["E309200"] = 4, ["E310700"] = 10, ["C308F00"] = 1, ["E30C800"] = 22, ["E310701"] = 24,
		["C200000"] = 1,
	},
	[131] = {
		["E30BD00"] = 29, ["C305500"] = 1, ["E305500"] = 21, ["C317500"] = 1, ["E309700"] = 28, ["E302500"] = 19,
		["E307400"] = 26, ["E302700"] = 2, ["E309200"] = 2, ["C308F00"] = 1, ["E302402"] = 12, ["E30C800"] = 64,
		["C200000"] = 1,
	},
	[132] = {
		["E30BD00"] = 34, ["C305500"] = 1, ["E305500"] = 13, ["C317500"] = 1, ["E309700"] = 28, ["E305400"] = 26,
		["E302500"] = 19, ["E302700"] = 7, ["C30CA01"] = 1, ["E302402"] = 29, ["E310701"] = 34, ["C200000"] = 1,
		["E316500"] = 18,
	},
	[133] = {
		["E30BD00"] = 52, ["C305500"] = 1, ["E305500"] = 13, ["C317500"] = 1, ["E309700"] = 28, ["E305400"] = 26,
		["E302500"] = 19, ["E302700"] = 6, ["E302402"] = 36, ["E310701"] = 28, ["C200000"] = 1, ["E316500"] = 18,
	},
	[134] = {
		["C316B00"] = 1, ["E30BD00"] = 34, ["C305500"] = 1, ["E307B01"] = 42, ["E305500"] = 13, ["C317500"] = 1,
		["E309700"] = 26, ["E302700"] = 3, ["C307801"] = 1, ["E310700"] = 34, ["C313800"] = 2, ["E310701"] = 40,
		["E30A000"] = 14, ["C200000"] = 1, ["E316500"] = 16,
	},
	[135] = {
		["E307B01"] = 22, ["C317500"] = 1, ["E309700"] = 6, ["E305400"] = 26, ["E302500"] = 7, ["C307801"] = 1,
		["E302600"] = 10, ["E30CD00"] = 44, ["C30CA00"] = 1, ["E314400"] = 12, ["C313800"] = 2, ["E310701"] = 40,
		["C200000"] = 1, ["E316500"] = 22,
	},
	[136] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 41, ["C317500"] = 1, ["E309700"] = 72,
		["E302600"] = 3, ["E309200"] = 82, ["E310700"] = 127, ["C308F00"] = 1, ["C200000"] = 1, ["E316500"] = 30,
	},
	[137] = {
		["E30BD00"] = 10, ["C305500"] = 1, ["E305500"] = 35, ["C317500"] = 1, ["E309700"] = 13, ["E305400"] = 24,
		["E307400"] = 10, ["E302700"] = 51, ["E309200"] = 58, ["E310700"] = 24, ["C308F00"] = 1, ["E30C800"] = 26,
	},
	[138] = {
		["E30BC00"] = 2, ["C317500"] = 1, ["E309700"] = 2, ["E302700"] = 5, ["E302600"] = 3, ["C30CA01"] = 1,
		["E310700"] = 2, ["E30B500"] = 3, ["E310701"] = 3, ["E200002"] = 4, ["E200005"] = 8,
	},
	[139] = {
		["C305500"] = 1, ["E305500"] = 95, ["C317500"] = 1, ["E303D00"] = 14, ["E302600"] = 4, ["E30CD00"] = 22,
		["E309200"] = 128, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C303C00"] = 1, ["E310700"] = 42, ["C308F00"] = 1,
		["C313800"] = 1, ["E310701"] = 33,
	},
	[140] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 64, ["E309700"] = 4, ["E303D00"] = 58,
		["E302700"] = 51, ["E30CD00"] = 14, ["E309200"] = 64, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C303C00"] = 1,
		["E310700"] = 50, ["C308F00"] = 1, ["C313800"] = 2, ["E30A000"] = 24, ["C200000"] = 1,
	},
	[141] = {
		["E30BD00"] = 34, ["C305500"] = 1, ["E305500"] = 63, ["C317500"] = 1, ["E302700"] = 15, ["E302600"] = 6,
		["E30CD00"] = 34, ["C30CA00"] = 1, ["E310700"] = 30, ["E303A00"] = 4, ["C313800"] = 2, ["E310701"] = 26,
		["C200000"] = 1, ["E316500"] = 36,
	},
	[142] = {
		["E317B00"] = 36, ["C316D00"] = 1, ["E30BD00"] = 42, ["C305500"] = 1, ["E305500"] = 49, ["C317500"] = 1,
		["E307400"] = 32, ["E302600"] = 7, ["E30CD00"] = 34, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 20,
		["E30C800"] = 10, ["E310701"] = 4, ["C200000"] = 1,
	},
	[143] = {
		["E317B00"] = 36, ["C316D00"] = 1, ["E30BD00"] = 41, ["C305500"] = 1, ["E305500"] = 42, ["C317500"] = 1,
		["E305400"] = 2, ["E302500"] = 36, ["E302600"] = 9, ["E30CD00"] = 40, ["C30CA00"] = 1, ["C30CA01"] = 1,
		["E302401"] = 2, ["E310700"] = 26, ["C200000"] = 1,
	},
	[144] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["E30BD00"] = 58, ["C305500"] = 1, ["E305500"] = 16, ["C317500"] = 1,
		["E309700"] = 62, ["E305400"] = 2, ["E302700"] = 9, ["E302401"] = 1, ["E310700"] = 32, ["E30C800"] = 40,
		["C200000"] = 1,
	},
	[145] = {
		["E316D00"] = 32, ["E309700"] = 58, ["E305400"] = 2, ["E303D00"] = 14, ["E302700"] = 17, ["E302600"] = 4,
		["C30CA01"] = 1, ["C303C00"] = 1, ["E310700"] = 30, ["E30C800"] = 46, ["C313800"] = 2, ["C200000"] = 1,
		["E316500"] = 38,
	},
	[146] = {
		["E317B00"] = 26, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 49, ["C317500"] = 1, ["E309700"] = 34,
		["E305400"] = 2, ["E302600"] = 4, ["C30CA01"] = 1, ["E302401"] = 2, ["E310700"] = 46, ["E30C800"] = 46,
		["E310702"] = 29, ["C200000"] = 1,
	},
	[147] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 25, ["E309700"] = 58, ["E305400"] = 2,
		["E302600"] = 4, ["E30CD00"] = 64, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E302401"] = 1, ["E310700"] = 5,
		["E30C800"] = 20, ["C313800"] = 1,
	},
	[148] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E316900"] = 14, ["E30BD00"] = 56, ["C305500"] = 1, ["C317500"] = 1,
		["E309700"] = 38, ["E305400"] = 2, ["E309200"] = 24, ["E314400"] = 20, ["E310700"] = 18, ["C308F00"] = 1,
		["E30C800"] = 2, ["C200000"] = 1,
	},
	[149] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["C305500"] = 1, ["E309700"] = 34, ["E305400"] = 2, ["E302600"] = 4,
		["E309200"] = 24, ["E314400"] = 16, ["C308F00"] = 1, ["E302402"] = 16, ["E30C800"] = 4, ["C200000"] = 1,
		["E316500"] = 8,
	},
	[150] = {
		["E317B00"] = 10, ["C316D00"] = 1, ["C305500"] = 1, ["E307B01"] = 20, ["E305500"] = 11, ["E305400"] = 46,
		["E307400"] = 28, ["E302700"] = 9, ["C307801"] = 1, ["E310700"] = 20, ["E302402"] = 21, ["E30C800"] = 10,
	},
	[151] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 25, ["C317500"] = 1, ["E305400"] = 46,
		["E307400"] = 46, ["E302700"] = 5, ["E302600"] = 7, ["E310700"] = 8, ["E310701"] = 20, ["E30A000"] = 16,
	},
	[152] = {
		["C305500"] = 1, ["E307B01"] = 26, ["E305400"] = 46, ["C307800"] = 1, ["E307400"] = 50, ["E303D00"] = 12,
		["C307801"] = 1, ["E302600"] = 47, ["E309200"] = 50, ["C30CA01"] = 1, ["C303C00"] = 1, ["E310700"] = 30,
		["C308F00"] = 1, ["E310701"] = 12, ["E307B00"] = 48,
	},
	[153] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["C305500"] = 1, ["C317500"] = 1, ["E305400"] = 46, ["C307800"] = 1,
		["E307400"] = 50, ["E302700"] = 46, ["E302600"] = 11, ["E310700"] = 26, ["C309300"] = 1, ["E310701"] = 16,
		["E30A100"] = 58, ["E307B00"] = 56,
	},
	[154] = {
		["E316A00"] = 4, ["E305400"] = 46, ["E307400"] = 20, ["E302400"] = 1, ["C30CA01"] = 1, ["E310700"] = 20,
		["E30B500"] = 9, ["E302402"] = 42, ["E316F00"] = 6, ["E310701"] = 6, ["C200000"] = 1,
	},
	[155] = {
		["C305500"] = 1, ["E305500"] = 21, ["E305400"] = 48, ["C307800"] = 1, ["E302500"] = 5, ["E302400"] = 26,
		["E309200"] = 16, ["E310700"] = 8, ["C308F00"] = 1, ["E316F00"] = 12, ["E310701"] = 4, ["E307B00"] = 8,
	},
	[156] = {
		["E316A01"] = 6, ["E307B01"] = 22, ["E303D00"] = 2, ["E302700"] = 15, ["C307801"] = 1, ["E302600"] = 7,
		["E309200"] = 16, ["C30CA01"] = 1, ["C303C00"] = 1, ["E310700"] = 24, ["C308F00"] = 1, ["E30B500"] = 3,
		["E30C800"] = 12,
	},
	[157] = {
		["E316A01"] = 30, ["C305500"] = 1, ["E302500"] = 25, ["E302700"] = 13, ["E302600"] = 26, ["E30CA03"] = 12,
		["E310700"] = 21, ["E302402"] = 42, ["E30C800"] = 32, ["E310701"] = 18, ["C200000"] = 1,
	},
	[158] = {
		["C317500"] = 1, ["C310700"] = 1, ["E305400"] = 46, ["C307800"] = 1, ["E307400"] = 12, ["E302700"] = 13,
		["E302600"] = 11, ["E30CD00"] = 30, ["E309200"] = 16, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C308F00"] = 1,
		["E302402"] = 46, ["C200000"] = 1, ["E316500"] = 12, ["E307B00"] = 6,
	},
	[159] = {
		["E307B01"] = 12, ["C317500"] = 1, ["E309700"] = 30, ["C310700"] = 1, ["E302500"] = 3, ["E307000"] = 6,
		["C307801"] = 1, ["E302400"] = 28, ["E302600"] = 10, ["E309200"] = 14, ["C30CA01"] = 1, ["C308F00"] = 1,
		["E302402"] = 10, ["C30AC00"] = 1, ["C200000"] = 1, ["E316500"] = 6,
	},
	[160] = {
		["C305500"] = 1, ["E307B01"] = 10, ["E305500"] = 45, ["E309700"] = 34, ["E307000"] = 12, ["C307801"] = 1,
		["E302400"] = 28, ["E302600"] = 5, ["E309200"] = 14, ["E302401"] = 45, ["E310700"] = 64, ["C308F00"] = 1,
		["C200000"] = 1,
	},
	[161] = {
		["E317B00"] = 34, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 63, ["E309700"] = 54, ["E302500"] = 28,
		["E302700"] = 47, ["E310700"] = 40, ["E30C800"] = 24, ["C309300"] = 1, ["E30A100"] = 64, ["C200000"] = 1,
		["E316500"] = 44,
	},
	[162] = {
		["C305500"] = 1, ["E305500"] = 39, ["E309700"] = 54, ["E302500"] = 28, ["E302700"] = 42, ["E310700"] = 64,
		["E30C800"] = 29, ["C309300"] = 1, ["C313800"] = 2, ["E310701"] = 20, ["E30A100"] = 64, ["C200000"] = 1,
		["E316500"] = 54,
	},
	[163] = {
		["C305500"] = 1, ["E307B01"] = 64, ["E30BC00"] = 10, ["E305500"] = 8, ["E305400"] = 62, ["E302500"] = 53,
		["E307400"] = 50, ["C307801"] = 1, ["E30CD00"] = 26, ["E309200"] = 44, ["C30CA00"] = 1, ["E310700"] = 40,
		["C308F00"] = 1, ["E30C800"] = 24, ["C200000"] = 1,
	},
	[164] = {
		["C305500"] = 1, ["E30BC00"] = 10, ["E305400"] = 62, ["E302500"] = 83, ["E307400"] = 68, ["E302700"] = 37,
		["E302600"] = 14, ["E309200"] = 100, ["E310700"] = 17, ["C308F00"] = 1, ["C200000"] = 1,
	},
	[165] = {
		["E305400"] = 62, ["E302500"] = 54, ["E307400"] = 68, ["E302700"] = 35, ["E302600"] = 44, ["E309200"] = 78,
		["E310700"] = 10, ["C308F00"] = 1, ["C313800"] = 2,
	},
	[166] = {
		["E30BD00"] = 21, ["C305500"] = 1, ["E305500"] = 35, ["C307800"] = 1, ["E302500"] = 58, ["E302700"] = 73,
		["E309200"] = 66, ["E310700"] = 24, ["C308F00"] = 1, ["C313800"] = 2, ["C200000"] = 1, ["E307B00"] = 128,
	},
	[167] = {
		["E30BD00"] = 28, ["C305500"] = 1, ["E305500"] = 19, ["C307800"] = 1, ["E302500"] = 58, ["E302700"] = 72,
		["E309200"] = 68, ["C30CA01"] = 1, ["C308F00"] = 1, ["E310701"] = 20, ["C200000"] = 1, ["E307B00"] = 128,
	},
	[168] = {
		["C305500"] = 1, ["E302500"] = 37, ["E307400"] = 128, ["E302700"] = 67, ["E302600"] = 13, ["E309200"] = 88,
		["C30CA01"] = 1, ["E307100"] = 14, ["E310700"] = 43, ["C308F00"] = 1, ["C313800"] = 2, ["C200000"] = 1,
	},
	[169] = {
		["E30BD00"] = 14, ["E309700"] = 52, ["E305400"] = 22, ["E302500"] = 119, ["E303D00"] = 18, ["E302700"] = 39,
		["C30CA01"] = 1, ["C303C00"] = 1, ["E310701"] = 108, ["C200000"] = 1,
	},
	[170] = {
		["E317B00"] = 10, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 80, ["E309700"] = 32, ["E305400"] = 14,
		["E307400"] = 128, ["C30CA01"] = 1, ["E310700"] = 9, ["E310701"] = 106, ["C200000"] = 1,
	},
	[171] = {
		["C305500"] = 1, ["E305500"] = 27, ["E309700"] = 11, ["E305400"] = 4, ["E302500"] = 1, ["E30CD00"] = 42,
		["E309200"] = 4, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 26, ["C308F00"] = 1, ["C313800"] = 1,
		["E30A000"] = 38, ["C200000"] = 1, ["E316500"] = 36,
	},
	[172] = {
		["E30BD00"] = 46, ["C305500"] = 1, ["E307B01"] = 58, ["E305500"] = 37, ["E305400"] = 10, ["E307400"] = 58,
		["E303D00"] = 14, ["C307801"] = 1, ["E302600"] = 28, ["C30CA01"] = 1, ["C303C00"] = 1, ["E310700"] = 38,
		["E310701"] = 38, ["C200000"] = 1,
	},
	[173] = {
		["C316B00"] = 1, ["C305500"] = 1, ["E30BC00"] = 16, ["E305500"] = 27, ["E309700"] = 13, ["E305400"] = 4,
		["E302500"] = 1, ["E30CD00"] = 16, ["E309200"] = 2, ["C30CA00"] = 1, ["E310700"] = 26, ["C308F00"] = 1,
		["C313800"] = 2, ["E310701"] = 24, ["C200000"] = 1, ["E316500"] = 64,
	},
	[174] = {
		["C305500"] = 1, ["E305500"] = 41, ["E309700"] = 30, ["E305400"] = 62, ["E307400"] = 50, ["E302700"] = 17,
		["E302600"] = 16, ["E310700"] = 37, ["E30B500"] = 13, ["E30C800"] = 4, ["C313800"] = 2, ["C200000"] = 1,
	},
	[175] = {
		["E30BD00"] = 27, ["C305500"] = 1, ["E305500"] = 23, ["E309700"] = 20, ["E305400"] = 4, ["E30CD00"] = 8,
		["C30CA00"] = 1, ["E317501"] = 14, ["E310700"] = 24, ["E310701"] = 10, ["C200000"] = 1, ["E316500"] = 50,
	},
	[176] = {
		["E317B00"] = 28, ["C316D00"] = 1, ["E30BD00"] = 54, ["C305500"] = 1, ["E305500"] = 59, ["E305400"] = 4,
		["E302500"] = 49, ["E307400"] = 64, ["E302700"] = 57, ["E307100"] = 24, ["E310701"] = 40, ["C200000"] = 1,
	},
	[177] = {
		["E30BD00"] = 50, ["C305500"] = 1, ["E305500"] = 53, ["E305400"] = 60, ["E307400"] = 52, ["E302700"] = 33,
		["E302600"] = 18, ["C30CA01"] = 1, ["E310700"] = 25, ["E302402"] = 8, ["E30C800"] = 48, ["C200000"] = 1,
	},
	[178] = {
		["C316B00"] = 1, ["E30B600"] = 14, ["C310700"] = 1, ["E305400"] = 60, ["E302500"] = 63, ["E307400"] = 44,
		["E303D00"] = 12, ["E302700"] = 60, ["E302600"] = 57, ["E309200"] = 48, ["C30CA01"] = 1, ["C303C00"] = 1,
		["C308F00"] = 1, ["E310701"] = 16, ["C200000"] = 1,
	},
	[179] = {
		["E30BC00"] = 14, ["E309700"] = 12, ["E302500"] = 5, ["E302600"] = 14, ["E309200"] = 12, ["C30CA01"] = 1,
		["E310700"] = 28, ["C308F00"] = 1, ["E30C800"] = 24, ["C313800"] = 1, ["E310701"] = 20, ["E310702"] = 25,
		["C200000"] = 1,
	},
	[180] = {
		["E30BD00"] = 48, ["C305500"] = 1, ["E309700"] = 56, ["E30CD00"] = 112, ["E309200"] = 52, ["C30CA00"] = 1,
		["C30CA01"] = 1, ["E310700"] = 30, ["C308F00"] = 1, ["E30B500"] = 33, ["C313800"] = 1, ["E310701"] = 51,
		["C200000"] = 1,
	},
	[181] = {
		["E307B01"] = 20, ["E307400"] = 12, ["C307801"] = 1, ["E302600"] = 20, ["E309200"] = 28, ["C30CA01"] = 1,
		["E317501"] = 14, ["E310700"] = 10, ["C308F00"] = 1, ["E30B500"] = 9, ["E310701"] = 4, ["E310702"] = 30,
		["C200000"] = 1,
	},
	[182] = {
		["E30BD00"] = 24, ["C305500"] = 1, ["E305500"] = 31, ["C317500"] = 1, ["E309700"] = 47, ["E305400"] = 76,
		["C307800"] = 1, ["E310700"] = 30, ["E310702"] = 76, ["C200000"] = 1, ["E307B00"] = 102,
	},
	[183] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E30BD00"] = 24, ["C310700"] = 1, ["E307400"] = 12, ["E302700"] = 3,
		["E302600"] = 22, ["E309200"] = 36, ["C308F00"] = 1, ["E302402"] = 22, ["E30C800"] = 12, ["E310701"] = 10,
		["C200000"] = 1,
	},
	[184] = {
		["E30BD00"] = 14, ["C305500"] = 1, ["E305500"] = 17, ["E307000"] = 12, ["E302700"] = 3, ["E302600"] = 15,
		["E309200"] = 44, ["E310700"] = 2, ["C308F00"] = 1, ["E30C800"] = 10, ["E310701"] = 10, ["C200000"] = 1,
	},
	[185] = {
		["E30BD00"] = 16, ["C317500"] = 1, ["E307000"] = 14, ["E302700"] = 5, ["E302600"] = 16, ["E000703"] = 12,
		["E310700"] = 17, ["E302402"] = 28, ["E30C800"] = 30, ["E310701"] = 4, ["C200000"] = 1,
	},
	[186] = {
		["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 55, ["C310700"] = 1, ["E305400"] = 128, ["C307800"] = 1,
		["E30CD00"] = 32, ["C30CA00"] = 1, ["E30C800"] = 14, ["C313800"] = 2, ["E310701"] = 74, ["C200000"] = 1,
		["E316500"] = 30, ["E307B00"] = 42,
	},
	[187] = {
		["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 55, ["C310700"] = 1, ["E305400"] = 112, ["C307800"] = 1,
		["E307400"] = 16, ["E30CD00"] = 28, ["C30CA00"] = 1, ["E30C800"] = 18, ["C313800"] = 1, ["E310701"] = 28,
		["C200000"] = 1, ["E307B00"] = 42,
	},
	[188] = {
		["E30BD00"] = 22, ["C305500"] = 1, ["E305500"] = 2, ["E307400"] = 16, ["E303D00"] = 10, ["E302700"] = 3,
		["E302600"] = 14, ["E30CD00"] = 30, ["E309200"] = 14, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C303C00"] = 1,
		["E310700"] = 7, ["C308F00"] = 1, ["C200000"] = 1,
	},
	[189] = {
		["E317B00"] = 16, ["C316D00"] = 1, ["E309700"] = 11, ["C310700"] = 1, ["E302500"] = 9, ["E307400"] = 12,
		["E302700"] = 3, ["E302600"] = 64, ["E309200"] = 2, ["C30CA01"] = 1, ["C308F00"] = 1, ["E30C800"] = 8,
		["E310701"] = 1, ["C200000"] = 1,
	},
	[190] = {
		["C305500"] = 1, ["E305500"] = 9, ["E309700"] = 8, ["E317600"] = 6, ["E307400"] = 16, ["E302600"] = 10,
		["E309200"] = 6, ["C30CA01"] = 1, ["E310700"] = 34, ["C308F00"] = 1, ["E302402"] = 6, ["E310701"] = 24,
		["C200000"] = 1,
	},
	[191] = {
		["E317B00"] = 24, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 5, ["E307400"] = 16, ["E302700"] = 23,
		["E302600"] = 14, ["E30CD00"] = 4, ["E309200"] = 14, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 11,
		["C308F00"] = 1, ["C30AC00"] = 1, ["E310701"] = 8,
	},
	[192] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["E316B00"] = 18, ["C305500"] = 1, ["E305500"] = 20, ["E307400"] = 10,
		["E302600"] = 36, ["E309200"] = 14, ["C30CA01"] = 1, ["E307100"] = 6, ["E310700"] = 14, ["C308F00"] = 1,
		["E30C800"] = 22, ["C313800"] = 2,
	},
	[193] = {
		["E317B00"] = 32, ["C316D00"] = 1, ["E30BD00"] = 16, ["E308702"] = 1, ["E307400"] = 16, ["E302700"] = 27,
		["E302600"] = 8, ["E309200"] = 58, ["E310700"] = 12, ["C308F00"] = 1, ["E000701"] = 1, ["C313800"] = 2,
	},
	[194] = {
		["C305500"] = 1, ["E305500"] = 63, ["C317500"] = 1, ["E309700"] = 42, ["C307800"] = 1, ["E302500"] = 64,
		["E307400"] = 20, ["E303D00"] = 12, ["E302600"] = 58, ["C303C00"] = 1, ["E310700"] = 60, ["E316500"] = 28,
		["E307B00"] = 64,
	},
	[195] = {
		["E30BD00"] = 14, ["E307B01"] = 6, ["E305400"] = 6, ["E307400"] = 10, ["E302700"] = 29, ["C307801"] = 1,
		["E30CA03"] = 22, ["E310700"] = 22, ["E316F00"] = 2, ["E310702"] = 7, ["C200000"] = 1,
	},
	[196] = {
		["E30BD00"] = 10, ["E317600"] = 4, ["E302500"] = 9, ["E312601"] = 30, ["E302700"] = 33, ["C30CA01"] = 1,
		["E000703"] = 6, ["E310700"] = 19, ["E310701"] = 3, ["E30A000"] = 10, ["C200000"] = 1,
	},
	[197] = {
		["E30BD00"] = 10, ["C317500"] = 1, ["E308702"] = 7, ["E308700"] = 1, ["E302700"] = 7, ["E302600"] = 21,
		["C30CA01"] = 1, ["E314400"] = 18, ["E310700"] = 7, ["E30C800"] = 18, ["E310701"] = 32, ["C200000"] = 1,
	},
	[198] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["E307B01"] = 64, ["C317500"] = 1, ["E305400"] = 64, ["C307800"] = 1,
		["E302500"] = 9, ["E307400"] = 14, ["E303D00"] = 4, ["E302700"] = 10, ["C307801"] = 1, ["E30CD00"] = 38,
		["C30CA00"] = 1, ["C303C00"] = 1, ["E307B00"] = 64,
	},
	[199] = {
		["E316A01"] = 4, ["C305500"] = 1, ["E305500"] = 3, ["C317500"] = 1, ["E302600"] = 5, ["E000703"] = 2,
		["E314400"] = 60, ["E310700"] = 26, ["E30C800"] = 2, ["E310701"] = 4, ["C200000"] = 1,
	},
	[200] = {
		["C316B00"] = 1, ["E317400"] = 4, ["E30BD00"] = 16, ["C317500"] = 1, ["E305400"] = 6, ["E302700"] = 2,
		["E317700"] = 16, ["E314400"] = 10, ["E310700"] = 28, ["E310701"] = 4, ["C200000"] = 1, ["E316500"] = 54,
	},
	[201] = {
		["E30BD00"] = 20, ["C305500"] = 1, ["E305500"] = 20, ["C317500"] = 1, ["E309700"] = 49, ["E305400"] = 48,
		["E307400"] = 46, ["E302600"] = 12, ["E30CD00"] = 50, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E310701"] = 64,
		["C200000"] = 1, ["E316500"] = 60,
	},
	[202] = {
		["E30BD00"] = 57, ["C305500"] = 1, ["E305500"] = 40, ["C317500"] = 1, ["E309700"] = 111, ["E307400"] = 78,
		["E303D00"] = 50, ["E309200"] = 26, ["C303C00"] = 1, ["E310700"] = 36, ["C308F00"] = 1,
	},
	[203] = {
		["C305500"] = 1, ["E305500"] = 61, ["C317500"] = 1, ["E309700"] = 95, ["E307400"] = 94, ["E303D00"] = 58,
		["E309200"] = 18, ["C303C00"] = 1, ["C308F00"] = 1, ["E30C800"] = 42, ["C200000"] = 1, ["E316500"] = 32,
	},
	[204] = {
		["E30BD00"] = 16, ["C305500"] = 1, ["E305500"] = 75, ["E309700"] = 116, ["E307400"] = 94, ["E302700"] = 35,
		["E310700"] = 20, ["E30C800"] = 16,
	},
	[205] = {
		["C305500"] = 1, ["E307B01"] = 14, ["E305500"] = 60, ["C317500"] = 1, ["E309700"] = 123, ["C307800"] = 1,
		["E307400"] = 52, ["E302700"] = 29, ["C307801"] = 1, ["E309200"] = 32, ["C308F00"] = 1, ["C313800"] = 2,
		["C200000"] = 1, ["E307B00"] = 18,
	},
	[206] = {
		["C316B00"] = 1, ["E30BD00"] = 48, ["C305500"] = 1, ["E305500"] = 43, ["C317500"] = 1, ["E309700"] = 52,
		["E307400"] = 62, ["E317700"] = 12, ["E309200"] = 18, ["E310700"] = 19, ["C308F00"] = 1, ["E310701"] = 30,
		["E310702"] = 40, ["C200000"] = 1,
	},
	[207] = {
		["E317B00"] = 36, ["C316D00"] = 1, ["E316A01"] = 6, ["E316900"] = 6, ["C317500"] = 1, ["E302500"] = 53,
		["E307400"] = 42, ["E302700"] = 2, ["C30CA01"] = 1, ["E310700"] = 24, ["E312501"] = 24, ["E310701"] = 11,
	},
	[208] = {
		["C305500"] = 1, ["E307B01"] = 46, ["E305500"] = 9, ["C317500"] = 1, ["C307801"] = 1, ["E307300"] = 1,
		["E302600"] = 22, ["E30CD00"] = 36, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E307100"] = 4, ["E30C800"] = 4,
		["E310701"] = 6, ["E316B02"] = 8, ["C200000"] = 1,
	},
	[209] = {
		["C305500"] = 1, ["E305500"] = 27, ["C317500"] = 1, ["E307400"] = 10, ["E302700"] = 39, ["E302600"] = 5,
		["E30CD00"] = 36, ["E309200"] = 2, ["C30CA00"] = 1, ["E310700"] = 5, ["C308F00"] = 1, ["E30C800"] = 2,
		["E310701"] = 14,
	},
	[210] = {
		["C317500"] = 1, ["E309700"] = 20, ["E305400"] = 30, ["E302500"] = 1, ["E307400"] = 12, ["E302700"] = 5,
		["E302600"] = 12, ["C30CA01"] = 1, ["E310700"] = 64, ["E310701"] = 1, ["E316B02"] = 2,
	},
	[211] = {
		["C317500"] = 1, ["E307400"] = 64, ["E302700"] = 11, ["E307200"] = 8, ["E302600"] = 5, ["C30CA01"] = 1,
		["E314400"] = 26, ["E310700"] = 22, ["E312300"] = 16, ["E000000"] = 18, ["E316C00"] = 4,
	},
	[212] = {
		["E316D00"] = 10, ["C317500"] = 1, ["E307400"] = 64, ["E307200"] = 8, ["E302600"] = 6, ["E309200"] = 8,
		["C30CA01"] = 1, ["E310700"] = 24, ["C308F00"] = 1, ["E312501"] = 10, ["E30C800"] = 25, ["E310701"] = 18,
	},
	[213] = {
		["E317B00"] = 118, ["C316D00"] = 1, ["C316B00"] = 1, ["C317500"] = 1, ["E307400"] = 78, ["E317700"] = 10,
		["E309200"] = 12, ["E310700"] = 29, ["C308F00"] = 1, ["E30C800"] = 26, ["C313800"] = 1, ["E310701"] = 3,
		["C200000"] = 1,
	},
	[214] = {
		["C305500"] = 1, ["E305500"] = 113, ["E309700"] = 73, ["C307800"] = 1, ["E307400"] = 70, ["E303D00"] = 90,
		["E30CD00"] = 70, ["C30CA00"] = 1, ["C303C00"] = 1, ["C313800"] = 2, ["E310701"] = 40, ["C200000"] = 1,
		["E307B00"] = 48,
	},
	[215] = {
		["C305500"] = 1, ["E307B01"] = 30, ["E309700"] = 44, ["E308501"] = 12, ["C307800"] = 1, ["E307400"] = 64,
		["C307801"] = 1, ["E30CD00"] = 8, ["E000200"] = 6, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E302402"] = 1,
		["C313800"] = 2, ["E310701"] = 2, ["E307B00"] = 16,
	},
	[216] = {
		["E317B00"] = 24, ["C316D00"] = 1, ["C305500"] = 1, ["C317500"] = 1, ["C310700"] = 1, ["E307400"] = 128,
		["E302700"] = 17, ["E302600"] = 29, ["E000200"] = 8, ["E000000"] = 4, ["E310701"] = 32, ["C200000"] = 1,
	},
	[217] = {
		["E30BD00"] = 42, ["E307B01"] = 40, ["C317500"] = 1, ["E309700"] = 10, ["C307800"] = 1, ["E307400"] = 28,
		["E302700"] = 10, ["C307801"] = 1, ["E302600"] = 12, ["C30CA01"] = 1, ["E310700"] = 13, ["E302402"] = 4,
		["C313800"] = 2, ["C200000"] = 1, ["E307B00"] = 58,
	},
	[218] = {
		["C317500"] = 1, ["E309700"] = 58, ["C310700"] = 1, ["E307400"] = 32, ["E302600"] = 78, ["E309200"] = 2,
		["C30CA00"] = 1, ["C308F00"] = 1, ["E302402"] = 24, ["E310701"] = 128, ["C200000"] = 1, ["E316500"] = 66,
	},
	[219] = {
		["E317B00"] = 64, ["C316D00"] = 1, ["E30BD00"] = 34, ["C305500"] = 1, ["E305500"] = 39, ["C317500"] = 1,
		["E302700"] = 3, ["E302400"] = 2, ["E309200"] = 18, ["E310700"] = 22, ["C308F00"] = 1, ["E310701"] = 46,
		["C200000"] = 1, ["E316500"] = 64,
	},
	[220] = {
		["E30BD00"] = 60, ["C305500"] = 1, ["E305500"] = 41, ["E302400"] = 2, ["E309200"] = 20, ["E310700"] = 20,
		["C308F00"] = 1, ["E30C800"] = 30, ["E310701"] = 8, ["C200000"] = 1, ["E316500"] = 62, ["E316401"] = 10,
	},
	[221] = {
		["E30BD00"] = 60, ["C305500"] = 1, ["E305500"] = 41, ["C317500"] = 1, ["E302600"] = 4, ["E309200"] = 18,
		["E310700"] = 20, ["C308F00"] = 1, ["E30C800"] = 30, ["E310701"] = 4, ["E30A000"] = 24, ["C200000"] = 1,
		["E316500"] = 52,
	},
	[222] = {
		["E317B00"] = 50, ["C316D00"] = 1, ["E30BD00"] = 42, ["E309700"] = 12, ["C307800"] = 1, ["E302500"] = 28,
		["E302700"] = 11, ["E302600"] = 64, ["E310700"] = 28, ["E000401"] = 12, ["C200000"] = 1, ["E307B00"] = 50,
	},
	[223] = {
		["E317B00"] = 38, ["C316D00"] = 1, ["E30BD00"] = 64, ["C317500"] = 1, ["E302500"] = 29, ["E303D00"] = 16,
		["E302600"] = 31, ["E30CD00"] = 12, ["E309200"] = 10, ["C30CA00"] = 1, ["C303C00"] = 1, ["C308F00"] = 1,
		["C200000"] = 1, ["E316500"] = 64, ["E316400"] = 14,
	},
	[224] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["C317500"] = 1, ["E305400"] = 14, ["E302500"] = 86, ["E307400"] = 74,
		["E302700"] = 3, ["E310700"] = 32, ["C200000"] = 1, ["E316500"] = 80,
	},
	[225] = {
		["C317500"] = 1, ["E305400"] = 34, ["E302500"] = 60, ["E307400"] = 54, ["E302700"] = 19, ["E302600"] = 32,
		["E30CA03"] = 16, ["E310700"] = 9, ["E310701"] = 30, ["C200000"] = 1, ["E316500"] = 54,
	},
	[226] = {
		["E317B00"] = 38, ["C316D00"] = 1, ["E305400"] = 14, ["E302500"] = 88, ["E307400"] = 74, ["E302700"] = 23,
		["E310700"] = 7, ["C200000"] = 1, ["E316500"] = 8,
	},
	[227] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["E30BD00"] = 36, ["E309700"] = 34, ["E317600"] = 4, ["E302500"] = 59,
		["E307400"] = 56, ["E302600"] = 58, ["E30CD00"] = 12, ["C30CA00"] = 1, ["E310701"] = 21, ["C200000"] = 1,
	},
	[228] = {
		["E317B00"] = 10, ["C316D00"] = 1, ["E30BD00"] = 28, ["C305500"] = 1, ["E305500"] = 63, ["E307400"] = 8,
		["E302700"] = 32, ["E30CD00"] = 44, ["E309200"] = 50, ["C30CA00"] = 1, ["C308F00"] = 1, ["E30C800"] = 24,
		["E310701"] = 24, ["C200000"] = 1,
	},
	[229] = {
		["E317B00"] = 24, ["C316D00"] = 1, ["E30BD00"] = 28, ["C305500"] = 1, ["E305500"] = 64, ["E307400"] = 6,
		["E303D00"] = 12, ["E302600"] = 9, ["E309200"] = 50, ["C303C00"] = 1, ["C308F00"] = 1, ["E30A800"] = 48,
		["E310701"] = 48, ["C200000"] = 1,
	},
	[230] = {
		["E317B00"] = 24, ["C316D00"] = 1, ["E30BD00"] = 28, ["C305500"] = 1, ["E307B01"] = 12, ["E305500"] = 57,
		["E307400"] = 6, ["E303D00"] = 6, ["C307801"] = 1, ["E30CD00"] = 64, ["E309200"] = 56, ["C30CA00"] = 1,
		["C303C00"] = 1, ["C308F00"] = 1, ["E310701"] = 26, ["C200000"] = 1,
	},
	[231] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["C305500"] = 1, ["E307B01"] = 6, ["E305500"] = 118, ["E307400"] = 8,
		["C307801"] = 1, ["E302600"] = 19, ["E30CD00"] = 64, ["C30CA00"] = 1, ["E310701"] = 17, ["C200000"] = 1,
	},
	[232] = {
		["E317B00"] = 18, ["C316D00"] = 1, ["E309700"] = 16, ["E307400"] = 64, ["E303D00"] = 8, ["E302600"] = 58,
		["E30CD00"] = 44, ["C30CA00"] = 1, ["C303C00"] = 1, ["E310700"] = 3, ["E302402"] = 20, ["E310701"] = 11,
		["C200000"] = 1,
	},
	[233] = {
		["E309700"] = 40, ["E305400"] = 42, ["E302500"] = 21, ["E303D00"] = 4, ["E302700"] = 61, ["E302600"] = 36,
		["C303C00"] = 1, ["E310700"] = 26, ["E302402"] = 16, ["E310701"] = 46,
	},
	[234] = {
		["C305500"] = 1, ["E305500"] = 49, ["E309700"] = 32, ["E305400"] = 44, ["E303D00"] = 8, ["E302600"] = 62,
		["E309200"] = 2, ["C303C00"] = 1, ["E310700"] = 32, ["C308F00"] = 1, ["E302402"] = 38, ["E310701"] = 22,
	},
	[235] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["C317500"] = 1, ["E309700"] = 50, ["E305400"] = 42, ["E302500"] = 21,
		["E302700"] = 64, ["E302600"] = 42, ["E310700"] = 24, ["E302402"] = 50, ["E310701"] = 3,
	},
	[236] = {
		["E316D00"] = 14, ["C305500"] = 1, ["E305500"] = 45, ["E309700"] = 58, ["E305400"] = 42, ["E302500"] = 21,
		["E302600"] = 35, ["E309200"] = 10, ["E310700"] = 20, ["C308F00"] = 1, ["E302402"] = 56,
	},
	[237] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["E30BD00"] = 39, ["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 14,
		["C310700"] = 1, ["E305400"] = 42, ["E302500"] = 21, ["E303D00"] = 4, ["E302600"] = 62, ["E309200"] = 22,
		["C30CA01"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["C200000"] = 1, ["E316500"] = 46,
	},
	[238] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E30BD00"] = 26, ["C305500"] = 1, ["E305500"] = 15, ["C317500"] = 1,
		["E309700"] = 32, ["E302500"] = 63, ["E302600"] = 58, ["E309200"] = 14, ["E310700"] = 58, ["C308F00"] = 1,
		["E30C800"] = 4, ["C313800"] = 1, ["C200000"] = 1,
	},
	[239] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["E30BD00"] = 32, ["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 18,
		["E302500"] = 63, ["E307400"] = 30, ["E302600"] = 30, ["E310700"] = 22, ["E30C800"] = 11, ["C200000"] = 1,
		["E316500"] = 48,
	},
	[240] = {
		["C305500"] = 1, ["E307B01"] = 16, ["E305500"] = 6, ["C317500"] = 1, ["E309700"] = 20, ["E307400"] = 38,
		["C307801"] = 1, ["E302600"] = 61, ["E310700"] = 16, ["E30C800"] = 12, ["E30CA00"] = 14, ["C313800"] = 2,
		["E30A000"] = 6, ["C200000"] = 1,
	},
	[241] = {
		["E317000"] = 4, ["E317B00"] = 10, ["C316D00"] = 1, ["C305500"] = 1, ["E305500"] = 9, ["C317500"] = 1,
		["E302700"] = 2, ["E302600"] = 10, ["C30CA01"] = 1, ["E310700"] = 3, ["E30C800"] = 2, ["E310701"] = 3,
		["E30A000"] = 2, ["C200000"] = 1,
	},
	[242] = {
		["C305500"] = 1, ["E307B01"] = 24, ["C317500"] = 1, ["E309700"] = 56, ["E307400"] = 24, ["E302700"] = 43,
		["C307801"] = 1, ["E302600"] = 27, ["E30CD00"] = 42, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E307100"] = 6,
		["E310700"] = 12, ["E30C800"] = 9,
	},
	[243] = {
		["E316B01"] = 2, ["C305500"] = 1, ["E307B01"] = 52, ["E305500"] = 69, ["C317500"] = 1, ["E309700"] = 92,
		["C310700"] = 1, ["E307400"] = 30, ["C307801"] = 1, ["E30CD00"] = 4, ["C30CA00"] = 1, ["E30A000"] = 8,
		["C200000"] = 1,
	},
	[244] = {
		["E30BC00"] = 10, ["C310700"] = 1, ["E307400"] = 8, ["E302600"] = 4, ["E30C800"] = 2, ["C313800"] = 2,
		["C30AC00"] = 1, ["E310701"] = 4, ["C200000"] = 1,
	},
	[245] = {
		["C305500"] = 1, ["E305500"] = 31, ["C317500"] = 1, ["E309700"] = 40, ["E307400"] = 60, ["E302700"] = 19,
		["E302600"] = 60, ["E30CD00"] = 12, ["C30CA00"] = 1, ["E310700"] = 26, ["E316C00"] = 4, ["E30A000"] = 4,
		["C200000"] = 1,
	},
	[246] = {
		["E316D00"] = 6, ["E316B01"] = 16, ["E30BD00"] = 54, ["E307B01"] = 58, ["C317500"] = 1, ["E307400"] = 60,
		["C307801"] = 1, ["E302600"] = 56, ["E310700"] = 23, ["E30C800"] = 20, ["E310701"] = 34, ["C200000"] = 1,
	},
	[247] = {
		["E30BD00"] = 61, ["C305500"] = 1, ["E307B01"] = 58, ["C317500"] = 1, ["E309700"] = 16, ["C307800"] = 1,
		["E302700"] = 63, ["C307801"] = 1, ["E302600"] = 58, ["E309200"] = 12, ["E310700"] = 25, ["C308F00"] = 1,
		["E30C800"] = 18, ["C313800"] = 2, ["C200000"] = 1, ["E307B00"] = 24,
	},
	[248] = {
		["E317B00"] = 32, ["C316D00"] = 1, ["E30BD00"] = 14, ["C305500"] = 1, ["E307B01"] = 58, ["C317500"] = 1,
		["C307800"] = 1, ["E303D00"] = 44, ["E302700"] = 23, ["C307801"] = 1, ["E302600"] = 57, ["E309200"] = 12,
		["C303C00"] = 1, ["E310700"] = 24, ["C308F00"] = 1, ["C200000"] = 1, ["E307B00"] = 24,
	},
	[249] = {
		["E317B00"] = 32, ["C316D00"] = 1, ["E30BD00"] = 26, ["E307B01"] = 28, ["C317500"] = 1, ["E309700"] = 30,
		["C310700"] = 1, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 57, ["E30CD00"] = 14, ["C30CA00"] = 1,
		["E302402"] = 26, ["C200000"] = 1, ["E316500"] = 34, ["E307B00"] = 54,
	},
	[250] = {
		["E317B00"] = 34, ["C316D00"] = 1, ["C305500"] = 1, ["C317500"] = 1, ["E309700"] = 29, ["E305400"] = 60,
		["E302500"] = 37, ["E302700"] = 51, ["E302600"] = 52, ["E309200"] = 12, ["E310700"] = 24, ["C308F00"] = 1,
		["E30C800"] = 12,
	},
	[251] = {
		["C305500"] = 1, ["E305500"] = 5, ["C317500"] = 1, ["E309700"] = 10, ["E308702"] = 1, ["E308700"] = 1,
		["C307800"] = 1, ["E302600"] = 24, ["E310700"] = 18, ["E30B500"] = 1, ["E310701"] = 2, ["E307B00"] = 26,
	},
	[252] = {
		["E30BD00"] = 5, ["E307B01"] = 92, ["C317500"] = 1, ["E309700"] = 14, ["E308502"] = 13, ["C307800"] = 1,
		["C307801"] = 1, ["E30CD00"] = 28, ["C30CA00"] = 1, ["C200000"] = 1, ["E316500"] = 18, ["E307B00"] = 50,
	},
	[253] = {
		["E316B00"] = 16, ["C305500"] = 1, ["E305500"] = 7, ["C317500"] = 1, ["E302700"] = 3, ["E302600"] = 16,
		["E30CD00"] = 32, ["E309200"] = 52, ["C30CA00"] = 1, ["E310700"] = 14, ["C308F00"] = 1, ["E302402"] = 38,
		["E30C800"] = 42, ["C200000"] = 1,
	},
	[254] = {
		["C305500"] = 1, ["E305500"] = 5, ["C317500"] = 1, ["C307800"] = 1, ["E302600"] = 14, ["E30CD00"] = 74,
		["E309200"] = 2, ["C30CA00"] = 1, ["C308F00"] = 1, ["E302402"] = 54, ["C200000"] = 1, ["E316500"] = 16,
		["E307B00"] = 50,
	},
	[255] = {
		["C305500"] = 1, ["E305500"] = 3, ["C317500"] = 1, ["E302700"] = 43, ["E302600"] = 16, ["E30CD00"] = 74,
		["E309200"] = 12, ["C30CA00"] = 1, ["E310700"] = 24, ["C308F00"] = 1, ["E302402"] = 32, ["C200000"] = 1,
	},
}

_M.routes["no64-rosa"] = {
	[0] = {
		["E317B00"] = 2, ["E30CD00"] = 6, ["C30CA00"] = 1, ["E302402"] = 32, ["E302600"] = 10, ["E302500"] = 1,
		["C316D00"] = 1, ["C308F00"] = 1, ["E307000"] = 4, ["E30BD00"] = 8, ["E000701"] = 1, ["E310700"] = 24,
		["E302700"] = 3, ["E309200"] = 52, ["C305500"] = 1, ["E305500"] = 3,
	},
	[1] = {
		["E30CD00"] = 6, ["C30CA00"] = 1, ["E302402"] = 14, ["E312501"] = 4, ["E310701"] = 4, ["E302600"] = 10,
		["E302500"] = 1, ["C308F00"] = 1, ["E000701"] = 1, ["E310700"] = 34, ["E000202"] = 4, ["E302700"] = 11,
		["E309200"] = 44, ["E000703"] = 4, ["C305500"] = 1, ["E305500"] = 3,
	},
	[2] = {
		["C30CA01"] = 1, ["E30CD00"] = 6, ["C30CA00"] = 1, ["E302402"] = 14, ["E312801"] = 18, ["E310701"] = 4,
		["E302600"] = 10, ["E302500"] = 5, ["C308F00"] = 1, ["E000701"] = 1, ["E310700"] = 20, ["E309700"] = 14,
		["E302700"] = 29, ["E309200"] = 12, ["E309A00"] = 4, ["C305500"] = 1, ["E305500"] = 3,
	},
	[3] = {
		["C30CA01"] = 1, ["E30CD00"] = 6, ["C30CA00"] = 1, ["E302402"] = 6, ["E308702"] = 1, ["E310701"] = 8,
		["E302600"] = 24, ["E302500"] = 5, ["E000701"] = 1, ["E310700"] = 10, ["E302700"] = 29, ["C305500"] = 1,
		["E305500"] = 55,
	},
	[4] = {
		["C316B00"] = 1, ["E317600"] = 6, ["E317B00"] = 12, ["E317700"] = 6, ["E30CD00"] = 32, ["C30CA00"] = 1,
		["E30C800"] = 10, ["E302402"] = 72, ["E310701"] = 10, ["E302600"] = 10, ["E302500"] = 23, ["C316D00"] = 1,
		["C310700"] = 1, ["C308F00"] = 1, ["E30BD00"] = 86, ["C307800"] = 1, ["E307B00"] = 82, ["E309700"] = 28,
		["E309200"] = 74,
	},
	[5] = {
		["C316B00"] = 1, ["E317B00"] = 126, ["E317700"] = 54, ["E30CD00"] = 42, ["C30CA00"] = 1, ["E30C800"] = 4,
		["E310701"] = 34, ["E302600"] = 5, ["E302500"] = 23, ["C316D00"] = 1, ["C303C00"] = 1, ["E30BD00"] = 4,
		["E310700"] = 9, ["E303D00"] = 2, ["E302700"] = 15, ["C305500"] = 1, ["E305500"] = 57, ["E316D01"] = 10,
	},
	[6] = {
		["E30B500"] = 1, ["E30A800"] = 8, ["C30CA01"] = 1, ["E30C800"] = 16, ["E310701"] = 60, ["E302600"] = 9,
		["E302500"] = 21, ["E307600"] = 2, ["E30BD00"] = 20, ["C307800"] = 1, ["E310700"] = 10, ["E307B00"] = 8,
		["E302700"] = 13, ["C305500"] = 1, ["E305500"] = 57,
	},
	[7] = {
		["E30CD00"] = 4, ["C30CA00"] = 1, ["E30C800"] = 2, ["E310701"] = 8, ["E302600"] = 42, ["E302500"] = 63,
		["C307801"] = 1, ["C308F00"] = 1, ["E30BD00"] = 6, ["C307800"] = 1, ["E307B01"] = 26, ["E310700"] = 14,
		["E307B00"] = 20, ["E302700"] = 3, ["E309200"] = 8, ["C305500"] = 1, ["E305500"] = 3, ["E316D00"] = 4,
	},
	[8] = {
		["E317000"] = 4, ["E30CD00"] = 4, ["C30CA00"] = 1, ["E30C800"] = 2, ["E310701"] = 8, ["E302600"] = 104,
		["E302500"] = 57, ["C308F00"] = 1, ["E307000"] = 2, ["E30BD00"] = 6, ["E310700"] = 6, ["E302700"] = 3,
		["E309200"] = 6, ["E000703"] = 8, ["C305500"] = 1, ["E305500"] = 3,
	},
	[9] = {
		["E30B500"] = 5, ["C30CA01"] = 1, ["E30CD00"] = 16, ["C30CA00"] = 1, ["E30C800"] = 8, ["E302402"] = 44,
		["E310701"] = 9, ["E302500"] = 48, ["C310700"] = 1, ["C308F00"] = 1, ["E30BD00"] = 52, ["E305400"] = 8,
		["E309200"] = 2, ["E000703"] = 12, ["C305500"] = 1, ["E305500"] = 7,
	},
	[10] = {
		["E30B500"] = 3, ["E30CD00"] = 60, ["C30CA00"] = 1, ["E30C800"] = 6, ["E310701"] = 4, ["E302500"] = 17,
		["C303C00"] = 1, ["C308F00"] = 1, ["E30BD00"] = 2, ["C307800"] = 1, ["E305400"] = 8, ["E310700"] = 11,
		["E307B00"] = 26, ["E303D00"] = 28, ["E309200"] = 12, ["E000703"] = 2, ["C305500"] = 1, ["E305500"] = 11,
	},
	[11] = {
		["E30B500"] = 1, ["E317B00"] = 2, ["E30CD00"] = 50, ["C30CA00"] = 1, ["E30C800"] = 2, ["E310701"] = 4,
		["E302600"] = 22, ["E302500"] = 51, ["C316D00"] = 1, ["C308F00"] = 1, ["E30BD00"] = 18, ["E305400"] = 8,
		["E310700"] = 4, ["E302700"] = 3, ["E309200"] = 26, ["C305500"] = 1, ["E305500"] = 3,
	},
	[12] = {
		["C30CA01"] = 1, ["E30CD00"] = 8, ["C30CA00"] = 1, ["E30C800"] = 2, ["E308702"] = 1, ["E302600"] = 22,
		["E302500"] = 44, ["E303A00"] = 10, ["C308F00"] = 1, ["E30BD00"] = 16, ["E305400"] = 10, ["E310700"] = 8,
		["E302700"] = 3, ["E309200"] = 20, ["E000703"] = 2, ["C305500"] = 1, ["E305500"] = 11,
	},
	[13] = {
		["E316900"] = 4, ["C30CA01"] = 1, ["E30C800"] = 22, ["E312501"] = 8, ["E308702"] = 1, ["E310701"] = 4,
		["E302600"] = 5, ["E302500"] = 7, ["E305400"] = 10, ["E000701"] = 3, ["E310700"] = 20, ["E302700"] = 5,
		["E000703"] = 2,
	},
	[14] = {
		["E308702"] = 1, ["E310701"] = 1, ["E308700"] = 1, ["E302600"] = 14, ["E302500"] = 5, ["C310700"] = 1,
		["E305400"] = 54, ["E309700"] = 14,
	},
	[15] = {
		["E309700"] = 34, ["C310700"] = 1, ["E305400"] = 54, ["E302500"] = 1, ["E309200"] = 12, ["C308F00"] = 1,
		["E000701"] = 1, ["E30C800"] = 1, ["E310701"] = 2, ["E30BD00"] = 14,
	},
	[16] = {
		["E317B00"] = 78, ["E316A01"] = 4, ["E302402"] = 86, ["E310701"] = 14, ["E302600"] = 13, ["E302500"] = 72,
		["C316D00"] = 1, ["C310700"] = 1, ["C307801"] = 1, ["C308F00"] = 1, ["E307B01"] = 74, ["E305400"] = 18,
		["E310700"] = 1, ["E309700"] = 34, ["E302700"] = 63, ["E309200"] = 34, ["E000703"] = 2,
	},
	[17] = {
		["E30CD00"] = 2, ["C30CA00"] = 1, ["E310701"] = 4, ["E302500"] = 71, ["C310700"] = 1, ["C308F00"] = 1,
		["E307400"] = 8, ["E30BD00"] = 24, ["E305400"] = 10, ["E310700"] = 2, ["E309200"] = 14, ["E000703"] = 2,
		["C305500"] = 1, ["E305500"] = 11,
	},
	[18] = {
		["E30B500"] = 1, ["E30A901"] = 10, ["E30A800"] = 4, ["C30CA01"] = 1, ["E30C800"] = 20, ["E312601"] = 4,
		["E310701"] = 34, ["E302600"] = 3, ["C308F00"] = 1, ["E30BD00"] = 28, ["E305400"] = 18, ["E310700"] = 24,
		["E302700"] = 3, ["E309200"] = 4, ["E000703"] = 2,
	},
	[19] = {
		["C316B00"] = 1, ["E317B00"] = 12, ["E317700"] = 2, ["E30CD00"] = 62, ["C30CA00"] = 1, ["E30C800"] = 2,
		["E302402"] = 8, ["E310701"] = 4, ["E302600"] = 3, ["C316D00"] = 1, ["C308F00"] = 1, ["E30BD00"] = 60,
		["E305400"] = 18, ["E310700"] = 18, ["E302700"] = 3, ["E309200"] = 4,
	},
	[20] = {
		["E316B02"] = 14, ["E317B00"] = 16, ["E30CD00"] = 80, ["C30CA00"] = 1, ["E30C800"] = 2, ["E302402"] = 8,
		["E310701"] = 10, ["E302600"] = 3, ["C316D00"] = 1, ["C308F00"] = 1, ["E30BD00"] = 46, ["E305400"] = 18,
		["E310700"] = 1, ["E302700"] = 3, ["E309200"] = 2,
	},
	[21] = {
		["E30B500"] = 1, ["E30CD00"] = 70, ["C30CA00"] = 1, ["E30C800"] = 2, ["E308702"] = 1, ["E310701"] = 8,
		["E302600"] = 1, ["C308F00"] = 1, ["E30BD00"] = 48, ["E305400"] = 18, ["E000701"] = 1, ["E310700"] = 19,
		["E302700"] = 3, ["E309200"] = 2, ["E316D00"] = 4,
	},
	[22] = {
		["E317600"] = 18, ["E316402"] = 12, ["E30AC01"] = 2, ["C30CA01"] = 1, ["E30C800"] = 38, ["E310701"] = 1,
		["E302600"] = 9, ["E000200"] = 2, ["E310700"] = 15, ["E302700"] = 3, ["E000703"] = 2, ["C305500"] = 1,
		["E305500"] = 3,
	},
	[23] = {
		["E305500"] = 27, ["E302500"] = 89, ["E307400"] = 2, ["E302700"] = 11, ["E302600"] = 19, ["E30CD00"] = 34,
		["E309200"] = 90, ["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 62, ["C308F00"] = 1, ["E30C800"] = 84,
		["E316C00"] = 14, ["E310701"] = 41,
	},
	[24] = {
		["C316B00"] = 1, ["E317700"] = 6, ["E30AA00"] = 12, ["C30CA01"] = 1, ["E30CD00"] = 4, ["C30CA00"] = 1,
		["E30C800"] = 7, ["E310701"] = 9, ["E302600"] = 10, ["C303C00"] = 1, ["C310700"] = 1, ["C307801"] = 1,
		["C307800"] = 1, ["E307B01"] = 26, ["E305400"] = 44, ["E307B00"] = 12, ["E303D00"] = 6, ["E302700"] = 5,
		["E316800"] = 5, ["E316D00"] = 6,
	},
	[25] = {
		["E316B02"] = 10, ["E100004"] = 42, ["C30CA01"] = 1, ["E30C800"] = 42, ["E310701"] = 4, ["E302500"] = 10,
		["E307400"] = 128, ["E000200"] = 34, ["E30BD00"] = 2, ["E305400"] = 114, ["E310700"] = 4, ["E309700"] = 3,
		["E302700"] = 2, ["C305500"] = 1, ["E305500"] = 9,
	},
	[26] = {
		["C316B00"] = 1, ["E317700"] = 2, ["E317000"] = 8, ["E30C800"] = 14, ["E310701"] = 128, ["E302500"] = 27,
		["E307400"] = 128, ["E000200"] = 16, ["E305400"] = 114, ["E309700"] = 4, ["E302700"] = 2, ["E000703"] = 2,
		["C305500"] = 1, ["E305500"] = 9, ["E316700"] = 18,
	},
	[27] = {
		["E30B500"] = 1, ["E30CD00"] = 14, ["C30CA00"] = 1, ["E30C800"] = 2, ["E310701"] = 8, ["C303C00"] = 1,
		["C310700"] = 1, ["C307801"] = 1, ["E307400"] = 8, ["C307800"] = 1, ["E307B01"] = 26, ["E307B00"] = 48,
		["E309700"] = 6, ["E303D00"] = 10, ["E302700"] = 5,
	},
	[28] = {
		["E30A901"] = 6, ["E30CD00"] = 10, ["C30CA00"] = 1, ["E30C800"] = 2, ["E310701"] = 14, ["E302500"] = 7,
		["C303C00"] = 1, ["C310700"] = 1, ["C307801"] = 1, ["E307B01"] = 30, ["E305400"] = 50, ["E309700"] = 6,
		["E303D00"] = 10, ["E316401"] = 8, ["E302700"] = 5,
	},
	[29] = {
		["E316B01"] = 16, ["E30B500"] = 5, ["E311D00"] = 10, ["E310701"] = 4, ["E302600"] = 44, ["C310700"] = 1,
		["C307801"] = 1, ["C308F00"] = 1, ["E307400"] = 110, ["E307B01"] = 14, ["E305400"] = 102, ["E302700"] = 67,
		["E309200"] = 2, ["E000703"] = 4, ["C305500"] = 1, ["E305500"] = 21, ["E316D00"] = 2,
	},
	[30] = {
		["C316B00"] = 1, ["E30B500"] = 1, ["E317700"] = 6, ["E30C800"] = 48, ["E310701"] = 4, ["E302600"] = 114,
		["E302500"] = 88, ["C310700"] = 1, ["C308F00"] = 1, ["E30BD00"] = 60, ["E305400"] = 8, ["E000701"] = 1,
		["E309700"] = 8, ["E302700"] = 3, ["E309200"] = 62,
	},
	[31] = {
		["E30C800"] = 1, ["E310701"] = 6, ["E302600"] = 10, ["E302500"] = 51, ["E308400"] = 8, ["E307E00"] = 20,
		["C307801"] = 1, ["C308F00"] = 1, ["E307B01"] = 38, ["E305400"] = 8, ["E000701"] = 7, ["E310700"] = 82,
		["E302700"] = 9, ["E309200"] = 128,
	},
	[32] = {
		["E305500"] = 85, ["C310700"] = 1, ["E305400"] = 6, ["E302500"] = 117, ["E303D00"] = 10, ["E302700"] = 12,
		["E302600"] = 54, ["E309200"] = 68, ["C305500"] = 1, ["C303C00"] = 1, ["E000703"] = 4, ["C308F00"] = 1,
		["E316C00"] = 6, ["E310701"] = 16,
	},
	[33] = {
		["E317B00"] = 70, ["C316D00"] = 1, ["C310700"] = 1, ["E305400"] = 30, ["E302500"] = 45, ["E307400"] = 34,
		["E302600"] = 40, ["E30CD00"] = 2, ["C30CA00"] = 1, ["C305500"] = 1, ["E310701"] = 4, ["E30B500"] = 11,
	},
	[34] = {
		["E309700"] = 22, ["E305400"] = 44, ["E302500"] = 31, ["E302700"] = 62, ["C307801"] = 1, ["E302600"] = 80,
		["E310701"] = 74, ["E30BD00"] = 2, ["E307B01"] = 36,
	},
	[35] = {
		["E309700"] = 64, ["E305400"] = 44, ["E302500"] = 30, ["C307801"] = 1, ["E302600"] = 74, ["C303C00"] = 1,
		["E30C800"] = 8, ["E310701"] = 72, ["E30BD00"] = 2, ["E307B01"] = 44,
	},
	[36] = {
		["E305400"] = 72, ["E303D00"] = 10, ["C307801"] = 1, ["E302600"] = 20, ["C305500"] = 1, ["C303C00"] = 1,
		["E310700"] = 19, ["E302402"] = 4, ["E30C800"] = 94, ["E30BD00"] = 99, ["E307B01"] = 46,
	},
	[37] = {
		["E309700"] = 6, ["E305400"] = 6, ["C307800"] = 1, ["E307400"] = 14, ["E302600"] = 4, ["C30CA01"] = 1,
		["E302402"] = 44, ["E310701"] = 2, ["E307B00"] = 14, ["E30B500"] = 1,
	},
	[38] = {
		["E305500"] = 13, ["E305400"] = 96, ["E302500"] = 9, ["C307801"] = 1, ["E302600"] = 31, ["E309200"] = 108,
		["C305500"] = 1, ["E30BC00"] = 10, ["E310700"] = 47, ["C308F00"] = 1, ["E310701"] = 42, ["E307B01"] = 24,
	},
	[39] = {
		["E309700"] = 6, ["C310700"] = 1, ["C307800"] = 1, ["E307400"] = 20, ["E307200"] = 2, ["E312801"] = 2,
		["E302600"] = 4, ["C30CA01"] = 1, ["E302402"] = 45, ["E310701"] = 2, ["E307B00"] = 12,
	},
	[40] = {
		["E305500"] = 5, ["E309700"] = 4, ["E302500"] = 4, ["E307000"] = 26, ["E309200"] = 4, ["C30CA01"] = 1,
		["C305500"] = 1, ["E310700"] = 3, ["C308F00"] = 1, ["E30C800"] = 12, ["E310701"] = 36,
	},
	[41] = {
		["E305500"] = 11, ["E309700"] = 3, ["E302500"] = 30, ["E317500"] = 6, ["E30CD00"] = 128, ["C30CA00"] = 1,
		["C305500"] = 1, ["E310700"] = 4, ["E30C800"] = 28, ["E310701"] = 8,
	},
	[42] = {
		["E305500"] = 11, ["E309700"] = 3, ["E302500"] = 10, ["E307400"] = 20, ["C30CA01"] = 1, ["C305500"] = 1,
		["E310700"] = 4, ["E30C800"] = 12, ["E310701"] = 92, ["E30BD00"] = 68,
	},
	[43] = {
		["E305500"] = 9, ["E309700"] = 4, ["E302500"] = 27, ["E307400"] = 2, ["E302700"] = 3, ["C305500"] = 1,
		["E316302"] = 14, ["E30C800"] = 28, ["E310701"] = 18,
	},
	[44] = {
		["E316A01"] = 26, ["E305500"] = 17, ["E302600"] = 12, ["E309200"] = 6, ["E000202"] = 10, ["C305500"] = 1,
		["E310700"] = 10, ["C308F00"] = 1, ["E30C800"] = 18, ["E000000"] = 2,
	},
	[45] = {
		["E302500"] = 3, ["E307400"] = 2, ["E302600"] = 16, ["E309200"] = 22, ["C305500"] = 1, ["E310700"] = 10,
		["C308F00"] = 1, ["E30C800"] = 20, ["E310701"] = 4, ["E30BD00"] = 22,
	},
	[46] = {
		["E316900"] = 2, ["E305500"] = 25, ["E302500"] = 28, ["E307400"] = 2, ["E302700"] = 3, ["E302600"] = 52,
		["E309200"] = 2, ["C30CA01"] = 1, ["C305500"] = 1, ["C308F00"] = 1, ["E310701"] = 2,
	},
	[47] = {
		["E305500"] = 20, ["C307800"] = 1, ["E302500"] = 77, ["E302700"] = 10, ["C307801"] = 1, ["E302600"] = 26,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 13, ["E30BD00"] = 16, ["E307B00"] = 38, ["E307B01"] = 22,
	},
	[48] = {
		["C310700"] = 1, ["E317600"] = 10, ["E307400"] = 4, ["E302600"] = 10, ["E309200"] = 14, ["C308F00"] = 1,
		["E30C800"] = 48, ["E310701"] = 4, ["E310702"] = 14, ["E30BD00"] = 8,
	},
	[49] = {
		["E316D00"] = 2, ["E308400"] = 6, ["E305500"] = 29, ["C310700"] = 1, ["E302500"] = 36, ["E307400"] = 2,
		["E302700"] = 5, ["E302600"] = 36, ["C305500"] = 1, ["E30C800"] = 2,
	},
	[50] = {
		["E316D00"] = 2, ["E305500"] = 37, ["C310700"] = 1, ["E305400"] = 40, ["C307800"] = 1, ["C307801"] = 1,
		["E302600"] = 10, ["C305500"] = 1, ["E000703"] = 2, ["E310701"] = 3, ["E307B00"] = 8, ["E307B01"] = 6,
	},
	[51] = {
		["E305500"] = 2, ["E309700"] = 73, ["E305400"] = 76, ["E302600"] = 12, ["E30CD00"] = 52, ["E309200"] = 22,
		["C30CA00"] = 1, ["C305500"] = 1, ["E307F00"] = 18, ["C308F00"] = 1, ["E30BD00"] = 37,
	},
	[52] = {
		["E305500"] = 37, ["E309700"] = 24, ["E302500"] = 37, ["E302700"] = 3, ["E302600"] = 12, ["C30CA01"] = 1,
		["C305500"] = 1, ["E30AC01"] = 10, ["E310700"] = 36, ["E302402"] = 16,
	},
	[53] = {
		["E305500"] = 53, ["E303D00"] = 48, ["E307300"] = 6, ["E302600"] = 80, ["E307701"] = 26, ["C305500"] = 1,
		["C303C00"] = 1, ["E310700"] = 114, ["E30C800"] = 20, ["E310701"] = 7,
	},
	[54] = {
		["E316A00"] = 30, ["E302500"] = 15, ["E302600"] = 4, ["E30CD00"] = 46, ["C30CA00"] = 1, ["E30BC00"] = 8,
		["E310700"] = 3, ["E30C800"] = 6, ["E310701"] = 12,
	},
	[55] = {
		["E305500"] = 11, ["E302500"] = 36, ["E303D00"] = 8, ["E302700"] = 2, ["E302600"] = 12, ["C305500"] = 1,
		["C303C00"] = 1, ["E000703"] = 2, ["E30BC00"] = 6, ["E310700"] = 26, ["E310701"] = 14,
	},
	[56] = {
		["E316A00"] = 4, ["E302500"] = 18, ["E307400"] = 4, ["E302700"] = 12, ["C307801"] = 1, ["E302600"] = 10,
		["C305500"] = 1, ["E310700"] = 40, ["E310701"] = 10, ["E307B01"] = 76,
	},
	[57] = {
		["E305500"] = 3, ["C310700"] = 1, ["E302500"] = 57, ["E307000"] = 4, ["E302600"] = 10, ["C305500"] = 1,
		["E310700"] = 1, ["E30C800"] = 2, ["E310701"] = 6, ["E30BD00"] = 60,
	},
	[58] = {
		["E316900"] = 20, ["E302500"] = 29, ["E000703"] = 9, ["E30CA03"] = 6, ["E310700"] = 19, ["E312501"] = 16,
		["E30C800"] = 2, ["E310701"] = 41,
	},
	[59] = {
		["E302700"] = 3, ["E302600"] = 9, ["E30CD00"] = 34, ["C30CA00"] = 1, ["E310700"] = 26, ["E302402"] = 22,
		["E310701"] = 12, ["E30BD00"] = 14, ["E000200"] = 8,
	},
	[60] = {
		["E309700"] = 2, ["E305400"] = 44, ["E308F00"] = 18, ["E302700"] = 7, ["E302600"] = 69, ["C30CA01"] = 1,
		["C305500"] = 1, ["E310700"] = 10, ["E302402"] = 12, ["E310701"] = 17,
	},
	[61] = {
		["E305400"] = 72, ["E302500"] = 29, ["E303D00"] = 24, ["E302600"] = 38, ["E30CD00"] = 56, ["E309200"] = 38,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E302402"] = 20, ["E30BD00"] = 14,
	},
	[62] = {
		["E302500"] = 97, ["E307000"] = 4, ["E302700"] = 107, ["E317500"] = 4, ["E302600"] = 14, ["E30CD00"] = 78,
		["C30CA00"] = 1, ["E310700"] = 19, ["E310701"] = 8,
	},
	[63] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E309700"] = 15, ["E305400"] = 72, ["E302500"] = 58, ["E303D00"] = 30,
		["E30CD00"] = 92, ["E309200"] = 26, ["C30CA00"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E302402"] = 21,
	},
	[64] = {
		["E305400"] = 72, ["E302500"] = 58, ["E303D00"] = 14, ["E302700"] = 47, ["E302600"] = 9, ["E30CD00"] = 80,
		["C30CA00"] = 1, ["C303C00"] = 1, ["E302402"] = 30, ["E310701"] = 4,
	},
	[65] = {
		["E305500"] = 43, ["E305400"] = 72, ["E302500"] = 58, ["E302600"] = 9, ["E30CD00"] = 48, ["C30CA00"] = 1,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 20, ["E302402"] = 40, ["E30BD00"] = 11,
	},
	[66] = {
		["E305500"] = 53, ["E305400"] = 72, ["E302500"] = 35, ["E302600"] = 9, ["E30CD00"] = 78, ["C30CA00"] = 1,
		["C305500"] = 1, ["E310700"] = 34, ["E302402"] = 40, ["E310701"] = 3,
	},
	[67] = {
		["E305500"] = 3, ["C310700"] = 1, ["E308702"] = 3, ["E307400"] = 72, ["E302700"] = 23, ["E302600"] = 14,
		["E307701"] = 18, ["C30CA01"] = 1, ["C305500"] = 1, ["E000701"] = 7, ["E310701"] = 3,
	},
	[68] = {
		["E316D00"] = 4, ["E305400"] = 16, ["E302500"] = 50, ["E307400"] = 26, ["E302700"] = 19, ["E302600"] = 14,
		["E310700"] = 15, ["E30C800"] = 2,
	},
	[69] = {
		["E305400"] = 16, ["C307800"] = 1, ["E307400"] = 26, ["E302700"] = 11, ["E302600"] = 22, ["E310700"] = 22,
		["E30C800"] = 2, ["E310701"] = 1, ["E307B00"] = 36,
	},
	[70] = {
		["E305500"] = 19, ["E305400"] = 90, ["E302700"] = 27, ["E302600"] = 14, ["C305500"] = 1, ["E310700"] = 17,
		["E312501"] = 22, ["E312700"] = 16, ["E310701"] = 8,
	},
	[71] = {
		["E305500"] = 33, ["E309700"] = 10, ["E302500"] = 3, ["E302700"] = 31, ["E302600"] = 44, ["C305500"] = 1,
		["E000703"] = 4, ["E310700"] = 20, ["E310701"] = 6,
	},
	[72] = {
		["E317B00"] = 54, ["C316D00"] = 1, ["E305500"] = 34, ["E305400"] = 90, ["E30CD00"] = 42, ["C30CA00"] = 1,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 34, ["E302402"] = 120, ["E310701"] = 26, ["E30BD00"] = 82,
	},
	[73] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["E305400"] = 78, ["E307400"] = 18, ["E302700"] = 17, ["E30CD00"] = 110,
		["E309200"] = 6, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 90, ["C308F00"] = 1,
		["E310701"] = 26,
	},
	[74] = {
		["E305400"] = 90, ["C307800"] = 1, ["E302500"] = 1, ["E302400"] = 15, ["E309200"] = 6, ["C30CA01"] = 1,
		["C305500"] = 1, ["E310700"] = 68, ["C308F00"] = 1, ["E302402"] = 22, ["E310701"] = 16, ["E307B00"] = 2,
	},
	[75] = {
		["E308702"] = 3, ["E305400"] = 74, ["E307400"] = 72, ["E302700"] = 19, ["E302600"] = 21, ["C30CA01"] = 1,
		["E310700"] = 9, ["E302402"] = 21, ["E310701"] = 6,
	},
	[76] = {
		["E305500"] = 27, ["E305400"] = 62, ["E302500"] = 19, ["E307400"] = 84, ["E302700"] = 7, ["C307801"] = 1,
		["E302600"] = 16, ["E309200"] = 28, ["C305500"] = 1, ["C308F00"] = 1, ["E307B01"] = 14,
	},
	[77] = {
		["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 56, ["E307400"] = 108, ["E302600"] = 10, ["E30CD00"] = 28,
		["E309200"] = 34, ["C30CA00"] = 1, ["C308F00"] = 1, ["E302402"] = 31, ["E30BD00"] = 22, ["E307B00"] = 20,
	},
	[78] = {
		["E317B00"] = 36, ["C316D00"] = 1, ["E305500"] = 29, ["C307800"] = 1, ["E302500"] = 17, ["E302700"] = 15,
		["E30CD00"] = 70, ["E309200"] = 120, ["C30CA00"] = 1, ["C305500"] = 1, ["C308F00"] = 1, ["E310701"] = 22,
		["E307B00"] = 76,
	},
	[79] = {
		["E316A01"] = 6, ["E305500"] = 29, ["E309700"] = 72, ["E302500"] = 2, ["E302700"] = 35, ["E302600"] = 5,
		["E309200"] = 120, ["C30CA01"] = 1, ["C305500"] = 1, ["C308F00"] = 1, ["E310701"] = 12,
	},
	[80] = {
		["E305500"] = 17, ["E309700"] = 64, ["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 3, ["E302700"] = 37,
		["E309200"] = 58, ["C30CA01"] = 1, ["C305500"] = 1, ["C308F00"] = 1, ["E30C800"] = 12, ["E30BD00"] = 60,
		["E307B00"] = 4,
	},
	[81] = {
		["E305500"] = 127, ["E309700"] = 66, ["E302700"] = 37, ["E302600"] = 10, ["E30CD00"] = 78, ["E309200"] = 122,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 108, ["C308F00"] = 1, ["E30BD00"] = 6,
	},
	[82] = {
		["E305500"] = 97, ["E309700"] = 40, ["E305400"] = 18, ["E307400"] = 18, ["E302700"] = 97, ["E30CD00"] = 102,
		["C30CA00"] = 1, ["C305500"] = 1, ["E302402"] = 12, ["E30BD00"] = 9,
	},
	[83] = {
		["C316B00"] = 1, ["E305500"] = 127, ["E309700"] = 44, ["C307800"] = 1, ["E302700"] = 126, ["E317700"] = 58,
		["E302600"] = 10, ["E309200"] = 30, ["C305500"] = 1, ["E310700"] = 69, ["C308F00"] = 1, ["E307B00"] = 20,
	},
	[84] = {
		["E305500"] = 128, ["E305400"] = 24, ["E302600"] = 84, ["E309200"] = 126, ["C305500"] = 1, ["E310700"] = 34,
		["C308F00"] = 1, ["E302402"] = 24, ["E30C800"] = 20, ["E30BD00"] = 28,
	},
	[85] = {
		["E316A01"] = 18, ["E309700"] = 48, ["E305400"] = 24, ["E303D00"] = 2, ["E302700"] = 67, ["E302600"] = 20,
		["C303C00"] = 1, ["E30C800"] = 28, ["E310701"] = 22,
	},
	[86] = {
		["E305500"] = 45, ["E309700"] = 8, ["E307400"] = 128, ["E307000"] = 94, ["E302700"] = 19, ["E302600"] = 70,
		["C305500"] = 1, ["E310700"] = 30, ["E302402"] = 42,
	},
	[87] = {
		["E316A00"] = 2, ["E309700"] = 40, ["E305400"] = 94, ["E302500"] = 23, ["E307400"] = 100, ["E302600"] = 69,
		["C305500"] = 1, ["E310700"] = 64, ["E302402"] = 34,
	},
	[88] = {
		["E309700"] = 52, ["C307800"] = 1, ["E317600"] = 10, ["E307300"] = 13, ["E310700"] = 9, ["E302402"] = 10,
		["E30C800"] = 50, ["E310701"] = 10, ["E307B00"] = 32,
	},
	[89] = {
		["E317B00"] = 34, ["C316D00"] = 1, ["E305500"] = 21, ["E307700"] = 24, ["E302700"] = 49, ["E302400"] = 2,
		["E302600"] = 70, ["C30CA01"] = 1, ["C305500"] = 1, ["E000703"] = 16, ["E310700"] = 22,
	},
	[90] = {
		["E316700"] = 54, ["E305500"] = 32, ["E309700"] = 64, ["E305400"] = 112, ["E302500"] = 75, ["E30CD00"] = 116,
		["E309200"] = 10, ["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 40, ["C308F00"] = 1,
	},
	[91] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E305500"] = 81, ["E309700"] = 40, ["E302600"] = 65, ["C30CA01"] = 1,
		["C305500"] = 1, ["E310700"] = 20, ["E30C800"] = 98, ["E316C00"] = 4, ["E310701"] = 24,
	},
	[92] = {
		["E316A00"] = 20, ["E305400"] = 112, ["E302500"] = 77, ["E302700"] = 102, ["C307801"] = 1, ["E302600"] = 32,
		["E309200"] = 48, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 17, ["C308F00"] = 1,
		["E307B01"] = 98,
	},
	[93] = {
		["E309700"] = 122, ["E302700"] = 45, ["E317500"] = 24, ["E302600"] = 25, ["E30CD00"] = 26, ["C30CA00"] = 1,
		["E310700"] = 15, ["E30C800"] = 29, ["E310701"] = 56,
	},
	[94] = {
		["E305500"] = 7, ["E307900"] = 8, ["E308000"] = 16, ["E302600"] = 14, ["C305500"] = 1, ["E310700"] = 19,
		["E302402"] = 40, ["E30C800"] = 1, ["E310701"] = 8,
	},
	[95] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E317600"] = 2, ["E303D00"] = 12, ["E302700"] = 65, ["E302600"] = 43,
		["E309200"] = 24, ["C303C00"] = 1, ["E310700"] = 30, ["C308F00"] = 1, ["E30C800"] = 36,
	},
	[96] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E305500"] = 10, ["C307800"] = 1, ["E303D00"] = 14, ["E309200"] = 26,
		["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 86, ["C308F00"] = 1, ["E302402"] = 22, ["E310701"] = 10,
		["E307B00"] = 38,
	},
	[97] = {
		["C316B00"] = 1, ["E305500"] = 69, ["C307800"] = 1, ["E317700"] = 2, ["E302600"] = 15, ["E30CD00"] = 28,
		["C30CA00"] = 1, ["E312500"] = 40, ["C305500"] = 1, ["E310700"] = 68, ["E30C800"] = 20, ["E307B00"] = 18,
	},
	[98] = {
		["C310700"] = 1, ["E308702"] = 3, ["C307800"] = 1, ["E303D00"] = 14, ["E302700"] = 61, ["E30CD00"] = 56,
		["E309200"] = 82, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C303C00"] = 1, ["E000703"] = 4, ["E30BC00"] = 2,
		["C308F00"] = 1, ["E310701"] = 28, ["E307B00"] = 36,
	},
	[99] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E305500"] = 37, ["E308702"] = 3, ["E305400"] = 2, ["E303D00"] = 12,
		["E302600"] = 40, ["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 60, ["E30BD00"] = 30,
	},
	[100] = {
		["C316B00"] = 1, ["E305500"] = 29, ["E305400"] = 2, ["E308F00"] = 8, ["C307800"] = 1, ["E303D00"] = 10,
		["E317700"] = 42, ["E302600"] = 6, ["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 62, ["E307B00"] = 34,
	},
	[101] = {
		["E305500"] = 37, ["E305400"] = 2, ["C307800"] = 1, ["E303D00"] = 12, ["E302600"] = 24, ["C305500"] = 1,
		["C303C00"] = 1, ["E310700"] = 32, ["E302402"] = 26, ["E30C800"] = 52, ["E307B00"] = 14,
	},
	[102] = {
		["E316B01"] = 12, ["E316A00"] = 14, ["E305500"] = 45, ["E309700"] = 26, ["E305400"] = 20, ["C307800"] = 1,
		["C305500"] = 1, ["E310700"] = 38, ["E302402"] = 34, ["E307B00"] = 12,
	},
	[103] = {
		["E316A00"] = 14, ["E305500"] = 43, ["E309700"] = 18, ["E305400"] = 36, ["E302600"] = 10, ["C305500"] = 1,
		["E310700"] = 32, ["E30C800"] = 14, ["E000000"] = 26,
	},
	[104] = {
		["E305400"] = 34, ["E302500"] = 11, ["E307400"] = 20, ["E309200"] = 92, ["E310700"] = 20, ["C308F00"] = 1,
		["E30C800"] = 2, ["E30A900"] = 8, ["E310701"] = 70,
	},
	[105] = {
		["E200007"] = 18, ["E309700"] = 48, ["E305400"] = 26, ["E307400"] = 62, ["E302700"] = 19, ["E317500"] = 8,
		["C30CA01"] = 1, ["E310700"] = 4, ["E302402"] = 22, ["C30AC00"] = 1,
	},
	[106] = {
		["E316B02"] = 6, ["E309700"] = 124, ["E305400"] = 28, ["E307400"] = 18, ["E309200"] = 6, ["C30CA01"] = 1,
		["E310700"] = 20, ["C308F00"] = 1, ["E30C800"] = 30, ["E310701"] = 10,
	},
	[107] = {
		["E317B00"] = 42, ["C316D00"] = 1, ["E309700"] = 18, ["E305400"] = 26, ["E307400"] = 20, ["E317500"] = 5,
		["E30CD00"] = 44, ["E309200"] = 82, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C308F00"] = 1, ["E30CA00"] = 4,
	},
	[108] = {
		["E309700"] = 10, ["E305400"] = 26, ["E307400"] = 12, ["E302700"] = 99, ["E302600"] = 15, ["E309200"] = 56,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 11, ["C308F00"] = 1, ["C30AC00"] = 1, ["E30BD00"] = 30,
	},
	[109] = {
		["C316B00"] = 1, ["E316900"] = 10, ["E309700"] = 18, ["E307400"] = 38, ["E317700"] = 2, ["E302600"] = 9,
		["E309200"] = 4, ["C305500"] = 1, ["E310700"] = 8, ["C308F00"] = 1, ["C30AC00"] = 1, ["E310701"] = 4,
	},
	[110] = {
		["E305400"] = 4, ["E307400"] = 38, ["C307801"] = 1, ["E302600"] = 8, ["E309200"] = 4, ["C30CA01"] = 1,
		["C305500"] = 1, ["E310700"] = 6, ["C308F00"] = 1, ["E303A00"] = 6, ["E302402"] = 2, ["C30AC00"] = 1,
		["E307B01"] = 4,
	},
	[111] = {
		["E305500"] = 5, ["E305400"] = 12, ["C307800"] = 1, ["E307400"] = 80, ["E30CD00"] = 32, ["C30CA00"] = 1,
		["C305500"] = 1, ["E302402"] = 16, ["E30C800"] = 28, ["E30BD00"] = 40, ["E307B00"] = 118,
	},
	[112] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["C310700"] = 1, ["E308700"] = 1, ["E305400"] = 4, ["E30CD00"] = 2,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["E302402"] = 2, ["E30C800"] = 1, ["E310701"] = 26, ["E30BD00"] = 12,
	},
	[113] = {
		["C316B00"] = 1, ["E305500"] = 3, ["E309700"] = 32, ["E305400"] = 12, ["E317700"] = 10, ["E302600"] = 12,
		["C305500"] = 1, ["E30C800"] = 2, ["E310701"] = 8, ["E30BD00"] = 2,
	},
	[114] = {
		["E316B01"] = 6, ["E305500"] = 17, ["E308401"] = 5, ["E305400"] = 12, ["E302700"] = 45, ["E302600"] = 56,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 20, ["E310701"] = 8,
	},
	[115] = {
		["E317B00"] = 32, ["C316D00"] = 1, ["E316A01"] = 6, ["E308702"] = 1, ["E305400"] = 6, ["E30CD00"] = 2,
		["C30CA00"] = 1, ["E310700"] = 7, ["C30AC00"] = 1, ["E310701"] = 20, ["E30BD00"] = 8,
	},
	[116] = {
		["E317B00"] = 16, ["C316D00"] = 1, ["E305400"] = 4, ["E302500"] = 6, ["E30CD00"] = 2, ["C30CA00"] = 1,
		["E310700"] = 1, ["E30C800"] = 2, ["E310701"] = 2, ["E30BD00"] = 49,
	},
	[117] = {
		["E305500"] = 7, ["E302500"] = 10, ["E302700"] = 34, ["E309200"] = 4, ["C30CA01"] = 1, ["C305500"] = 1,
		["E310700"] = 2, ["C308F00"] = 1, ["E30C800"] = 54, ["E310701"] = 10, ["E30BD00"] = 50,
	},
	[118] = {
		["E316800"] = 18, ["C310700"] = 1, ["E302500"] = 10, ["E302700"] = 3, ["E30CD00"] = 4, ["C30CA00"] = 1,
		["E30C800"] = 2, ["C30AC00"] = 1, ["E310701"] = 4, ["E30BD00"] = 16, ["E30B500"] = 1,
	},
	[119] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["E305500"] = 7, ["E311E00"] = 2, ["E302700"] = 35, ["E317500"] = 1,
		["E302600"] = 9, ["E309200"] = 4, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 13, ["C308F00"] = 1,
	},
	[120] = {
		["E302700"] = 18, ["E312801"] = 14, ["E302600"] = 26, ["E30CD00"] = 20, ["E309200"] = 8, ["C30CA00"] = 1,
		["E310700"] = 17, ["C308F00"] = 1, ["E310701"] = 16, ["E30BD00"] = 14,
	},
	[121] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["C310700"] = 1, ["E308702"] = 1, ["E302500"] = 15, ["E302600"] = 10,
		["E30CD00"] = 2, ["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 2, ["E30C800"] = 10, ["E310701"] = 1,
	},
	[122] = {
		["E316B01"] = 16, ["E309700"] = 17, ["E302700"] = 17, ["E302600"] = 9, ["E309200"] = 72, ["C30CA01"] = 1,
		["C305500"] = 1, ["E310700"] = 17, ["C308F00"] = 1, ["E302402"] = 24, ["E30C800"] = 15,
	},
	[123] = {
		["E316A01"] = 2, ["E309700"] = 4, ["E302700"] = 5, ["E302600"] = 2, ["E30CD00"] = 2, ["C30CA00"] = 1,
		["C30CA01"] = 1, ["E310700"] = 18, ["E30C800"] = 6, ["E310701"] = 4,
	},
	[124] = {
		["E305500"] = 73, ["E307400"] = 30, ["E303D00"] = 4, ["E302600"] = 16, ["C30CA01"] = 1, ["C305500"] = 1,
		["C303C00"] = 1, ["E310700"] = 28, ["E30C800"] = 6, ["E310701"] = 70, ["E30BD00"] = 64,
	},
	[125] = {
		["E316A00"] = 14, ["E309700"] = 56, ["E307000"] = 30, ["E302600"] = 32, ["E309200"] = 88, ["E30CA03"] = 16,
		["E310700"] = 15, ["C308F00"] = 1, ["E310701"] = 7,
	},
	[126] = {
		["E316A00"] = 20, ["E309700"] = 60, ["E307400"] = 30, ["E302600"] = 36, ["E30CD00"] = 26, ["E309200"] = 74,
		["C30CA00"] = 1, ["E310700"] = 10, ["C308F00"] = 1, ["E30C800"] = 2,
	},
	[127] = {
		["E305500"] = 127, ["E309700"] = 14, ["E307400"] = 30, ["E303D00"] = 32, ["E302600"] = 36, ["E309200"] = 92,
		["C305500"] = 1, ["C303C00"] = 1, ["E302401"] = 2, ["E310700"] = 24, ["C308F00"] = 1,
	},
	[128] = {
		["E316D00"] = 8, ["E305500"] = 13, ["E309700"] = 18, ["E302500"] = 15, ["E302600"] = 46, ["C305500"] = 1,
		["E302402"] = 40, ["E310701"] = 17, ["E30BD00"] = 15,
	},
	[129] = {
		["E305500"] = 13, ["E309700"] = 18, ["E307400"] = 44, ["E302600"] = 17, ["C305500"] = 1, ["E310700"] = 17,
		["E30C800"] = 18, ["E310701"] = 26, ["E30BD00"] = 19,
	},
	[130] = {
		["E317B00"] = 44, ["C316D00"] = 1, ["E305500"] = 21, ["E309700"] = 29, ["C310700"] = 1, ["E307400"] = 44,
		["E302700"] = 3, ["E317500"] = 40, ["E309200"] = 2, ["C305500"] = 1, ["C308F00"] = 1, ["E302402"] = 78,
	},
	[131] = {
		["E316B00"] = 30, ["E305500"] = 27, ["E309700"] = 28, ["E302500"] = 19, ["E307400"] = 26, ["E302700"] = 3,
		["E309200"] = 2, ["C305500"] = 1, ["C308F00"] = 1, ["E30C800"] = 69,
	},
	[132] = {
		["E305500"] = 13, ["E309700"] = 28, ["E305400"] = 26, ["E302500"] = 19, ["E302700"] = 6, ["C30CA01"] = 1,
		["C305500"] = 1, ["E310700"] = 17, ["E302402"] = 14, ["E310701"] = 78,
	},
	[133] = {
		["E317B00"] = 34, ["C316D00"] = 1, ["E316A01"] = 4, ["E305500"] = 31, ["E305400"] = 26, ["E302500"] = 18,
		["E302700"] = 17, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 11, ["E302402"] = 124,
	},
	[134] = {
		["E316B02"] = 10, ["E309700"] = 24, ["E305400"] = 26, ["E302500"] = 14, ["E302700"] = 2, ["E302600"] = 9,
		["C30CA01"] = 1, ["E30C800"] = 2,
	},
	[135] = {
		["E305500"] = 13, ["E309700"] = 4, ["E305400"] = 26, ["E302500"] = 7, ["C307801"] = 1, ["E302600"] = 10,
		["C30CA01"] = 1, ["C305500"] = 1, ["C30AC00"] = 1, ["E310701"] = 8, ["E30BD00"] = 13, ["E307B01"] = 22,
	},
	[136] = {
		["E316D00"] = 4, ["E305500"] = 41, ["E309700"] = 72, ["E302600"] = 3, ["E309200"] = 82, ["C305500"] = 1,
		["E310700"] = 20, ["C308F00"] = 1, ["E30C800"] = 32, ["E310701"] = 10,
	},
	[137] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["E305500"] = 22, ["E302700"] = 3, ["E302600"] = 6, ["E309200"] = 4,
		["C305500"] = 1, ["E310700"] = 11, ["C308F00"] = 1, ["E310701"] = 6, ["E30BD00"] = 42,
	},
	[138] = {
		["E316D00"] = 2, ["E305500"] = 25, ["E309700"] = 6, ["E302600"] = 3, ["E30CD00"] = 58, ["E309200"] = 2,
		["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 30, ["C308F00"] = 1, ["E310701"] = 4,
	},
	[139] = {
		["E305500"] = 5, ["E309700"] = 2, ["C310700"] = 1, ["E303D00"] = 10, ["E302700"] = 3, ["E302600"] = 2,
		["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 1, ["E000701"] = 1, ["E30BD00"] = 10,
	},
	[140] = {
		["E316700"] = 14, ["E305500"] = 12, ["E309700"] = 2, ["E303D00"] = 2, ["E302700"] = 5, ["E302600"] = 2,
		["C30CA01"] = 1, ["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 6, ["E30C800"] = 2,
	},
	[141] = {
		["E317B00"] = 62, ["C316D00"] = 1, ["E305500"] = 99, ["E309700"] = 30, ["E303D00"] = 40, ["E302600"] = 7,
		["E309200"] = 68, ["C30CA01"] = 1, ["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 48, ["C308F00"] = 1,
		["E30BD00"] = 14,
	},
	[142] = {
		["E316B01"] = 10, ["E305500"] = 47, ["E305400"] = 26, ["E307400"] = 6, ["E302700"] = 3, ["E302600"] = 7,
		["E30CD00"] = 24, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 28,
	},
	[143] = {
		["E305500"] = 39, ["E305400"] = 2, ["E307400"] = 36, ["E302600"] = 12, ["E30CD00"] = 34, ["C30CA00"] = 1,
		["C305500"] = 1, ["E302401"] = 28, ["E310701"] = 105, ["E30BD00"] = 124,
	},
	[144] = {
		["E305500"] = 16, ["E309700"] = 62, ["E305400"] = 2, ["E302700"] = 9, ["C30CA01"] = 1, ["C305500"] = 1,
		["E302401"] = 2, ["E310700"] = 30, ["E30C800"] = 80, ["E310701"] = 4,
	},
	[145] = {
		["E309700"] = 62, ["E305400"] = 2, ["E303D00"] = 14, ["E302700"] = 17, ["C30CA01"] = 1, ["C303C00"] = 1,
		["E310700"] = 30, ["E30C800"] = 64, ["E310701"] = 6, ["E30BD00"] = 22,
	},
	[146] = {
		["E305500"] = 49, ["E309700"] = 34, ["E305400"] = 2, ["E302600"] = 4, ["E30CD00"] = 12, ["C30CA00"] = 1,
		["C30CA01"] = 1, ["C305500"] = 1, ["E302401"] = 1, ["E310700"] = 48, ["E30C800"] = 80,
	},
	[147] = {
		["E316D00"] = 34, ["E316B00"] = 8, ["E305500"] = 25, ["E309700"] = 58, ["E305400"] = 2, ["E302600"] = 4,
		["C305500"] = 1, ["E302401"] = 6, ["E30C800"] = 30,
	},
	[148] = {
		["E309700"] = 34, ["E305400"] = 2, ["E302600"] = 4, ["E30CD00"] = 36, ["E309200"] = 24, ["C30CA00"] = 1,
		["C305500"] = 1, ["E310700"] = 18, ["C308F00"] = 1, ["E30C800"] = 2, ["E30BD00"] = 4,
	},
	[149] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["E305400"] = 58, ["E307400"] = 42, ["E302700"] = 18, ["E30CD00"] = 12,
		["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 76, ["E30C800"] = 24, ["E310701"] = 14,
	},
	[150] = {
		["E317B00"] = 30, ["C316D00"] = 1, ["E316B00"] = 22, ["E305400"] = 46, ["E307400"] = 28, ["E302700"] = 19,
		["C307801"] = 1, ["C305500"] = 1, ["E310700"] = 21, ["E310701"] = 7, ["E307B01"] = 20,
	},
	[151] = {
		["E317B00"] = 46, ["C316D00"] = 1, ["E305500"] = 17, ["E305400"] = 46, ["E307400"] = 46, ["E302600"] = 7,
		["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 67, ["E310701"] = 52, ["E30BD00"] = 30,
	},
	[152] = {
		["E305400"] = 46, ["C307800"] = 1, ["E307400"] = 50, ["E302700"] = 5, ["E302600"] = 72, ["E309200"] = 70,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 18, ["C308F00"] = 1, ["E302402"] = 6, ["E307B00"] = 54,
	},
	[153] = {
		["E316A01"] = 8, ["E305500"] = 9, ["E302700"] = 21, ["C307801"] = 1, ["E302600"] = 17, ["C305500"] = 1,
		["E310700"] = 28, ["E302402"] = 6, ["E310701"] = 12, ["E307B01"] = 12,
	},
	[154] = {
		["E316A00"] = 14, ["E309700"] = 10, ["E302500"] = 15, ["E302700"] = 29, ["E302600"] = 10, ["C305500"] = 1,
		["E310700"] = 22, ["E302402"] = 46, ["E100101"] = 20,
	},
	[155] = {
		["E317B00"] = 22, ["C316D00"] = 1, ["E305500"] = 29, ["E305400"] = 48, ["C307800"] = 1, ["E303D00"] = 12,
		["E309200"] = 16, ["C305500"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E30C800"] = 104, ["E310701"] = 34,
		["E307B00"] = 14,
	},
	[156] = {
		["E316D00"] = 22, ["E308702"] = 1, ["E302500"] = 19, ["E303D00"] = 2, ["E302600"] = 14, ["C303C00"] = 1,
		["E310700"] = 1, ["E30C800"] = 2, ["E310701"] = 2,
	},
	[157] = {
		["E305500"] = 5, ["E308702"] = 19, ["E302500"] = 25, ["E302700"] = 3, ["E317500"] = 12, ["E302600"] = 12,
		["C305500"] = 1, ["E310701"] = 26, ["E30B500"] = 1,
	},
	[158] = {
		["E308702"] = 3, ["E302500"] = 9, ["E302700"] = 23, ["E302400"] = 4, ["E302600"] = 54, ["C30CA01"] = 1,
		["E310700"] = 14, ["E302402"] = 20, ["E310701"] = 3,
	},
	[159] = {
		["E305500"] = 21, ["E309700"] = 42, ["E302500"] = 9, ["C307801"] = 1, ["E30CD00"] = 26, ["E309200"] = 38,
		["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 31, ["C308F00"] = 1, ["E310701"] = 16, ["E307B01"] = 14,
	},
	[160] = {
		["E309700"] = 34, ["C310700"] = 1, ["E307000"] = 12, ["C307801"] = 1, ["E302400"] = 28, ["E302600"] = 5,
		["E309200"] = 14, ["C30CA01"] = 1, ["C308F00"] = 1, ["E302402"] = 14, ["E30BD00"] = 10, ["E307B01"] = 10,
	},
	[161] = {
		["E317400"] = 10, ["E309700"] = 46, ["E307700"] = 22, ["E302700"] = 12, ["E302600"] = 14, ["E309200"] = 14,
		["E310700"] = 11, ["C308F00"] = 1, ["E310701"] = 6,
	},
	[162] = {
		["E317B00"] = 38, ["C316D00"] = 1, ["E305500"] = 93, ["E309700"] = 46, ["E302500"] = 22, ["E302700"] = 13,
		["E302600"] = 14, ["C305500"] = 1, ["E310700"] = 70, ["C30AC00"] = 1, ["E30BD00"] = 19,
	},
	[163] = {
		["E309700"] = 32, ["C310700"] = 1, ["E307000"] = 12, ["E302700"] = 29, ["C307801"] = 1, ["E302600"] = 10,
		["E309200"] = 14, ["C308F00"] = 1, ["E30C800"] = 1, ["E310701"] = 15, ["E307B01"] = 6,
	},
	[164] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["E316B01"] = 2, ["E309700"] = 44, ["C310700"] = 1, ["E302500"] = 24,
		["E302600"] = 30, ["E309200"] = 10, ["C30CA01"] = 1, ["C308F00"] = 1, ["E30C800"] = 1, ["E310701"] = 10,
	},
	[165] = {
		["E317B00"] = 26, ["C316D00"] = 1, ["E316800"] = 11, ["E305500"] = 91, ["E309700"] = 94, ["E302500"] = 3,
		["E303D00"] = 34, ["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 25, ["E30CA00"] = 24,
	},
	[166] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 50, ["E303D00"] = 18,
		["E302700"] = 39, ["C307801"] = 1, ["C303C00"] = 1, ["E30CA00"] = 24, ["E30BD00"] = 26, ["E307B00"] = 128,
		["E307B01"] = 6,
	},
	[167] = {
		["C307800"] = 1, ["E302500"] = 47, ["E302700"] = 72, ["E302600"] = 73, ["E309200"] = 84, ["C305500"] = 1,
		["E310700"] = 102, ["C308F00"] = 1, ["E302402"] = 34, ["E310701"] = 22, ["E307B00"] = 66,
	},
	[168] = {
		["E309700"] = 36, ["C310700"] = 1, ["E302700"] = 5, ["E317500"] = 16, ["E302600"] = 5, ["E309200"] = 12,
		["E307100"] = 24, ["C308F00"] = 1, ["E316F00"] = 4, ["E30BD00"] = 8,
	},
	[169] = {
		["E305400"] = 10, ["C307800"] = 1, ["E307400"] = 14, ["E302600"] = 26, ["E30CD00"] = 16, ["E309200"] = 12,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["C308F00"] = 1, ["E30C800"] = 74, ["E310701"] = 4, ["E307B00"] = 86,
	},
	[170] = {
		["E305500"] = 49, ["E309700"] = 22, ["E305400"] = 14, ["E307400"] = 128, ["E302700"] = 11, ["C30CA01"] = 1,
		["C305500"] = 1, ["E000703"] = 30, ["E30BC00"] = 2, ["E310700"] = 9, ["E310701"] = 32,
	},
	[171] = {
		["E316D00"] = 24, ["E305500"] = 79, ["E317600"] = 4, ["E302500"] = 114, ["E302700"] = 33, ["E302600"] = 28,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 6, ["E310701"] = 42,
	},
	[172] = {
		["E316D00"] = 6, ["E309700"] = 11, ["E305400"] = 4, ["E302500"] = 1, ["E30CD00"] = 26, ["E309200"] = 4,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 20, ["C308F00"] = 1, ["E302402"] = 28,
	},
	[173] = {
		["E316B02"] = 6, ["E316A01"] = 4, ["E305500"] = 27, ["E305400"] = 8, ["E302600"] = 10, ["E30CD00"] = 16,
		["E309200"] = 2, ["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 26, ["C308F00"] = 1,
	},
	[174] = {
		["E305500"] = 41, ["E305400"] = 60, ["E317600"] = 10, ["E307400"] = 52, ["E302700"] = 17, ["E302600"] = 46,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 44, ["E310701"] = 37,
	},
	[175] = {
		["E305500"] = 5, ["E309700"] = 26, ["E305400"] = 60, ["E307400"] = 8, ["E302700"] = 17, ["C307801"] = 1,
		["E302600"] = 34, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 10, ["E307B01"] = 24,
	},
	[176] = {
		["E316A00"] = 22, ["E305400"] = 60, ["E302500"] = 38, ["E307400"] = 32, ["E302700"] = 17, ["C305500"] = 1,
		["E310700"] = 20, ["E310701"] = 50, ["E000000"] = 90,
	},
	[177] = {
		["E316A01"] = 22, ["E305500"] = 53, ["E309700"] = 18, ["E307400"] = 114, ["E302700"] = 31, ["C305500"] = 1,
		["E312600"] = 16, ["E310700"] = 25, ["E310701"] = 102,
	},
	[178] = {
		["C310700"] = 1, ["E305400"] = 72, ["E302500"] = 96, ["E307400"] = 26, ["E303D00"] = 74, ["E302600"] = 30,
		["E30CD00"] = 118, ["E309200"] = 46, ["C30CA00"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E302402"] = 56,
	},
	[179] = {
		["E316D00"] = 8, ["E305500"] = 7, ["E302500"] = 5, ["E302700"] = 5, ["E302600"] = 14, ["E30CD00"] = 88,
		["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 40, ["E30C800"] = 24,
	},
	[180] = {
		["E309700"] = 62, ["E307400"] = 12, ["E302600"] = 22, ["E30CD00"] = 42, ["E309200"] = 12, ["C30CA00"] = 1,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 14, ["C308F00"] = 1, ["E312502"] = 18, ["E30BD00"] = 10,
	},
	[181] = {
		["E316A00"] = 18, ["E305500"] = 2, ["E308702"] = 13, ["E307400"] = 12, ["E302700"] = 3, ["E302600"] = 30,
		["E309200"] = 48, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 17, ["C308F00"] = 1,
	},
	[182] = {
		["E316700"] = 20, ["E302700"] = 3, ["E302600"] = 4, ["E309200"] = 78, ["C30CA01"] = 1, ["E310700"] = 10,
		["C308F00"] = 1, ["E30C800"] = 2, ["E310701"] = 20, ["E30B500"] = 9,
	},
	[183] = {
		["C316B00"] = 1, ["E305500"] = 33, ["E308702"] = 3, ["E317700"] = 4, ["E302600"] = 34, ["E309200"] = 38,
		["C305500"] = 1, ["E310700"] = 13, ["C308F00"] = 1, ["E312301"] = 2, ["E310701"] = 3,
	},
	[184] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["E309700"] = 58, ["E307400"] = 106, ["E302700"] = 42, ["E302600"] = 24,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 5, ["E30C800"] = 8, ["E30BD00"] = 5,
	},
	[185] = {
		["C310700"] = 1, ["E305400"] = 98, ["C307800"] = 1, ["E302500"] = 31, ["E302700"] = 12, ["E302600"] = 48,
		["E30CD00"] = 34, ["C30CA00"] = 1, ["C305500"] = 1, ["E30C800"] = 16, ["E310701"] = 43, ["E307B00"] = 36,
	},
	[186] = {
		["E309700"] = 44, ["C310700"] = 1, ["E305400"] = 128, ["C307800"] = 1, ["E302700"] = 9, ["E302600"] = 8,
		["E30CD00"] = 32, ["C30CA00"] = 1, ["C305500"] = 1, ["E30C800"] = 14, ["E310701"] = 47, ["E307B00"] = 36,
	},
	[187] = {
		["C310700"] = 1, ["E305400"] = 112, ["C307800"] = 1, ["E307400"] = 16, ["E302700"] = 9, ["E302600"] = 40,
		["E30CD00"] = 28, ["C30CA00"] = 1, ["C305500"] = 1, ["E30C800"] = 18, ["E310701"] = 47, ["E307B00"] = 48,
	},
	[188] = {
		["E307400"] = 16, ["E303D00"] = 10, ["E302700"] = 3, ["E302600"] = 14, ["E309200"] = 16, ["C30CA01"] = 1,
		["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 8, ["C308F00"] = 1, ["E30C800"] = 4, ["E310701"] = 3,
	},
	[189] = {
		["E317B00"] = 32, ["C316D00"] = 1, ["E308502"] = 6, ["E307400"] = 16, ["E302700"] = 3, ["E302600"] = 9,
		["E309200"] = 14, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 20, ["C308F00"] = 1, ["E302402"] = 22,
	},
	[190] = {
		["E305500"] = 40, ["E309700"] = 26, ["E307400"] = 16, ["E312801"] = 110, ["E302600"] = 10, ["C305500"] = 1,
		["E310700"] = 18, ["E30C800"] = 24, ["E310701"] = 20,
	},
	[191] = {
		["E309700"] = 30, ["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 83, ["E303D00"] = 46, ["C307801"] = 1,
		["E302600"] = 50, ["E309200"] = 38, ["C30CA01"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E30C800"] = 12,
		["E307B00"] = 38, ["E307B01"] = 40,
	},
	[192] = {
		["E317B00"] = 8, ["C316D00"] = 1, ["E302700"] = 3, ["E302600"] = 34, ["E309200"] = 58, ["E307100"] = 16,
		["E30CA03"] = 64, ["E310700"] = 20, ["C308F00"] = 1, ["E310701"] = 8,
	},
	[193] = {
		["E316D00"] = 10, ["E305500"] = 63, ["E309700"] = 68, ["E307400"] = 128, ["E303D00"] = 10, ["E302600"] = 59,
		["C30CA01"] = 1, ["C305500"] = 1, ["C303C00"] = 1, ["E310700"] = 58, ["E310701"] = 12,
	},
	[194] = {
		["E309700"] = 35, ["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 67, ["E307400"] = 16, ["E303D00"] = 2,
		["E302600"] = 60, ["C303C00"] = 1, ["E30C800"] = 8, ["E310701"] = 3, ["E307B00"] = 72,
	},
	[195] = {
		["E309700"] = 96, ["C310700"] = 1, ["E305400"] = 6, ["C307800"] = 1, ["E307400"] = 78, ["E302700"] = 13,
		["E30CD00"] = 10, ["C30CA00"] = 1, ["E316F00"] = 12, ["E30BD00"] = 4, ["E307B00"] = 68,
	},
	[196] = {
		["E305500"] = 2, ["E305400"] = 6, ["E307400"] = 10, ["E302700"] = 23, ["E302600"] = 10, ["C30CA01"] = 1,
		["C305500"] = 1, ["E000703"] = 4, ["E30C800"] = 1, ["E30BD00"] = 25,
	},
	[197] = {
		["E309700"] = 8, ["E305400"] = 6, ["C307800"] = 1, ["E307400"] = 78, ["C307801"] = 1, ["E302600"] = 22,
		["E30C800"] = 20, ["E310701"] = 14, ["E307B00"] = 120, ["E307B01"] = 12,
	},
	[198] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E305400"] = 6, ["C307800"] = 1, ["E302500"] = 1, ["E307400"] = 72,
		["E302700"] = 27, ["C307801"] = 1, ["E30CD00"] = 48, ["C30CA00"] = 1, ["E307B00"] = 106, ["E307B01"] = 30,
	},
	[199] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["E305400"] = 6, ["C307800"] = 1, ["E307400"] = 80, ["E302600"] = 34,
		["E309200"] = 26, ["E310700"] = 31, ["C308F00"] = 1, ["E30C800"] = 35, ["E307B00"] = 128,
	},
	[200] = {
		["E305500"] = 61, ["E307400"] = 78, ["C307801"] = 1, ["E317500"] = 8, ["E302600"] = 19, ["C30CA01"] = 1,
		["C305500"] = 1, ["E316F00"] = 6, ["E310701"] = 62, ["E30BD00"] = 44, ["E307B01"] = 12,
	},
	[201] = {
		["E316D00"] = 6, ["E305500"] = 20, ["E309700"] = 60, ["E305400"] = 6, ["E307400"] = 72, ["E302600"] = 17,
		["E30CD00"] = 36, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C305500"] = 1, ["E310701"] = 56,
	},
	[202] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E305500"] = 39, ["E309700"] = 112, ["E307400"] = 78, ["E302700"] = 55,
		["E309200"] = 34, ["C305500"] = 1, ["E310700"] = 22, ["C308F00"] = 1, ["E30BD00"] = 4,
	},
	[203] = {
		["E305500"] = 47, ["E309700"] = 112, ["E307400"] = 78, ["E302700"] = 41, ["C307801"] = 1, ["E309200"] = 32,
		["C305500"] = 1, ["E310700"] = 15, ["C308F00"] = 1, ["E30BD00"] = 4, ["E307B01"] = 10,
	},
	[204] = {
		["E305500"] = 75, ["E309700"] = 120, ["E307400"] = 78, ["E302700"] = 35, ["E302600"] = 12, ["C305500"] = 1,
		["E310700"] = 20, ["E310701"] = 3, ["E30BD00"] = 2,
	},
	[205] = {
		["E305500"] = 63, ["E309700"] = 123, ["C307800"] = 1, ["E307400"] = 52, ["E302700"] = 29, ["C307801"] = 1,
		["E309200"] = 32, ["C305500"] = 1, ["C308F00"] = 1, ["E30C800"] = 40, ["E307B00"] = 18, ["E307B01"] = 14,
	},
	[206] = {
		["E316700"] = 6, ["C310700"] = 1, ["C307800"] = 1, ["E302500"] = 89, ["E307400"] = 52, ["E303D00"] = 16,
		["C307801"] = 1, ["E302600"] = 31, ["C303C00"] = 1, ["E30C800"] = 19, ["E307B00"] = 26, ["E307B01"] = 108,
	},
	[207] = {
		["E305500"] = 37, ["E309700"] = 122, ["E305400"] = 80, ["E302500"] = 15, ["E302700"] = 29, ["E30CD00"] = 6,
		["E309200"] = 54, ["C30CA00"] = 1, ["C30CA01"] = 1, ["C305500"] = 1, ["C308F00"] = 1, ["E302402"] = 20,
	},
	[208] = {
		["E316D00"] = 18, ["E305500"] = 9, ["E307400"] = 2, ["C307801"] = 1, ["E302600"] = 10, ["E307100"] = 4,
		["C305500"] = 1, ["E310700"] = 24, ["E30C800"] = 54, ["E307B01"] = 34,
	},
	[209] = {
		["E316D00"] = 12, ["E307400"] = 6, ["E302700"] = 15, ["E302600"] = 9, ["E310700"] = 28, ["E312401"] = 30,
		["E30C800"] = 42, ["E310701"] = 18,
	},
	[210] = {
		["E305400"] = 68, ["C307800"] = 1, ["E317500"] = 22, ["E307300"] = 1, ["E30CD00"] = 80, ["E309200"] = 8,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 57, ["C308F00"] = 1, ["E30BD00"] = 40, ["E307B00"] = 4,
	},
	[211] = { ["C30CA01"] = 1, ["E000703"] = 1, ["E310700"] = 6 },
	[212] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["C310700"] = 1, ["E302700"] = 5, ["E302600"] = 5, ["E30CD00"] = 8,
		["C30CA00"] = 1, ["E310700"] = 1, ["E310701"] = 3, ["E30BD00"] = 2,
	},
	[213] = {
		["E317B00"] = 114, ["C316D00"] = 1, ["E317600"] = 2, ["E307400"] = 78, ["E309200"] = 12, ["E310700"] = 29,
		["C308F00"] = 1, ["E302402"] = 60, ["E310701"] = 26, ["E30BD00"] = 94,
	},
	[214] = {
		["E317B00"] = 78, ["C316D00"] = 1, ["E309700"] = 40, ["C307800"] = 1, ["E307400"] = 70, ["E302700"] = 7,
		["E312401"] = 8, ["E310701"] = 30, ["E30BD00"] = 92, ["E307B00"] = 48,
	},
	[215] = {
		["E317B00"] = 78, ["C316D00"] = 1, ["C316B00"] = 1, ["E308501"] = 60, ["E307400"] = 104, ["E317700"] = 2,
		["E302600"] = 18, ["C305500"] = 1, ["E302402"] = 1, ["E310701"] = 24, ["E30BD00"] = 82,
	},
	[216] = {
		["E317B00"] = 20, ["C316D00"] = 1, ["E309700"] = 22, ["E307400"] = 128, ["E302600"] = 10, ["E30CD00"] = 100,
		["C30CA00"] = 1, ["C30CA01"] = 1, ["E310700"] = 16, ["E310701"] = 71, ["E000200"] = 8,
	},
	[217] = {
		["E305500"] = 36, ["E30CD00"] = 30, ["E309200"] = 12, ["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 108,
		["C308F00"] = 1, ["E303B00"] = 10, ["E302402"] = 16, ["E310701"] = 50, ["E30BD00"] = 4,
	},
	[218] = {
		["E309700"] = 58, ["E317600"] = 36, ["E307400"] = 32, ["E302600"] = 78, ["E309200"] = 2, ["E310700"] = 6,
		["C308F00"] = 1, ["E302402"] = 16, ["E310701"] = 78,
	},
	[219] = {
		["E317B00"] = 104, ["C316D00"] = 1, ["E305500"] = 41, ["E302700"] = 3, ["E302600"] = 9, ["E309200"] = 10,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 20, ["C308F00"] = 1, ["E310701"] = 3, ["E30BD00"] = 2,
	},
	[220] = {
		["E317B00"] = 126, ["C316D00"] = 1, ["E305500"] = 19, ["E302500"] = 32, ["E302700"] = 3, ["E302600"] = 9,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 19, ["E30BD00"] = 1, ["E000000"] = 6,
	},
	[221] = {
		["E302500"] = 33, ["E302700"] = 31, ["E302600"] = 26, ["E309200"] = 66, ["C30CA01"] = 1, ["E312701"] = 2,
		["E310700"] = 15, ["C308F00"] = 1, ["E302402"] = 34, ["E30BD00"] = 8,
	},
	[222] = {
		["E309700"] = 26, ["E302500"] = 40, ["E302700"] = 9, ["E317500"] = 5, ["E302600"] = 108, ["E310700"] = 24,
		["E30C800"] = 12, ["E310701"] = 16,
	},
	[223] = {
		["E317B00"] = 24, ["C316D00"] = 1, ["E302500"] = 29, ["E303D00"] = 16, ["E302600"] = 31, ["E30CD00"] = 26,
		["E309200"] = 10, ["C30CA00"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E310701"] = 44, ["E30BD00"] = 17,
	},
	[224] = {
		["E305400"] = 14, ["E302500"] = 86, ["E307400"] = 74, ["E302700"] = 3, ["E310700"] = 20, ["E30CA00"] = 10,
		["E310701"] = 16, ["E309C00"] = 12,
	},
	[225] = {
		["E305400"] = 34, ["E302500"] = 89, ["E307400"] = 54, ["E302700"] = 15, ["E302600"] = 7, ["E30C800"] = 1,
		["E310701"] = 10, ["E30BD00"] = 30,
	},
	[226] = {
		["E317B00"] = 64, ["C316D00"] = 1, ["E302500"] = 85, ["E307400"] = 88, ["E308000"] = 4, ["E302600"] = 10,
		["E310700"] = 11, ["E303A00"] = 12, ["E30BD00"] = 38,
	},
	[227] = {
		["E317B00"] = 2, ["C316D00"] = 1, ["E308501"] = 16, ["E302500"] = 27, ["E307400"] = 88, ["E302600"] = 72,
		["E312501"] = 4, ["E310701"] = 4, ["E30BD00"] = 34,
	},
	[228] = {
		["C316B00"] = 1, ["E305500"] = 65, ["E307400"] = 6, ["E303D00"] = 60, ["E317700"] = 58, ["E302600"] = 10,
		["E30CD00"] = 16, ["C30CA00"] = 1, ["C305500"] = 1, ["C303C00"] = 1, ["E30C800"] = 25, ["E30BD00"] = 82,
	},
	[229] = {
		["E305500"] = 66, ["E307400"] = 6, ["E303D00"] = 4, ["C307801"] = 1, ["E30CD00"] = 64, ["E309200"] = 48,
		["C30CA00"] = 1, ["C305500"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E310701"] = 6, ["E30BD00"] = 42,
		["E307B01"] = 12,
	},
	[230] = {
		["E309700"] = 84, ["E302500"] = 21, ["E307400"] = 88, ["E302700"] = 15, ["E317500"] = 10, ["E302600"] = 12,
		["E310700"] = 38, ["E30B500"] = 15,
	},
	[231] = {
		["C316B00"] = 1, ["E309700"] = 30, ["E307400"] = 64, ["E302700"] = 11, ["E317500"] = 9, ["E317700"] = 8,
		["E302600"] = 112, ["E310700"] = 42, ["E310701"] = 14,
	},
	[232] = {
		["E316A01"] = 30, ["E309700"] = 84, ["E307400"] = 18, ["E302700"] = 11, ["E302600"] = 104, ["E200006"] = 12,
		["E310700"] = 40, ["E310701"] = 4,
	},
	[233] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["E309700"] = 36, ["E307400"] = 110, ["E302600"] = 13, ["E30CD00"] = 18,
		["C30CA00"] = 1, ["E310700"] = 20, ["E302402"] = 3, ["E310701"] = 12,
	},
	[234] = {
		["E305500"] = 105, ["E317600"] = 4, ["E307400"] = 64, ["E302600"] = 42, ["C305500"] = 1, ["E310700"] = 54,
		["E30C800"] = 6, ["E310701"] = 112, ["E30BD00"] = 59,
	},
	[235] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["E309700"] = 114, ["E305400"] = 42, ["E302500"] = 21, ["E302600"] = 42,
		["E310700"] = 24, ["E302402"] = 52, ["E310701"] = 104,
	},
	[236] = {
		["E317B00"] = 4, ["C316D00"] = 1, ["E309700"] = 52, ["E305400"] = 42, ["E303D00"] = 68, ["E302600"] = 44,
		["C30CA01"] = 1, ["C303C00"] = 1, ["E310700"] = 24, ["E302402"] = 51, ["E30BD00"] = 112,
	},
	[237] = {
		["E309700"] = 14, ["C310700"] = 1, ["E305400"] = 42, ["E302500"] = 21, ["E303D00"] = 4, ["E302600"] = 62,
		["E309200"] = 10, ["C30CA01"] = 1, ["C303C00"] = 1, ["C308F00"] = 1, ["E302402"] = 4, ["E310701"] = 4,
	},
	[238] = {
		["E309700"] = 50, ["C310700"] = 1, ["E305400"] = 42, ["E302500"] = 21, ["E303D00"] = 2, ["E302600"] = 28,
		["E309200"] = 10, ["C303C00"] = 1, ["C308F00"] = 1, ["E302402"] = 4, ["E30C800"] = 20,
	},
	[239] = {
		["E317B00"] = 22, ["C316D00"] = 1, ["E309700"] = 18, ["E302500"] = 89, ["E307400"] = 22, ["E302600"] = 12,
		["C30CA01"] = 1, ["C305500"] = 1, ["E000703"] = 1, ["E310700"] = 15, ["E310701"] = 6,
	},
	[240] = {
		["E317B00"] = 16, ["C316D00"] = 1, ["E309700"] = 20, ["E307400"] = 30, ["C307801"] = 1, ["E302600"] = 62,
		["C305500"] = 1, ["E310700"] = 17, ["E310701"] = 10, ["E30B500"] = 1, ["E307B01"] = 24,
	},
	[241] = {
		["E317B00"] = 6, ["C316D00"] = 1, ["E305500"] = 3, ["E309700"] = 45, ["E302500"] = 71, ["E307400"] = 24,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 20, ["E30C800"] = 11, ["E310701"] = 5,
	},
	[242] = {
		["E305500"] = 2, ["E309700"] = 54, ["E307400"] = 24, ["C307801"] = 1, ["E302600"] = 27, ["E307100"] = 6,
		["C305500"] = 1, ["E310700"] = 10, ["C30AC00"] = 1, ["E310701"] = 34, ["E307B01"] = 24,
	},
	[243] = {
		["E305500"] = 69, ["E309700"] = 73, ["C310700"] = 1, ["E307400"] = 30, ["E303D00"] = 6, ["C307801"] = 1,
		["E30CD00"] = 4, ["C30CA00"] = 1, ["C305500"] = 1, ["E200008"] = 4, ["C303C00"] = 1, ["E310701"] = 6,
		["E307B01"] = 52,
	},
	[244] = {
		["E309700"] = 21, ["C310700"] = 1, ["E302500"] = 97, ["E307400"] = 36, ["E302700"] = 19, ["E302600"] = 6,
		["C30CA01"] = 1, ["E30C800"] = 1, ["E310701"] = 6, ["E30BD00"] = 4,
	},
	[245] = {
		["E317B00"] = 20, ["C316D00"] = 1, ["E309700"] = 22, ["E307400"] = 60, ["C307801"] = 1, ["E302600"] = 9,
		["E309200"] = 16, ["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 6, ["C308F00"] = 1, ["E30BD00"] = 19,
		["E307B01"] = 28,
	},
	[246] = {
		["E317B00"] = 12, ["C316D00"] = 1, ["E309700"] = 10, ["E305400"] = 98, ["E302700"] = 7, ["E302600"] = 70,
		["E30CD00"] = 14, ["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 13, ["E310701"] = 40,
	},
	[247] = {
		["E307400"] = 80, ["E302700"] = 93, ["C307801"] = 1, ["E302600"] = 56, ["E30CD00"] = 30, ["C30CA00"] = 1,
		["C305500"] = 1, ["E310700"] = 25, ["E30C800"] = 128, ["E30BD00"] = 40, ["E307B01"] = 8,
	},
	[248] = {
		["C307800"] = 1, ["E302700"] = 80, ["C307801"] = 1, ["E302600"] = 57, ["E30CD00"] = 2, ["E309200"] = 12,
		["C30CA00"] = 1, ["C305500"] = 1, ["E310700"] = 25, ["C308F00"] = 1, ["E30C800"] = 128, ["E307B00"] = 24,
		["E307B01"] = 58,
	},
	[249] = {
		["E317B00"] = 14, ["C316D00"] = 1, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 33, ["E309200"] = 116,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 24, ["C308F00"] = 1, ["E30C800"] = 92, ["E30BD00"] = 84,
		["E307B00"] = 54, ["E307B01"] = 28,
	},
	[250] = {
		["C307800"] = 1, ["E302500"] = 1, ["E302600"] = 10, ["E30CD00"] = 36, ["C30CA00"] = 1, ["C30CA01"] = 1,
		["E310700"] = 20, ["E302402"] = 2, ["E30C800"] = 12, ["E30BD00"] = 7, ["E307B00"] = 52,
	},
	[251] = {
		["E305500"] = 21, ["E302500"] = 7, ["E302600"] = 8, ["E30CD00"] = 36, ["E309200"] = 48, ["C30CA00"] = 1,
		["C30CA01"] = 1, ["C305500"] = 1, ["E310700"] = 5, ["C308F00"] = 1, ["E30C800"] = 11, ["E30BD00"] = 48,
	},
	[252] = {
		["E316D00"] = 8, ["E309700"] = 14, ["E308502"] = 14, ["C310700"] = 1, ["C307800"] = 1, ["C307801"] = 1,
		["E30CA03"] = 2, ["E30C800"] = 2, ["E310701"] = 2, ["E307B00"] = 50, ["E307B01"] = 92,
	},
	[253] = {
		["E316D00"] = 2, ["E316B01"] = 6, ["E302600"] = 23, ["E309200"] = 48, ["C305500"] = 1, ["E310700"] = 20,
		["C308F00"] = 1, ["E302402"] = 38, ["E30C800"] = 44, ["E310701"] = 8,
	},
	[254] = {
		["E305500"] = 4, ["C307800"] = 1, ["E302600"] = 14, ["E309200"] = 2, ["C305500"] = 1, ["E310700"] = 9,
		["C308F00"] = 1, ["E312501"] = 6, ["E302402"] = 40, ["E30BD00"] = 22, ["E307B00"] = 50,
	},
	[255] = {
		["E316B02"] = 8, ["E305500"] = 3, ["E302700"] = 43, ["E302600"] = 16, ["E309200"] = 12, ["C305500"] = 1,
		["E310700"] = 24, ["C308F00"] = 1, ["E302402"] = 34, ["E30BD00"] = 49,
	},
}

_M.routes["nocw"] = {
	[0] = {
		["E000703"] = 1, ["E000202"] = 4, ["E309200"] = 12, ["E302600"] = 10, ["E302700"] = 3, ["E302500"] = 1,
		["C308F00"] = 1, ["E303B00"] = 8, ["E305500"] = 15, ["C305500"] = 1,
	},
	[1] = {
		["E309C00"] = 2, ["E000202"] = 4, ["E309200"] = 12, ["E302600"] = 10, ["E302700"] = 11, ["E302500"] = 1,
		["C308F00"] = 1, ["E305500"] = 15, ["C305500"] = 1,
	},
	[2] = {
		["E309C00"] = 2, ["E000202"] = 4, ["E309200"] = 6, ["E302600"] = 10, ["E302700"] = 3, ["E302500"] = 1,
		["C308F00"] = 1, ["E309700"] = 14, ["E305500"] = 15, ["C305500"] = 1,
	},
	[3] = {
		["E309200"] = 4, ["E302600"] = 24, ["E302700"] = 3, ["E302500"] = 5, ["C308F00"] = 1, ["E308702"] = 1,
		["E305500"] = 15, ["E000701"] = 1, ["C305500"] = 1,
	},
	[4] = {
		["E309C00"] = 2, ["E309200"] = 2, ["E302600"] = 16, ["E302700"] = 3, ["E302500"] = 13, ["C308F00"] = 1,
		["E308702"] = 1, ["E305500"] = 17, ["E000701"] = 1, ["C305500"] = 1,
	},
	[5] = {
		["E309C00"] = 2, ["C303C00"] = 1, ["E302600"] = 6, ["E302700"] = 3, ["E302500"] = 23, ["E303D00"] = 2,
		["E305500"] = 7, ["C305500"] = 1,
	},
	[6] = {
		["E000703"] = 4, ["E309200"] = 2, ["E307B00"] = 60, ["C307801"] = 1, ["E302700"] = 15, ["E302500"] = 23,
		["C307800"] = 1, ["C308F00"] = 1, ["E309700"] = 74, ["E305500"] = 10, ["E307B01"] = 98, ["C305500"] = 1,
	},
	[7] = {
		["E309200"] = 2, ["E307B00"] = 20, ["E302600"] = 38, ["C307801"] = 1, ["E302700"] = 15, ["E302500"] = 63,
		["C307800"] = 1, ["C308F00"] = 1, ["E309700"] = 108, ["E305500"] = 14, ["E307B01"] = 26, ["C305500"] = 1,
	},
	[8] = {
		["E309200"] = 2, ["E307B00"] = 58, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 15, ["E302500"] = 25,
		["C307800"] = 1, ["C308F00"] = 1, ["E309700"] = 110, ["E305500"] = 14, ["E307B01"] = 52, ["C305500"] = 1,
	},
	[9] = {
		["E000703"] = 2, ["E309200"] = 4, ["E302600"] = 16, ["E302700"] = 3, ["E302500"] = 49, ["E305400"] = 8,
		["C308F00"] = 1, ["E309700"] = 12, ["E305500"] = 7, ["C305500"] = 1,
	},
	[10] = {
		["E000703"] = 3, ["E309200"] = 12, ["E302600"] = 18, ["E302700"] = 3, ["E302500"] = 51, ["E305400"] = 8,
		["C308F00"] = 1, ["E305500"] = 7, ["C305500"] = 1,
	},
	[11] = {
		["E000703"] = 3, ["E000202"] = 12, ["E309200"] = 12, ["E307B00"] = 18, ["E302600"] = 30, ["E302700"] = 3,
		["C307800"] = 1, ["E305400"] = 12, ["C308F00"] = 1, ["E305500"] = 7, ["C305500"] = 1,
	},
	[12] = {
		["E000703"] = 2, ["E309200"] = 2, ["E302600"] = 22, ["E302700"] = 2, ["E302500"] = 45, ["E305400"] = 10,
		["C308F00"] = 1, ["E303A00"] = 10, ["E305500"] = 9, ["C305500"] = 1,
	},
	[13] = {
		["E000703"] = 2, ["E309200"] = 2, ["E302600"] = 20, ["E302700"] = 3, ["E302500"] = 49, ["E305400"] = 10,
		["C308F00"] = 1, ["E303A00"] = 8, ["E305500"] = 7, ["C305500"] = 1,
	},
	[14] = {
		["E309200"] = 2, ["E302600"] = 14, ["E302500"] = 5, ["E305400"] = 54, ["C308F00"] = 1, ["E308700"] = 1,
		["E308702"] = 1, ["E309700"] = 14, ["E305500"] = 31, ["C305500"] = 1,
	},
	[15] = {
		["E309200"] = 2, ["E302500"] = 1, ["E305400"] = 54, ["C308F00"] = 1, ["E309700"] = 34, ["E305500"] = 31,
		["C305500"] = 1,
	},
	[16] = { ["E309200"] = 2, ["E302500"] = 71, ["E305400"] = 18, ["C308F00"] = 1, ["E305500"] = 31, ["C305500"] = 1 },
	[17] = {
		["E309200"] = 28, ["E307400"] = 8, ["E302500"] = 71, ["E305400"] = 10, ["C308F00"] = 1, ["E305500"] = 5,
		["C305500"] = 1,
	},
	[18] = {
		["E000703"] = 2, ["E309200"] = 28, ["E302600"] = 10, ["E302500"] = 37, ["E305400"] = 18, ["C308F00"] = 1,
		["E308700"] = 13, ["E308702"] = 11, ["E000701"] = 1,
	},
	[19] = {
		["E309200"] = 2, ["E302600"] = 10, ["E302500"] = 37, ["E305400"] = 18, ["C308F00"] = 1, ["E308700"] = 1,
		["E308702"] = 13, ["E309700"] = 10,
	},
	[20] = {
		["E000703"] = 4, ["E309200"] = 2, ["E302600"] = 1, ["E302700"] = 3, ["E305400"] = 18, ["C308F00"] = 1,
		["E308702"] = 1, ["E000701"] = 1,
	},
	[21] = {
		["E309200"] = 2, ["E307B00"] = 2, ["E302600"] = 9, ["E302700"] = 31, ["E302500"] = 27, ["C307800"] = 1,
		["E305400"] = 18, ["C308F00"] = 1, ["E309700"] = 28, ["E305500"] = 5, ["C305500"] = 1,
	},
	[22] = {
		["E309200"] = 2, ["E302600"] = 1, ["E302700"] = 3, ["E307400"] = 18, ["C308F00"] = 1, ["E308702"] = 1,
		["E305500"] = 10, ["E000701"] = 1, ["C305500"] = 1,
	},
	[23] = {
		["E302600"] = 14, ["E302700"] = 3, ["E307400"] = 2, ["E308700"] = 1, ["E308702"] = 3, ["E305500"] = 13,
		["E000701"] = 1, ["C305500"] = 1,
	},
	[24] = {
		["C303C00"] = 1, ["E309200"] = 2, ["E307B00"] = 12, ["E302600"] = 10, ["C307801"] = 1, ["C307800"] = 1,
		["E305400"] = 44, ["C308F00"] = 1, ["E303D00"] = 6, ["E305500"] = 1, ["E307B01"] = 26, ["C305500"] = 1,
	},
	[25] = {
		["C303C00"] = 1, ["E309200"] = 2, ["E307B00"] = 4, ["C307801"] = 1, ["E307400"] = 2, ["E302500"] = 50,
		["C307800"] = 1, ["C308F00"] = 1, ["E303D00"] = 16, ["E305500"] = 3, ["E307B01"] = 26, ["C305500"] = 1,
	},
	[26] = {
		["C303C00"] = 1, ["E309200"] = 2, ["C307801"] = 1, ["E307400"] = 2, ["E302500"] = 51, ["C308F00"] = 1,
		["E309700"] = 6, ["E303D00"] = 10, ["E305500"] = 32, ["E309300"] = 1, ["E307B01"] = 34, ["C305500"] = 1,
	},
	[27] = {
		["E000703"] = 6, ["E307B00"] = 48, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 8, ["C307800"] = 1,
		["E308702"] = 1, ["E305500"] = 5, ["E000701"] = 1, ["E307B01"] = 26, ["C305500"] = 1,
	},
	[28] = {
		["E000202"] = 4, ["E302600"] = 10, ["E302700"] = 2, ["E307400"] = 2, ["E302500"] = 7, ["E308700"] = 1,
		["E308702"] = 1, ["E305500"] = 7, ["C305500"] = 1,
	},
	[29] = {
		["E302600"] = 26, ["C307801"] = 1, ["E305400"] = 58, ["E308702"] = 1, ["E305500"] = 29, ["E307B01"] = 38,
		["C305500"] = 1,
	},
	[30] = {
		["E302600"] = 26, ["C307801"] = 1, ["E302500"] = 50, ["E305400"] = 8, ["E308702"] = 1, ["E305500"] = 29,
		["E307B01"] = 38, ["C305500"] = 1,
	},
	[31] = {
		["E307E00"] = 22, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 11, ["E302500"] = 50, ["E305400"] = 8,
		["E305500"] = 7, ["E308400"] = 6, ["E307B01"] = 38, ["C305500"] = 1,
	},
	[32] = {
		["E309200"] = 58, ["E302600"] = 69, ["C307801"] = 1, ["E302700"] = 3, ["E302500"] = 65, ["E305400"] = 6,
		["C308F00"] = 1, ["E309700"] = 41, ["E305500"] = 65, ["E307B01"] = 32, ["C305500"] = 1,
	},
	[33] = {
		["E000202"] = 6, ["E302600"] = 40, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 34, ["E302500"] = 7,
		["E305400"] = 30, ["E308702"] = 1, ["E307B01"] = 26, ["C305500"] = 1,
	},
	[34] = {
		["C303C00"] = 1, ["E309200"] = 38, ["E302600"] = 80, ["C307801"] = 1, ["E302500"] = 31, ["E305400"] = 44,
		["C308F00"] = 1, ["E309700"] = 23, ["E303D00"] = 40, ["E305500"] = 34, ["E307B01"] = 36, ["C305500"] = 1,
	},
	[35] = {
		["E000703"] = 2, ["E302600"] = 58, ["C307801"] = 1, ["E302700"] = 3, ["E302500"] = 30, ["E305400"] = 44,
		["E308700"] = 15, ["E309700"] = 22, ["E307B01"] = 44,
	},
	[36] = {
		["C303C00"] = 1, ["E309200"] = 36, ["E302600"] = 18, ["C307801"] = 1, ["E307400"] = 38, ["E302500"] = 8,
		["E305400"] = 26, ["C308F00"] = 1, ["E309700"] = 1, ["E303D00"] = 6, ["E307B01"] = 46,
	},
	[37] = {
		["E000703"] = 8, ["E309200"] = 10, ["E307B00"] = 28, ["E302600"] = 48, ["E302700"] = 7, ["C307800"] = 1,
		["E305400"] = 20, ["C308F00"] = 1, ["E308702"] = 1, ["E000701"] = 1,
	},
	[38] = {
		["C303C00"] = 1, ["E309200"] = 62, ["E307B00"] = 14, ["E302600"] = 10, ["C307801"] = 1, ["E307200"] = 20,
		["E302700"] = 2, ["C307800"] = 1, ["C308F00"] = 1, ["E303D00"] = 2, ["E305500"] = 39, ["E307B01"] = 90,
		["C305500"] = 1,
	},
	[39] = {
		["C303C00"] = 1, ["E309200"] = 12, ["E307B00"] = 14, ["E302600"] = 10, ["E307200"] = 2, ["E302700"] = 37,
		["E307400"] = 20, ["C307800"] = 1, ["C308F00"] = 1, ["E303D00"] = 8, ["E305500"] = 11, ["C305500"] = 1,
	},
	[40] = {
		["C303C00"] = 1, ["E309200"] = 2, ["E302700"] = 15, ["E307000"] = 26, ["E302500"] = 4, ["C308F00"] = 1,
		["E309700"] = 20, ["E303D00"] = 8, ["E305500"] = 7, ["C305500"] = 1,
	},
	[41] = { ["E302700"] = 3, ["E307400"] = 20, ["E302500"] = 10, ["E309700"] = 3, ["E305500"] = 3, ["C305500"] = 1 },
	[42] = {
		["E308000"] = 1, ["E302700"] = 29, ["E307400"] = 20, ["E302500"] = 9, ["E309700"] = 4, ["E305500"] = 17,
		["E000701"] = 1, ["C305500"] = 1,
	},
	[43] = { ["E307400"] = 2, ["E302500"] = 27, ["E309700"] = 4 },
	[44] = { ["E000200"] = 2, ["E302600"] = 10, ["E302700"] = 3, ["E302500"] = 7, ["E305500"] = 3, ["C305500"] = 1 },
	[45] = {
		["E309200"] = 8, ["E302600"] = 10, ["E302700"] = 2, ["E307400"] = 2, ["E302500"] = 3, ["C308F00"] = 1,
		["E308700"] = 1, ["E308702"] = 3,
	},
	[46] = {
		["E309200"] = 16, ["E302600"] = 4, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 24, ["E302500"] = 24,
		["E305400"] = 120, ["C308F00"] = 1, ["E307B01"] = 20,
	},
	[47] = {
		["E309200"] = 38, ["E307B00"] = 76, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 9, ["E307400"] = 2,
		["E302500"] = 36, ["C307800"] = 1, ["C308F00"] = 1, ["E309700"] = 16, ["E307B01"] = 24,
	},
	[48] = {
		["E309200"] = 32, ["E307B00"] = 76, ["E302600"] = 30, ["C307801"] = 1, ["E302700"] = 11, ["E307400"] = 2,
		["E302500"] = 37, ["C307800"] = 1, ["C308F00"] = 1, ["E307B01"] = 18,
	},
	[49] = {
		["E309200"] = 32, ["E302600"] = 5, ["E302700"] = 9, ["E307400"] = 18, ["E302500"] = 24, ["E305400"] = 126,
		["C308F00"] = 1, ["E308702"] = 1, ["E000701"] = 1,
	},
	[50] = {
		["E000703"] = 2, ["E302700"] = 3, ["E305400"] = 38, ["E308702"] = 3, ["E305500"] = 45, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[51] = {
		["E000703"] = 2, ["E309200"] = 8, ["E302600"] = 5, ["E302700"] = 3, ["E305400"] = 38, ["C308F00"] = 1,
		["E305500"] = 35, ["C305500"] = 1,
	},
	[52] = {
		["E302600"] = 12, ["E307300"] = 6, ["E302500"] = 31, ["E308702"] = 1, ["E309700"] = 20, ["E305500"] = 3,
		["E000701"] = 1, ["C305500"] = 1,
	},
	[53] = { ["E309200"] = 2, ["E302600"] = 1, ["E307300"] = 6, ["E308000"] = 2, ["E302500"] = 7, ["C308F00"] = 1 },
	[54] = {
		["C303C00"] = 1, ["E309200"] = 14, ["E302600"] = 52, ["E307300"] = 6, ["E302700"] = 27, ["E302500"] = 55,
		["C308F00"] = 1, ["E303D00"] = 20, ["E000701"] = 1,
	},
	[55] = {
		["C303C00"] = 1, ["E309200"] = 14, ["E302600"] = 10, ["E307300"] = 6, ["C307801"] = 1, ["E302700"] = 27,
		["E302500"] = 60, ["C308F00"] = 1, ["E303D00"] = 20, ["E000701"] = 1, ["E307B01"] = 32,
	},
	[56] = {
		["E309200"] = 58, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 59, ["E307400"] = 4, ["E302500"] = 18,
		["C308F00"] = 1, ["E305500"] = 15, ["E000701"] = 1, ["E307B01"] = 76, ["C305500"] = 1,
	},
	[57] = {
		["E309200"] = 4, ["E302600"] = 10, ["E302700"] = 101, ["E307000"] = 4, ["E302500"] = 57, ["C308F00"] = 1,
		["E305500"] = 3, ["E000701"] = 1, ["C305500"] = 1,
	},
	[58] = {
		["C303C00"] = 1, ["E302600"] = 30, ["C307801"] = 1, ["E302700"] = 3, ["E307000"] = 4, ["E302500"] = 18,
		["E308702"] = 19, ["E303D00"] = 10, ["E305500"] = 17, ["E307B01"] = 128, ["C305500"] = 1,
	},
	[59] = {
		["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 45, ["E307000"] = 4, ["E302500"] = 18, ["E308702"] = 1,
		["E305500"] = 2, ["E307B01"] = 76, ["C305500"] = 1,
	},
	[60] = {
		["E000703"] = 1, ["E309200"] = 30, ["E302600"] = 68, ["E302700"] = 7, ["E302500"] = 3, ["E305400"] = 42,
		["C308F00"] = 1, ["E309700"] = 2, ["E305500"] = 7, ["C305500"] = 1,
	},
	[61] = {
		["C303C00"] = 1, ["E309200"] = 48, ["E302600"] = 36, ["E302700"] = 11, ["E302500"] = 29, ["E305400"] = 72,
		["C308F00"] = 1, ["E308702"] = 3, ["E303D00"] = 12, ["E305500"] = 22, ["C305500"] = 1,
	},
	[62] = {
		["E307701"] = 22, ["E302600"] = 14, ["E302700"] = 3, ["E302500"] = 27, ["E305400"] = 52, ["E305500"] = 19,
		["C305500"] = 1,
	},
	[63] = {
		["C303C00"] = 1, ["E309200"] = 38, ["E302600"] = 6, ["E302700"] = 43, ["E302500"] = 58, ["E305400"] = 72,
		["C308F00"] = 1, ["E309700"] = 8, ["E303D00"] = 8, ["E305500"] = 3, ["C305500"] = 1,
	},
	[64] = {
		["E302600"] = 7, ["C307801"] = 1, ["E302700"] = 3, ["E302500"] = 21, ["E305400"] = 72, ["E305500"] = 19,
		["E307B01"] = 10, ["C305500"] = 1,
	},
	[65] = {
		["E302600"] = 7, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 20, ["E302500"] = 9, ["E305400"] = 52,
		["E305500"] = 29, ["E307B01"] = 22, ["C305500"] = 1,
	},
	[66] = {
		["E307701"] = 2, ["E302600"] = 8, ["E302700"] = 3, ["E302500"] = 33, ["E305400"] = 72, ["E305500"] = 29,
		["C305500"] = 1,
	},
	[67] = {
		["C303C00"] = 1, ["E302600"] = 10, ["C307801"] = 1, ["E302500"] = 21, ["E305400"] = 72, ["E303D00"] = 6,
		["E305500"] = 10, ["E307B01"] = 10, ["C305500"] = 1,
	},
	[68] = {
		["E307701"] = 2, ["E302600"] = 68, ["E302700"] = 25, ["E307400"] = 18, ["E305400"] = 16, ["E308702"] = 1,
		["E305500"] = 17, ["C305500"] = 1,
	},
	[69] = {
		["E309200"] = 2, ["E307B00"] = 36, ["E302600"] = 22, ["E302700"] = 11, ["E307400"] = 18, ["E302500"] = 7,
		["C307800"] = 1, ["E305400"] = 16, ["C308F00"] = 1, ["E305500"] = 29, ["C305500"] = 1,
	},
	[70] = {
		["E309200"] = 2, ["E302600"] = 14, ["E302700"] = 11, ["E305400"] = 90, ["C308F00"] = 1, ["E305500"] = 29,
		["C305500"] = 1,
	},
	[71] = { ["E302600"] = 6, ["E302500"] = 56, ["E305400"] = 34, ["E308400"] = 4 },
	[72] = { ["E000703"] = 2, ["E302600"] = 6, ["E302700"] = 2, ["E305400"] = 90, ["E305500"] = 3, ["C305500"] = 1 },
	[73] = { ["E000703"] = 2, ["E302600"] = 7, ["E307400"] = 14, ["E305400"] = 78, ["E305500"] = 2, ["C305500"] = 1 },
	[74] = { ["E000703"] = 2, ["E302600"] = 7, ["E307400"] = 14, ["E305400"] = 78, ["E305500"] = 2, ["C305500"] = 1 },
	[75] = {
		["E309200"] = 16, ["E302600"] = 7, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 72, ["E302500"] = 18,
		["E305400"] = 74, ["C308F00"] = 1, ["E305500"] = 21, ["E307B01"] = 8, ["C305500"] = 1,
	},
	[76] = {
		["E309200"] = 26, ["E302600"] = 16, ["C307801"] = 1, ["E302700"] = 9, ["E307400"] = 84, ["E302500"] = 18,
		["E305400"] = 62, ["C308F00"] = 1, ["E305500"] = 7, ["E307B01"] = 14, ["C305500"] = 1,
	},
	[77] = {
		["E309200"] = 32, ["E307B00"] = 20, ["E302600"] = 10, ["E302700"] = 3, ["E307000"] = 22, ["E307400"] = 86,
		["E302500"] = 56, ["C307800"] = 1, ["C308F00"] = 1, ["E305500"] = 7, ["C305500"] = 1,
	},
	[78] = {
		["E309200"] = 120, ["E307B00"] = 32, ["E302700"] = 13, ["E307400"] = 36, ["E302500"] = 3, ["C307800"] = 1,
		["E305400"] = 22, ["C308F00"] = 1, ["E308702"] = 3, ["E305500"] = 7, ["C305500"] = 1,
	},
	[79] = {
		["E309200"] = 82, ["E302600"] = 8, ["E302700"] = 35, ["E307400"] = 4, ["E302500"] = 1, ["E305400"] = 22,
		["C308F00"] = 1, ["E309700"] = 44, ["E305500"] = 45, ["C305500"] = 1,
	},
	[80] = {
		["E309200"] = 98, ["E307B00"] = 4, ["E302700"] = 37, ["E302500"] = 3, ["C307800"] = 1, ["C308F00"] = 1,
		["E309700"] = 64, ["E305500"] = 29, ["E000701"] = 1, ["C305500"] = 1,
	},
	[81] = {
		["E309200"] = 98, ["E302600"] = 12, ["E302700"] = 35, ["E307400"] = 12, ["E302500"] = 1, ["E305400"] = 14,
		["C308F00"] = 1, ["E309700"] = 40, ["E305500"] = 29, ["C305500"] = 1,
	},
	[82] = {
		["E309200"] = 54, ["E307B00"] = 6, ["E302600"] = 9, ["E302700"] = 18, ["E307400"] = 40, ["E302500"] = 59,
		["C307800"] = 1, ["E305400"] = 18, ["C308F00"] = 1, ["E309700"] = 32, ["C305500"] = 1,
	},
	[83] = {
		["E000703"] = 1, ["E302600"] = 10, ["E307300"] = 11, ["E302700"] = 19, ["E305400"] = 14, ["E309700"] = 44,
		["E305500"] = 5, ["E000701"] = 3, ["C305500"] = 1,
	},
	[84] = {
		["C303C00"] = 1, ["E309200"] = 38, ["E302600"] = 10, ["E302700"] = 3, ["E302500"] = 1, ["E305400"] = 24,
		["C308F00"] = 1, ["E309700"] = 56, ["E303D00"] = 2, ["E000701"] = 1,
	},
	[85] = {
		["E302600"] = 10, ["E302700"] = 71, ["E302500"] = 1, ["E305400"] = 24, ["E308702"] = 1, ["E309700"] = 66,
		["E305500"] = 3, ["E000701"] = 1, ["C305500"] = 1,
	},
	[86] = {
		["C303C00"] = 1, ["E307B00"] = 4, ["E302600"] = 10, ["E302700"] = 67, ["E000500"] = 12, ["E302500"] = 13,
		["C307800"] = 1, ["E309700"] = 48, ["E303D00"] = 2, ["E305500"] = 3, ["C305500"] = 1,
	},
	[87] = {
		["E000703"] = 4, ["C303C00"] = 1, ["E302600"] = 44, ["E302700"] = 3, ["E302500"] = 7, ["E309700"] = 40,
		["E303D00"] = 2, ["E305500"] = 19, ["E000701"] = 1, ["C305500"] = 1,
	},
	[88] = {
		["E307B00"] = 4, ["E302600"] = 12, ["E307300"] = 1, ["E302700"] = 3, ["E307400"] = 12, ["C307800"] = 1,
		["E309700"] = 67, ["E305500"] = 25, ["E309300"] = 4, ["C305500"] = 1,
	},
	[89] = {
		["E307B00"] = 30, ["E302600"] = 46, ["E307300"] = 3, ["E307200"] = 10, ["E302700"] = 23, ["C307800"] = 1,
		["E303A00"] = 8, ["E305500"] = 19, ["C305500"] = 1,
	},
	[90] = {
		["E302600"] = 2, ["E307300"] = 1, ["E302700"] = 3, ["E307400"] = 12, ["E305500"] = 5, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[91] = { ["E302600"] = 9, ["E302700"] = 3, ["E308702"] = 7, ["E305500"] = 5, ["C305500"] = 1 },
	[92] = {
		["E302600"] = 6, ["E302700"] = 5, ["E307400"] = 10, ["E305400"] = 104, ["E305500"] = 3, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[93] = { ["E302600"] = 14, ["E302700"] = 3, ["E308700"] = 1, ["E308702"] = 1, ["E305500"] = 5, ["C305500"] = 1 },
	[94] = { ["E302600"] = 12, ["E302700"] = 3, ["E302500"] = 1, ["E308702"] = 1, ["E305500"] = 7, ["C305500"] = 1 },
	[95] = {
		["C303C00"] = 1, ["E302600"] = 42, ["E302700"] = 3, ["E302500"] = 1, ["E308F00"] = 12, ["E308702"] = 1,
		["E303D00"] = 10, ["E305500"] = 9, ["E000701"] = 1, ["C305500"] = 1,
	},
	[96] = {
		["C303C00"] = 1, ["E307B00"] = 36, ["E302600"] = 3, ["E302700"] = 3, ["E302500"] = 1, ["C307800"] = 1,
		["E303D00"] = 12, ["E305500"] = 13, ["C305500"] = 1,
	},
	[97] = { ["E302600"] = 12, ["E302700"] = 3, ["E308702"] = 5, ["E305500"] = 3, ["E000701"] = 1, ["C305500"] = 1 },
	[98] = {
		["C303C00"] = 1, ["E307E00"] = 16, ["E307B00"] = 2, ["E302600"] = 18, ["E302500"] = 1, ["C307800"] = 1,
		["E308702"] = 3, ["E303D00"] = 12, ["E305500"] = 15, ["E000701"] = 1, ["C305500"] = 1,
	},
	[99] = {
		["C303C00"] = 1, ["E307B00"] = 34, ["C307800"] = 1, ["E305400"] = 2, ["E308700"] = 1, ["E308702"] = 3,
		["E303D00"] = 12, ["E305500"] = 15, ["E000701"] = 1, ["C305500"] = 1,
	},
	[100] = {
		["C303C00"] = 1, ["E307B00"] = 34, ["E302600"] = 6, ["C307800"] = 1, ["E308F00"] = 8, ["E305400"] = 2,
		["E303D00"] = 10, ["E305500"] = 7, ["E000701"] = 1, ["C305500"] = 1,
	},
	[101] = {
		["C303C00"] = 1, ["E307802"] = 3, ["E307B00"] = 34, ["E302600"] = 3, ["C307800"] = 1, ["E308F00"] = 8,
		["E305400"] = 2, ["E303D00"] = 10, ["E305500"] = 7, ["E000701"] = 1, ["C305500"] = 1,
	},
	[102] = {
		["E307B00"] = 8, ["E302600"] = 9, ["E302700"] = 3, ["C307800"] = 1, ["E308F00"] = 14, ["E305400"] = 20,
		["E309700"] = 22, ["E305500"] = 4, ["E000701"] = 1, ["C305500"] = 1,
	},
	[103] = {
		["E309200"] = 2, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 2, ["E305400"] = 26, ["C308F00"] = 1,
		["E308702"] = 1, ["E305500"] = 37, ["E307B01"] = 2, ["C305500"] = 1,
	},
	[104] = {
		["E000703"] = 2, ["E307701"] = 8, ["E309200"] = 78, ["E302700"] = 3, ["E307400"] = 34, ["E302500"] = 1,
		["E305400"] = 20, ["C308F00"] = 1,
	},
	[105] = {
		["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 19, ["E307400"] = 28, ["E302500"] = 7, ["E305400"] = 26,
		["E309700"] = 50, ["E307B01"] = 10,
	},
	[106] = {
		["C307801"] = 1, ["E302700"] = 21, ["E307400"] = 26, ["E305400"] = 28, ["E308702"] = 1, ["E307700"] = 10,
		["E309700"] = 52, ["E308400"] = 6, ["E307B01"] = 6,
	},
	[107] = { ["E302600"] = 5, ["E305500"] = 12, ["C305500"] = 1 },
	[108] = {
		["E309200"] = 2, ["E302600"] = 16, ["E302700"] = 2, ["E307400"] = 12, ["E305400"] = 26, ["C308F00"] = 1,
		["E308702"] = 1, ["E309700"] = 8, ["E305500"] = 45, ["C305500"] = 1,
	},
	[109] = {
		["C303C00"] = 1, ["E309200"] = 6, ["E307B00"] = 24, ["E302600"] = 7, ["E307400"] = 38, ["E302500"] = 5,
		["C307800"] = 1, ["C308F00"] = 1, ["E308702"] = 7, ["E303D00"] = 72, ["E305500"] = 21, ["C305500"] = 1,
	},
	[110] = {
		["E302401"] = 2, ["E309200"] = 2, ["E302700"] = 7, ["E305400"] = 4, ["C308F00"] = 1, ["E308700"] = 1,
		["E305500"] = 6, ["E000701"] = 1, ["C305500"] = 1,
	},
	[111] = {
		["E309200"] = 4, ["E307B00"] = 132, ["E302600"] = 3, ["E302700"] = 3, ["E307400"] = 80, ["C307800"] = 1,
		["E305400"] = 12, ["C308F00"] = 1, ["E000701"] = 1,
	},
	[112] = {
		["E309200"] = 2, ["E302600"] = 1, ["E302700"] = 3, ["E302500"] = 5, ["E305400"] = 4, ["C308F00"] = 1,
		["E305500"] = 7, ["C305500"] = 1,
	},
	[113] = {
		["E309200"] = 2, ["E302600"] = 2, ["E302700"] = 3, ["E305400"] = 6, ["C308F00"] = 1, ["E308702"] = 1,
		["E305500"] = 7, ["E000701"] = 1, ["C305500"] = 1,
	},
	[114] = {
		["C303C00"] = 1, ["E000202"] = 12, ["E309200"] = 148, ["E302600"] = 44, ["E302700"] = 17, ["E305400"] = 12,
		["C308F00"] = 1, ["E308401"] = 6, ["E303D00"] = 14, ["E305500"] = 3, ["C305500"] = 1,
	},
	[115] = {
		["E000703"] = 1, ["E302700"] = 3, ["E302500"] = 5, ["E305400"] = 4, ["E305500"] = 9, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[116] = { ["E302700"] = 3, ["E302500"] = 10, ["E305500"] = 7, ["E000701"] = 3, ["C305500"] = 1 },
	[117] = { ["E302700"] = 3, ["E302500"] = 10, ["E305500"] = 7, ["E000701"] = 3, ["C305500"] = 1 },
	[118] = { ["E309200"] = 2, ["E302700"] = 34, ["E302500"] = 10, ["C308F00"] = 1, ["E305500"] = 1, ["C305500"] = 1 },
	[119] = {
		["C303C00"] = 1, ["E302600"] = 54, ["E302700"] = 19, ["E302500"] = 12, ["E308700"] = 1, ["E308702"] = 1,
		["E309700"] = 4, ["E303D00"] = 8, ["C305500"] = 1,
	},
	[120] = {
		["E302600"] = 20, ["E302700"] = 85, ["E302500"] = 1, ["E308700"] = 3, ["E308702"] = 1, ["E303A00"] = 2,
		["C305500"] = 1,
	},
	[121] = {
		["E309200"] = 34, ["E302600"] = 10, ["E302700"] = 17, ["E302500"] = 15, ["C308F00"] = 1, ["E308702"] = 1,
		["E305500"] = 16, ["E000701"] = 1, ["C305500"] = 1,
	},
	[122] = {
		["E309200"] = 34, ["E302600"] = 8, ["E302700"] = 17, ["E302500"] = 1, ["C308F00"] = 1, ["E309700"] = 18,
		["E305500"] = 16, ["C305500"] = 1,
	},
	[123] = {
		["C303C00"] = 1, ["E307B00"] = 80, ["E302600"] = 36, ["E302700"] = 2, ["E307400"] = 118, ["E302500"] = 19,
		["C307800"] = 1, ["E309700"] = 8, ["E303D00"] = 4, ["E305500"] = 38, ["C305500"] = 1,
	},
	[124] = {
		["C303C00"] = 1, ["E309200"] = 48, ["E307B00"] = 12, ["E302600"] = 37, ["C307801"] = 1, ["E302700"] = 5,
		["E307400"] = 54, ["C307800"] = 1, ["C308F00"] = 1, ["E303D00"] = 8, ["E305500"] = 83, ["E307B01"] = 20,
		["C305500"] = 1,
	},
	[125] = {
		["E309200"] = 88, ["E307B00"] = 2, ["E302600"] = 20, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 30,
		["C307800"] = 1, ["C308F00"] = 1, ["E309700"] = 50, ["E305500"] = 115, ["E307B01"] = 4, ["C305500"] = 1,
	},
	[126] = {
		["E302401"] = 1, ["C303C00"] = 1, ["E309200"] = 38, ["E307B00"] = 10, ["E302600"] = 31, ["C307801"] = 1,
		["E307400"] = 56, ["C307800"] = 1, ["C308F00"] = 1, ["E303D00"] = 10, ["E305500"] = 131, ["E307B01"] = 24,
		["C305500"] = 1,
	},
	[127] = {
		["E302401"] = 1, ["C303C00"] = 1, ["E309200"] = 52, ["E302600"] = 36, ["E302700"] = 41, ["E307400"] = 30,
		["C308F00"] = 1, ["E309700"] = 14, ["E303D00"] = 6, ["E305500"] = 131, ["C305500"] = 1,
	},
	[128] = { ["E302600"] = 2, ["E302500"] = 1, ["E308F00"] = 4, ["E305500"] = 7, ["C305500"] = 1 },
	[129] = {
		["E302600"] = 12, ["E302700"] = 3, ["E307400"] = 30, ["E302500"] = 19, ["E308700"] = 1, ["E308702"] = 1,
		["E309700"] = 10, ["E305500"] = 3, ["C305500"] = 1,
	},
	[130] = {
		["E309200"] = 2, ["E302600"] = 12, ["E302700"] = 2, ["E307400"] = 26, ["E302500"] = 23, ["C308F00"] = 1,
		["E308700"] = 1, ["E308702"] = 1, ["E309700"] = 10, ["C305500"] = 1,
	},
	[131] = {
		["C303C00"] = 1, ["E302600"] = 4, ["E302700"] = 43, ["E307400"] = 26, ["E302500"] = 18, ["E308702"] = 1,
		["E309700"] = 24, ["E303D00"] = 38,
	},
	[132] = {
		["E309200"] = 4, ["E302600"] = 4, ["E302700"] = 31, ["E302500"] = 18, ["E305400"] = 26, ["C308F00"] = 1,
		["E308702"] = 1, ["E309700"] = 24, ["E000701"] = 1, ["C305500"] = 1,
	},
	[133] = {
		["E000703"] = 6, ["E302600"] = 4, ["E302700"] = 13, ["E302500"] = 18, ["E305400"] = 26, ["E305500"] = 3,
		["E000701"] = 1, ["C305500"] = 1,
	},
	[134] = { ["E302600"] = 9, ["E302700"] = 1, ["E302500"] = 14, ["E305400"] = 26, ["E309700"] = 24 },
	[135] = {
		["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 1, ["E302500"] = 7, ["E305400"] = 26, ["E308702"] = 1,
		["E309700"] = 2, ["E307B01"] = 22,
	},
	[136] = {
		["E000703"] = 2, ["E309200"] = 44, ["E302600"] = 9, ["C307801"] = 1, ["E302700"] = 3, ["C308F00"] = 1,
		["E309700"] = 10, ["E305500"] = 33, ["E000701"] = 21, ["E307B01"] = 50, ["C305500"] = 1,
	},
	[137] = {
		["E309200"] = 4, ["E302600"] = 2, ["E302700"] = 5, ["C308F00"] = 1, ["E309700"] = 2, ["E305500"] = 1,
		["C305500"] = 1,
	},
	[138] = {
		["E302600"] = 6, ["E302700"] = 13, ["E307400"] = 2, ["E302500"] = 1, ["E305400"] = 30, ["E308702"] = 9,
		["E305500"] = 3, ["E000701"] = 1, ["C305500"] = 1,
	},
	[139] = {
		["E000703"] = 4, ["C303C00"] = 1, ["E302600"] = 2, ["E302700"] = 2, ["E309700"] = 2, ["E303D00"] = 10,
		["E305500"] = 2, ["C305500"] = 1,
	},
	[140] = {
		["E000703"] = 8, ["C303C00"] = 1, ["E302600"] = 2, ["E309700"] = 2, ["E303D00"] = 10, ["E305500"] = 5,
		["C305500"] = 1,
	},
	[141] = {
		["C303C00"] = 1, ["E302600"] = 2, ["E302700"] = 2, ["E309700"] = 2, ["E303D00"] = 10, ["E305500"] = 38,
		["C305500"] = 1,
	},
	[142] = { ["E302600"] = 7, ["E302700"] = 3, ["E307400"] = 6, ["E305400"] = 26, ["E305500"] = 25, ["C305500"] = 1 },
	[143] = {
		["E302401"] = 1, ["E302600"] = 10, ["E307400"] = 30, ["E302500"] = 7, ["E305400"] = 2, ["E309700"] = 16,
		["E305500"] = 3, ["C305500"] = 1,
	},
	[144] = {
		["E302401"] = 1, ["E302600"] = 4, ["E305400"] = 2, ["E309700"] = 58, ["E305500"] = 3, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[145] = {
		["E302401"] = 1, ["E302600"] = 4, ["E302700"] = 5, ["E305400"] = 2, ["E309700"] = 30, ["E305500"] = 27,
		["C305500"] = 1,
	},
	[146] = {
		["E302401"] = 1, ["E302600"] = 4, ["E302700"] = 5, ["E305400"] = 2, ["E309700"] = 30, ["E305500"] = 27,
		["C305500"] = 1,
	},
	[147] = {
		["E302401"] = 1, ["E302600"] = 4, ["E305400"] = 2, ["E309700"] = 58, ["E305500"] = 3, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[148] = {
		["C303C00"] = 1, ["E309200"] = 2, ["E302600"] = 4, ["E305400"] = 2, ["C308F00"] = 1, ["E309700"] = 58,
		["E303D00"] = 14, ["E305500"] = 3, ["C305500"] = 1,
	},
	[149] = {
		["E302600"] = 2, ["C307801"] = 1, ["E302700"] = 5, ["E307F01"] = 10, ["E307400"] = 16, ["E305400"] = 58,
		["E305500"] = 3, ["E000701"] = 1, ["E307B01"] = 8, ["C305500"] = 1,
	},
	[150] = {
		["E302600"] = 4, ["E307300"] = 1, ["E302400"] = 2, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 34,
		["E305400"] = 46, ["E000701"] = 1, ["E307B01"] = 12, ["C305500"] = 1,
	},
	[151] = {
		["E302600"] = 4, ["C307801"] = 1, ["E302700"] = 9, ["E307400"] = 36, ["E302500"] = 9, ["E305400"] = 46,
		["E309700"] = 26, ["E305500"] = 3, ["E307B01"] = 2, ["C305500"] = 1,
	},
	[152] = {
		["C303C00"] = 1, ["E309200"] = 28, ["E307B00"] = 48, ["E302600"] = 20, ["C307801"] = 1, ["E307400"] = 50,
		["C307800"] = 1, ["E305400"] = 46, ["C308F00"] = 1, ["E303A00"] = 4, ["E303D00"] = 8, ["E307B01"] = 54,
		["C305500"] = 1,
	},
	[153] = {
		["C303C00"] = 1, ["E307B00"] = 56, ["E302600"] = 10, ["E302700"] = 27, ["E307400"] = 50, ["C307800"] = 1,
		["E305400"] = 46, ["E303A00"] = 2, ["E303D00"] = 4, ["C309300"] = 1, ["E30A100"] = 38, ["C305500"] = 1,
	},
	[154] = {
		["E307B00"] = 62, ["E302600"] = 48, ["E302700"] = 13, ["E307400"] = 20, ["E302500"] = 25, ["C307800"] = 1,
		["E305400"] = 46, ["E309700"] = 42, ["E305500"] = 21, ["C305500"] = 1,
	},
	[155] = {
		["E307B00"] = 2, ["E302400"] = 2, ["E302700"] = 23, ["E307400"] = 12, ["E302500"] = 1, ["C307800"] = 1,
		["E305400"] = 46, ["E305500"] = 17, ["E000701"] = 1, ["C305500"] = 1,
	},
	[156] = {
		["C303C00"] = 1, ["E309200"] = 16, ["E302600"] = 4, ["C307801"] = 1, ["E302700"] = 9, ["E302500"] = 1,
		["C308F00"] = 1, ["E309700"] = 4, ["E303D00"] = 2, ["E000701"] = 5, ["E307B01"] = 20,
	},
	[157] = {
		["E307B00"] = 2, ["E302400"] = 4, ["E302700"] = 23, ["E307400"] = 12, ["E302500"] = 1, ["C307800"] = 1,
		["E305400"] = 46, ["E305500"] = 15, ["E000701"] = 1, ["C305500"] = 1,
	},
	[158] = {
		["E309200"] = 12, ["E307B00"] = 4, ["E302600"] = 12, ["E302700"] = 13, ["E307400"] = 12, ["E302500"] = 1,
		["C307800"] = 1, ["E305400"] = 46, ["C308F00"] = 1, ["E305500"] = 3, ["C305500"] = 1,
	},
	[159] = {
		["E309200"] = 12, ["E302600"] = 9, ["E302400"] = 4, ["C307801"] = 1, ["E302700"] = 23, ["E307000"] = 8,
		["C308F00"] = 1, ["E309700"] = 30, ["E305500"] = 3, ["E307B01"] = 14, ["C305500"] = 1,
	},
	[160] = {
		["E309200"] = 12, ["E302600"] = 5, ["E302400"] = 1, ["C307801"] = 1, ["E302700"] = 27, ["E307000"] = 12,
		["C308F00"] = 1, ["E309700"] = 34, ["E305500"] = 21, ["E307B01"] = 10, ["C305500"] = 1,
	},
	[161] = {
		["E309200"] = 10, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 13, ["E302500"] = 9, ["C308F00"] = 1,
		["E309700"] = 52, ["E305500"] = 33, ["E307B01"] = 6, ["C305500"] = 1,
	},
	[162] = {
		["E309200"] = 14, ["E307B00"] = 14, ["E302700"] = 12, ["E307400"] = 14, ["E302500"] = 1, ["C307800"] = 1,
		["E305400"] = 34, ["C308F00"] = 1, ["E309700"] = 14, ["E305500"] = 30, ["C305500"] = 1,
	},
	[163] = {
		["E309200"] = 8, ["E307B00"] = 14, ["E302400"] = 1, ["E302700"] = 2, ["E307400"] = 14, ["E302500"] = 1,
		["C307800"] = 1, ["E305400"] = 34, ["C308F00"] = 1, ["E305500"] = 11, ["C305500"] = 1,
	},
	[164] = {
		["E000703"] = 1, ["E309200"] = 6, ["E302600"] = 30, ["E302700"] = 3, ["E302500"] = 24, ["C308F00"] = 1,
		["E309700"] = 44, ["E305500"] = 29, ["E000701"] = 1, ["C305500"] = 1,
	},
	[165] = {
		["E309200"] = 78, ["E302600"] = 34, ["C307801"] = 1, ["E302700"] = 35, ["E307400"] = 68, ["E302500"] = 55,
		["E305400"] = 62, ["C308F00"] = 1, ["E305500"] = 2, ["E307B01"] = 4, ["C305500"] = 1,
	},
	[166] = {
		["C303C00"] = 1, ["E309200"] = 66, ["C307801"] = 1, ["E302700"] = 39, ["E307400"] = 130, ["E302500"] = 55,
		["C308F00"] = 1, ["E303D00"] = 18, ["E305500"] = 13, ["E307B01"] = 4, ["C305500"] = 1,
	},
	[167] = {
		["C303C00"] = 1, ["E309200"] = 66, ["E307B00"] = 46, ["E302600"] = 2, ["C307801"] = 1, ["E302700"] = 39,
		["E302500"] = 47, ["C307800"] = 1, ["C308F00"] = 1, ["E303D00"] = 16, ["E000701"] = 1, ["E307B01"] = 90,
	},
	[168] = {
		["C303C00"] = 1, ["E307100"] = 10, ["E309200"] = 66, ["E302600"] = 10, ["E302700"] = 35, ["E307400"] = 132,
		["E302500"] = 37, ["C308F00"] = 1, ["E308702"] = 3, ["E303D00"] = 20, ["C305500"] = 1,
	},
	[169] = { ["E309200"] = 16, ["E302700"] = 3, ["C308F00"] = 1, ["E305500"] = 5, ["E000701"] = 1, ["C305500"] = 1 },
	[170] = {
		["E302600"] = 3, ["E302700"] = 3, ["E307400"] = 130, ["E302500"] = 1, ["E305400"] = 10, ["E309700"] = 20,
		["E305500"] = 35, ["C305500"] = 1,
	},
	[171] = {
		["E309200"] = 2, ["E302700"] = 2, ["E302500"] = 1, ["E305400"] = 4, ["C308F00"] = 1, ["E309700"] = 11,
		["E305500"] = 5, ["C305500"] = 1,
	},
	[172] = {
		["E309200"] = 2, ["E302700"] = 2, ["E302500"] = 1, ["E305400"] = 4, ["C308F00"] = 1, ["E309700"] = 11,
		["E305500"] = 5, ["C305500"] = 1,
	},
	[173] = {
		["E309200"] = 2, ["E302600"] = 10, ["E302500"] = 3, ["E305400"] = 4, ["C308F00"] = 1, ["E308702"] = 1,
		["E305500"] = 5, ["C305500"] = 1,
	},
	[174] = {
		["E309200"] = 18, ["E302600"] = 14, ["C307801"] = 1, ["E302700"] = 5, ["E307400"] = 8, ["E305400"] = 60,
		["C308F00"] = 1, ["E308702"] = 3, ["E305500"] = 4, ["E307B01"] = 40, ["C305500"] = 1,
	},
	[175] = {
		["E000703"] = 2, ["E309200"] = 18, ["E302600"] = 34, ["C307801"] = 1, ["E302700"] = 4, ["E307400"] = 8,
		["E305400"] = 60, ["C308F00"] = 1, ["E305500"] = 2, ["E307B01"] = 24, ["C305500"] = 1,
	},
	[176] = {
		["E309200"] = 10, ["E302600"] = 10, ["E302700"] = 13, ["E307400"] = 32, ["E302500"] = 27, ["E305400"] = 60,
		["C308F00"] = 1, ["E308702"] = 1, ["E305500"] = 4, ["C305500"] = 1,
	},
	[177] = {
		["E302600"] = 10, ["E302700"] = 21, ["E307400"] = 32, ["E302500"] = 21, ["E305400"] = 60, ["E308702"] = 7,
		["E305500"] = 43, ["E000701"] = 1, ["C305500"] = 1,
	},
	[178] = {
		["E302600"] = 14, ["E302700"] = 9, ["E307400"] = 26, ["E302500"] = 43, ["E305400"] = 72, ["E305500"] = 1,
		["C305500"] = 1,
	},
	[179] = {
		["E309200"] = 52, ["E302600"] = 8, ["E302700"] = 3, ["E302500"] = 1, ["E000201"] = 4, ["C308F00"] = 1,
		["E308401"] = 6, ["E309700"] = 12, ["E305500"] = 3, ["C305500"] = 1,
	},
	[180] = {
		["E309200"] = 28, ["E302600"] = 22, ["E302700"] = 2, ["E307400"] = 12, ["C308F00"] = 1, ["E309700"] = 21,
		["E305500"] = 2, ["C305500"] = 1,
	},
	[181] = {
		["E309200"] = 28, ["E302600"] = 20, ["C307801"] = 1, ["E307400"] = 12, ["E302500"] = 1, ["C308F00"] = 1,
		["E305500"] = 2, ["E000701"] = 1, ["E307B01"] = 18, ["C305500"] = 1,
	},
	[182] = { ["E309200"] = 78, ["E302600"] = 4, ["E302700"] = 3, ["C308F00"] = 1, ["E305500"] = 2, ["C305500"] = 1 },
	[183] = {
		["E302600"] = 14, ["E302700"] = 29, ["E307400"] = 34, ["E302500"] = 19, ["E308700"] = 1, ["E308702"] = 3,
		["E309700"] = 64, ["E305500"] = 55, ["C305500"] = 1,
	},
	[184] = {
		["E309200"] = 44, ["E302600"] = 12, ["E302700"] = 3, ["E307000"] = 8, ["E302500"] = 5, ["C308F00"] = 1,
		["E308702"] = 1, ["E000701"] = 1,
	},
	[185] = {
		["C303C00"] = 1, ["E309200"] = 30, ["E307B00"] = 36, ["E302600"] = 16, ["E302700"] = 13, ["E302500"] = 31,
		["C307800"] = 1, ["E305400"] = 98, ["C308F00"] = 1, ["E309700"] = 12, ["E303D00"] = 4,
	},
	[186] = {
		["E307100"] = 28, ["E307B00"] = 36, ["E302600"] = 8, ["E302700"] = 7, ["E302500"] = 53, ["C307800"] = 1,
		["E305400"] = 48, ["E308702"] = 1, ["E309700"] = 42,
	},
	[187] = {
		["E307B00"] = 48, ["E302600"] = 24, ["E302700"] = 2, ["E307400"] = 10, ["E302500"] = 6, ["C307800"] = 1,
		["E305400"] = 112, ["E308702"] = 15, ["E303B00"] = 6,
	},
	[188] = {
		["C303C00"] = 1, ["E309200"] = 44, ["E302600"] = 10, ["E302700"] = 3, ["E307400"] = 12, ["E302500"] = 5,
		["C308F00"] = 1, ["E308700"] = 3, ["E303D00"] = 10, ["E000701"] = 1,
	},
	[189] = {
		["E000703"] = 5, ["E302600"] = 10, ["E302700"] = 7, ["E307000"] = 8, ["E307400"] = 8, ["E309700"] = 19,
		["E305500"] = 19, ["C305500"] = 1,
	},
	[190] = {
		["E302600"] = 10, ["E302700"] = 5, ["E307400"] = 12, ["E302500"] = 5, ["E308700"] = 1, ["E308702"] = 1,
		["E309700"] = 18, ["E305500"] = 19, ["C305500"] = 1,
	},
	[191] = {
		["E309200"] = 4, ["E302600"] = 10, ["E302700"] = 5, ["E307400"] = 12, ["E302500"] = 5, ["C308F00"] = 1,
		["E308702"] = 1, ["E309700"] = 2,
	},
	[192] = {
		["C303C00"] = 1, ["E307100"] = 6, ["E309200"] = 8, ["E302600"] = 4, ["E302700"] = 3, ["E307400"] = 10,
		["C308F00"] = 1, ["E303D00"] = 22,
	},
	[193] = {
		["C303C00"] = 1, ["E309200"] = 8, ["E302600"] = 4, ["E302700"] = 3, ["E307400"] = 16, ["C308F00"] = 1,
		["E303D00"] = 22,
	},
	[194] = {
		["C303C00"] = 1, ["E307B00"] = 72, ["E302600"] = 60, ["E302700"] = 3, ["E307400"] = 16, ["E302500"] = 67,
		["C307800"] = 1, ["E309700"] = 35, ["E303D00"] = 4, ["C309300"] = 1, ["E30A100"] = 12,
	},
	[195] = {
		["E307B00"] = 72, ["E302600"] = 54, ["E302700"] = 3, ["E307400"] = 10, ["E302500"] = 67, ["C307800"] = 1,
		["E305400"] = 6, ["E309700"] = 40, ["E305500"] = 11, ["C305500"] = 1,
	},
	[196] = {
		["E307B00"] = 18, ["E302600"] = 6, ["E302700"] = 23, ["E307400"] = 78, ["C307800"] = 1, ["E305400"] = 6,
		["E309700"] = 46, ["E308C00"] = 3, ["E305500"] = 75, ["C305500"] = 1,
	},
	[197] = {
		["E307B00"] = 120, ["E302600"] = 22, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 78, ["C307800"] = 1,
		["E305400"] = 6, ["E309700"] = 6, ["E305500"] = 3, ["E307B01"] = 12, ["C305500"] = 1,
	},
	[198] = {
		["C303C00"] = 1, ["E309200"] = 34, ["E307B00"] = 106, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 72,
		["E302500"] = 1, ["C307800"] = 1, ["E305400"] = 6, ["C308F00"] = 1, ["E303D00"] = 4, ["E307B01"] = 30,
	},
	[199] = {
		["E000703"] = 2, ["E309200"] = 12, ["E307B00"] = 136, ["E302600"] = 29, ["E302700"] = 13, ["E307400"] = 72,
		["C307800"] = 1, ["E305400"] = 6, ["C308F00"] = 1, ["E308702"] = 5,
	},
	[200] = {
		["E302600"] = 12, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 72, ["E305400"] = 6, ["E308702"] = 5,
		["E305500"] = 35, ["E000701"] = 1, ["E307B01"] = 12, ["C305500"] = 1,
	},
	[201] = {
		["E302600"] = 14, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 72, ["E305400"] = 6, ["E308702"] = 5,
		["E305500"] = 35, ["E000701"] = 1, ["E307B01"] = 10, ["C305500"] = 1,
	},
	[202] = {
		["C307801"] = 1, ["E302700"] = 19, ["E307400"] = 78, ["E308700"] = 1, ["E308702"] = 1, ["E305500"] = 37,
		["E307B01"] = 10, ["C305500"] = 1,
	},
	[203] = {
		["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 78, ["E308700"] = 1, ["E308702"] = 1, ["E303A00"] = 4,
		["E305500"] = 49, ["E307B01"] = 10, ["C305500"] = 1,
	},
	[204] = {
		["C303C00"] = 1, ["E302600"] = 12, ["E302700"] = 3, ["E307400"] = 78, ["E308700"] = 1, ["E308702"] = 1,
		["E309700"] = 98, ["E303D00"] = 4,
	},
	[205] = {
		["E309200"] = 32, ["E307B00"] = 18, ["C307801"] = 1, ["E302700"] = 2, ["E307400"] = 52, ["E302500"] = 1,
		["C307800"] = 1, ["C308F00"] = 1, ["E303A00"] = 2, ["E305500"] = 19, ["E307B01"] = 14, ["C305500"] = 1,
	},
	[206] = {
		["E000703"] = 4, ["E307B00"] = 18, ["E302600"] = 14, ["E307200"] = 2, ["E302700"] = 11, ["E307400"] = 50,
		["C307800"] = 1, ["E308702"] = 3, ["E305500"] = 48, ["C305500"] = 1,
	},
	[207] = {
		["E000703"] = 4, ["E302700"] = 3, ["E302500"] = 15, ["E308F00"] = 6, ["E305400"] = 80, ["E305500"] = 47,
		["C305500"] = 1,
	},
	[208] = {
		["E000703"] = 2, ["E307100"] = 4, ["E309200"] = 2, ["E302600"] = 9, ["C307801"] = 1, ["E307400"] = 2,
		["C308F00"] = 1, ["E305500"] = 6, ["E307B01"] = 34, ["C305500"] = 1,
	},
	[209] = {
		["E302600"] = 18, ["E307400"] = 70, ["E302500"] = 75, ["E308700"] = 1, ["E308702"] = 11, ["E309700"] = 42,
		["E305500"] = 9, ["C305500"] = 1,
	},
	[210] = {
		["E309200"] = 22, ["E307B00"] = 2, ["E302600"] = 2, ["E307300"] = 1, ["E302700"] = 3, ["E307400"] = 38,
		["C307800"] = 1, ["E305400"] = 30, ["C308F00"] = 1, ["E305500"] = 69, ["C305500"] = 1,
	},
	[211] = { ["C303C00"] = 1, ["E302700"] = 3, ["E303D00"] = 2, ["E305500"] = 11, ["E000701"] = 9, ["C305500"] = 1 },
	[212] = {
		["E309200"] = 2, ["E302600"] = 5, ["E302700"] = 3, ["C308F00"] = 1, ["E303B00"] = 4, ["C309300"] = 1,
		["E30A100"] = 16,
	},
	[213] = {
		["E000703"] = 4, ["E309200"] = 6, ["E302600"] = 7, ["C307801"] = 1, ["E307200"] = 8, ["E302700"] = 3,
		["C308F00"] = 1, ["E307B01"] = 32,
	},
	[214] = { ["E305500"] = 3, ["E000701"] = 1, ["C305500"] = 1 },
	[215] = { ["E000703"] = 2, ["E309200"] = 10, ["E302400"] = 2, ["E302700"] = 9, ["C308F00"] = 1, ["E000701"] = 1 },
	[216] = {
		["E307B00"] = 16, ["E302600"] = 12, ["C307801"] = 1, ["E302700"] = 21, ["E307400"] = 70, ["C307800"] = 1,
		["E309700"] = 18, ["E305500"] = 13, ["E000701"] = 1, ["E307B01"] = 30, ["C305500"] = 1,
	},
	[217] = {
		["E309200"] = 10, ["E302400"] = 2, ["E302700"] = 9, ["C308F00"] = 1, ["E305500"] = 2, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[218] = {
		["E000200"] = 10, ["E302600"] = 12, ["E302700"] = 15, ["E307400"] = 18, ["E302500"] = 55, ["E308F00"] = 2,
		["E309700"] = 68, ["E305500"] = 13, ["C305500"] = 1,
	},
	[219] = {
		["E307B00"] = 50, ["E302600"] = 27, ["E302700"] = 19, ["E307400"] = 28, ["C307800"] = 1, ["E308702"] = 1,
		["E309700"] = 48, ["E305500"] = 13, ["E000701"] = 1, ["C305500"] = 1,
	},
	[220] = { ["E309200"] = 18, ["E302400"] = 1, ["E302700"] = 3, ["C308F00"] = 1, ["E305500"] = 19, ["C305500"] = 1 },
	[221] = {
		["E307B00"] = 74, ["E302600"] = 8, ["C307801"] = 1, ["E302700"] = 5, ["E302500"] = 28, ["C307800"] = 1,
		["E308501"] = 4, ["E309700"] = 26, ["E305500"] = 77, ["E307B01"] = 24, ["C305500"] = 1,
	},
	[222] = {
		["E307B00"] = 50, ["E302600"] = 76, ["E302700"] = 7, ["E302500"] = 28, ["C307800"] = 1, ["E309700"] = 12,
		["E305500"] = 77, ["E000701"] = 1, ["C305500"] = 1,
	},
	[223] = {
		["C303C00"] = 1, ["E309200"] = 12, ["E302600"] = 30, ["E302700"] = 9, ["E302500"] = 29, ["C308F00"] = 1,
		["E303D00"] = 8, ["E305500"] = 7, ["E000701"] = 5, ["C305500"] = 1,
	},
	[224] = {
		["E302700"] = 3, ["E307400"] = 74, ["E302500"] = 86, ["E305400"] = 14, ["E305500"] = 25, ["E000701"] = 1,
		["C305500"] = 1,
	},
	[225] = {
		["E302600"] = 12, ["E307400"] = 54, ["E302500"] = 89, ["E305400"] = 34, ["E308702"] = 11, ["E305500"] = 3,
		["C305500"] = 1,
	},
	[226] = {
		["C303C00"] = 1, ["E302600"] = 10, ["E307400"] = 74, ["E302500"] = 89, ["E305400"] = 14, ["E308501"] = 2,
		["E309700"] = 16, ["E303D00"] = 38, ["E305500"] = 1, ["C305500"] = 1,
	},
	[227] = {
		["E302600"] = 72, ["E302700"] = 47, ["E307400"] = 88, ["E302500"] = 27, ["E308501"] = 8, ["E309700"] = 10,
		["E305500"] = 5, ["C305500"] = 1,
	},
	[228] = {
		["C303C00"] = 1, ["E309200"] = 46, ["E302600"] = 6, ["E302700"] = 3, ["E307400"] = 6, ["C308F00"] = 1,
		["E308702"] = 3, ["E303D00"] = 10, ["E305500"] = 41, ["E000701"] = 1, ["C305500"] = 1,
	},
	[229] = {
		["E000703"] = 4, ["E309200"] = 48, ["E302600"] = 12, ["C307801"] = 1, ["E302700"] = 11, ["E307400"] = 6,
		["E302500"] = 1, ["C308F00"] = 1, ["E305500"] = 41, ["E307B01"] = 6, ["C305500"] = 1,
	},
	[230] = {
		["C303C00"] = 1, ["E309200"] = 20, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 6, ["E302500"] = 1,
		["C308F00"] = 1, ["E303D00"] = 8, ["E305500"] = 111, ["E307B01"] = 6, ["C305500"] = 1,
	},
	[231] = {
		["E000703"] = 4, ["E309200"] = 10, ["E302600"] = 18, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 8,
		["C308F00"] = 1, ["E305500"] = 67, ["E000701"] = 13, ["E307B01"] = 6, ["C305500"] = 1,
	},
	[232] = {
		["C303C00"] = 1, ["E309200"] = 2, ["E302600"] = 72, ["E302700"] = 2, ["E307000"] = 2, ["E307400"] = 36,
		["E302500"] = 13, ["C308F00"] = 1, ["E309700"] = 16, ["E303D00"] = 4,
	},
	[233] = {
		["C303C00"] = 1, ["E302600"] = 34, ["E307300"] = 15, ["E302700"] = 2, ["E302500"] = 7, ["E305400"] = 42,
		["E308702"] = 1, ["E309700"] = 40, ["E303D00"] = 4, ["C305500"] = 1,
	},
	[234] = {
		["C303C00"] = 1, ["E302600"] = 36, ["E302700"] = 2, ["E302500"] = 19, ["E305400"] = 44, ["E308700"] = 7,
		["E308702"] = 1, ["E309700"] = 32, ["E303D00"] = 4, ["C305500"] = 1,
	},
	[235] = {
		["C303C00"] = 1, ["E302600"] = 36, ["E302700"] = 2, ["E302500"] = 21, ["E305400"] = 42, ["E308700"] = 7,
		["E308702"] = 1, ["E309700"] = 34, ["E303D00"] = 2, ["C305500"] = 1,
	},
	[236] = {
		["C303C00"] = 1, ["E302600"] = 36, ["E302500"] = 21, ["E305400"] = 42, ["E308700"] = 1, ["E308702"] = 1,
		["E309700"] = 40, ["E303D00"] = 2, ["E305500"] = 2, ["C305500"] = 1,
	},
	[237] = {
		["C303C00"] = 1, ["E302600"] = 61, ["E307400"] = 16, ["E302500"] = 5, ["E305400"] = 42, ["E308702"] = 1,
		["E309700"] = 14, ["E303D00"] = 4, ["E305500"] = 2, ["C305500"] = 1,
	},
	[238] = {
		["C303C00"] = 1, ["E302600"] = 28, ["E302500"] = 21, ["E305400"] = 42, ["E308502"] = 30, ["E309700"] = 20,
		["E303D00"] = 2, ["E305500"] = 2, ["C305500"] = 1,
	},
	[239] = {
		["E302600"] = 14, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 22, ["E302500"] = 70, ["E309700"] = 14,
		["E305500"] = 15, ["E000701"] = 1, ["E307B01"] = 14, ["C305500"] = 1,
	},
	[240] = {
		["E302600"] = 60, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 22, ["E302500"] = 9, ["E308702"] = 1,
		["E309700"] = 16, ["E305500"] = 25, ["E307B01"] = 24, ["C305500"] = 1,
	},
	[241] = {
		["E302600"] = 26, ["E307200"] = 4, ["E302700"] = 15, ["E307400"] = 20, ["E302500"] = 71, ["E308702"] = 1,
		["E309700"] = 92, ["C305500"] = 1,
	},
	[242] = {
		["C303C00"] = 1, ["E307100"] = 6, ["E302600"] = 27, ["C307801"] = 1, ["E302700"] = 11, ["E307400"] = 24,
		["E309700"] = 74, ["E303D00"] = 2, ["E305500"] = 43, ["E307B01"] = 24, ["C305500"] = 1,
	},
	[243] = {
		["C303C00"] = 1, ["E307B00"] = 22, ["E302600"] = 22, ["E307400"] = 24, ["E302500"] = 7, ["C307800"] = 1,
		["E308F00"] = 6, ["E309700"] = 80, ["E303D00"] = 6, ["E305500"] = 42, ["C305500"] = 1,
	},
	[244] = {
		["E309200"] = 36, ["E307B00"] = 18, ["E302600"] = 28, ["E302700"] = 5, ["E307400"] = 36, ["C307800"] = 1,
		["C308F00"] = 1, ["E309700"] = 32, ["E305500"] = 3, ["C305500"] = 1,
	},
	[245] = {
		["E309200"] = 36, ["E307B00"] = 18, ["E302600"] = 9, ["C307801"] = 1, ["E302700"] = 5, ["E307400"] = 36,
		["C307800"] = 1, ["C308F00"] = 1, ["E309700"] = 18, ["E305500"] = 3, ["E307B01"] = 28, ["C305500"] = 1,
	},
	[246] = {
		["E000703"] = 6, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 3, ["E307400"] = 60, ["E302500"] = 1,
		["E308702"] = 1, ["E000701"] = 1, ["E307B01"] = 102,
	},
	[247] = {
		["E302600"] = 56, ["C307801"] = 1, ["E302700"] = 21, ["E307400"] = 70, ["E305400"] = 10, ["E308700"] = 1,
		["E308702"] = 1, ["E309700"] = 28, ["E307B01"] = 8,
	},
	[248] = {
		["C303C00"] = 1, ["E309200"] = 22, ["E302600"] = 54, ["E302700"] = 23, ["E307400"] = 50, ["E302500"] = 35,
		["E305400"] = 10, ["C308F00"] = 1, ["E303D00"] = 44, ["E305500"] = 1, ["C305500"] = 1,
	},
	[249] = {
		["E000202"] = 4, ["E309200"] = 24, ["E307B00"] = 52, ["E302600"] = 10, ["C307801"] = 1, ["E302700"] = 5,
		["E302500"] = 1, ["C307800"] = 1, ["C308F00"] = 1, ["E309700"] = 16, ["E307B01"] = 26,
	},
	[250] = {
		["E000703"] = 1, ["E307B00"] = 52, ["E302600"] = 7, ["E302500"] = 1, ["C307800"] = 1, ["E308700"] = 1,
		["E308702"] = 1,
	},
	[251] = {
		["E307B00"] = 48, ["E302600"] = 12, ["C307801"] = 1, ["E302700"] = 13, ["E302500"] = 1, ["C307800"] = 1,
		["E308702"] = 1, ["C309300"] = 1, ["E30A100"] = 10, ["E307B01"] = 32,
	},
	[252] = {
		["E000703"] = 1, ["E307B00"] = 50, ["C307801"] = 1, ["E302700"] = 5, ["C307800"] = 1, ["E308702"] = 1,
		["E308502"] = 12, ["E309700"] = 14, ["E305500"] = 3, ["E307B01"] = 92, ["C305500"] = 1,
	},
	[253] = {
		["E309200"] = 18, ["E302600"] = 10, ["E302700"] = 3, ["E302500"] = 1, ["E305400"] = 12, ["C308F00"] = 1,
		["E305500"] = 5, ["E000701"] = 1, ["C305500"] = 1,
	},
	[254] = { ["E000703"] = 1, ["E307B00"] = 48, ["E302600"] = 14, ["E302500"] = 1, ["C307800"] = 1 },
	[255] = {
		["E000202"] = 4, ["E309200"] = 20, ["E302600"] = 10, ["E302700"] = 3, ["E302500"] = 1, ["C308F00"] = 1,
		["E305500"] = 15, ["C305500"] = 1,
	},
}

_M.routes["paladin"] = {
	[0] = { ["E302500"] = 1, ["E302600"] = 10, ["E000202"] = 4 },
	[1] = { ["E302500"] = 59, ["E302600"] = 10, ["E000202"] = 14 },
	[2] = { ["E302500"] = 59, ["C307800"] = 1, ["E307B00"] = 40 },
	[3] = { ["E302500"] = 59, ["C307800"] = 1, ["E302600"] = 2, ["E307B00"] = 36 },
	[4] = { ["E302500"] = 23, ["C307800"] = 1, ["E302600"] = 2, ["E307B00"] = 72 },
	[5] = {},
	[6] = {
		["E302500"] = 21, ["C307800"] = 1, ["E307600"] = 2, ["C307801"] = 1, ["E302600"] = 2, ["E307B00"] = 60,
		["E307B01"] = 98,
	},
	[7] = {
		["E302500"] = 61, ["C307800"] = 1, ["E307600"] = 2, ["C307801"] = 1, ["E302600"] = 33, ["E307B00"] = 20,
		["E307B01"] = 26,
	},
	[8] = { ["E302500"] = 57, ["E307000"] = 2, ["E302600"] = 93 },
	[9] = {
		["E305400"] = 8, ["E302500"] = 17, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 33, ["E307B00"] = 58,
		["E000202"] = 4, ["E307B01"] = 22,
	},
	[10] = { ["E305400"] = 8, ["E302500"] = 17, ["C307800"] = 1, ["E302600"] = 17, ["E307B00"] = 26 },
	[11] = { ["E305400"] = 8, ["E302500"] = 3, ["C307800"] = 1, ["E302600"] = 28, ["E307B00"] = 20, ["E000202"] = 12 },
	[12] = { ["E305400"] = 10, ["E302500"] = 44, ["E302600"] = 22 },
	[13] = { ["E305400"] = 10, ["E302500"] = 45, ["E302600"] = 8 },
	[14] = { ["E305400"] = 54, ["E302500"] = 1, ["E302600"] = 8 },
	[15] = { ["E305400"] = 54, ["E302500"] = 1, ["E302600"] = 8 },
	[16] = { ["E305400"] = 18, ["E302500"] = 37, ["E302600"] = 7 },
	[17] = { ["E305400"] = 10, ["C307800"] = 1, ["E302600"] = 12, ["E307B00"] = 36 },
	[18] = { ["E305400"] = 10, ["E302500"] = 37, ["E307400"] = 8, ["E302600"] = 8 },
	[19] = { ["E305400"] = 18, ["E302500"] = 37, ["E302600"] = 7 },
	[20] = { ["E305400"] = 18, ["E302500"] = 5, ["E302600"] = 10 },
	[21] = { ["E305400"] = 18, ["E302500"] = 27, ["C307800"] = 1, ["E302600"] = 5, ["E307B00"] = 2 },
	[22] = { ["E302500"] = 27, ["E307400"] = 18, ["C307800"] = 1, ["E302600"] = 5, ["E307B00"] = 2 },
	[23] = { ["E302500"] = 81, ["E307400"] = 2, ["C307801"] = 1, ["E302600"] = 10, ["E307B01"] = 4 },
	[24] = { ["E305400"] = 44, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 16, ["E307B00"] = 12, ["E307B01"] = 2 },
	[25] = {
		["E302500"] = 50, ["E307400"] = 2, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 7, ["E307B00"] = 4,
		["E307B01"] = 2,
	},
	[26] = { ["E302500"] = 55, ["E307400"] = 2, ["E302600"] = 18 },
	[27] = { ["E307400"] = 8, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 5, ["E307B00"] = 48, ["E307B01"] = 36 },
	[28] = { ["E305400"] = 50, ["E302500"] = 7, ["E302600"] = 18 },
	[29] = { ["E302500"] = 7, ["E307400"] = 2, ["E302600"] = 10 },
	[30] = { ["E305400"] = 8, ["E302500"] = 50, ["C307801"] = 1, ["E307B01"] = 38 },
	[31] = { ["E305400"] = 8, ["E302500"] = 11, ["C307800"] = 1, ["E307B00"] = 16 },
	[32] = {
		["E305400"] = 6, ["E302500"] = 65, ["C307801"] = 1, ["E302600"] = 19, ["E000202"] = 2, ["E307B01"] = 26,
		["E308000"] = 4,
	},
	[33] = {
		["E308400"] = 4, ["E305400"] = 30, ["E302500"] = 7, ["E307400"] = 34, ["C307801"] = 1, ["E302600"] = 66,
		["E000202"] = 6, ["E307B01"] = 26,
	},
	[34] = {
		["E305400"] = 26, ["E302500"] = 31, ["E307400"] = 18, ["C307801"] = 1, ["E302600"] = 58, ["E000202"] = 2,
		["E307B01"] = 22, ["E307F00"] = 18,
	},
	[35] = { ["E305400"] = 20, ["E302600"] = 18 },
	[36] = { ["E305400"] = 6, ["E302500"] = 1, ["E307400"] = 14, ["C307800"] = 1, ["E302600"] = 4, ["E307B00"] = 8 },
	[37] = { ["E305400"] = 6, ["E307400"] = 14, ["C307800"] = 1, ["E302600"] = 48, ["E307B00"] = 24, ["E000202"] = 4 },
	[38] = { ["C307800"] = 1, ["E307200"] = 20, ["C307801"] = 1, ["E302600"] = 38, ["E307B00"] = 14, ["E307B01"] = 90 },
	[39] = { ["E302500"] = 1, ["C307800"] = 1, ["E307200"] = 20, ["E302600"] = 10, ["E307B00"] = 64 },
	[40] = { ["E302500"] = 5, ["E307000"] = 26, ["E302600"] = 10 },
	[41] = { ["E302500"] = 10, ["E307400"] = 20, ["E302600"] = 7 },
	[42] = { ["E302500"] = 9, ["E307400"] = 20, ["E302600"] = 10, ["E308000"] = 2 },
	[43] = { ["E302500"] = 27, ["E307400"] = 2, ["E302600"] = 29 },
	[44] = { ["E302500"] = 27, ["E307400"] = 2, ["E302600"] = 32 },
	[45] = { ["E302500"] = 29, ["E307400"] = 2, ["E302600"] = 30 },
	[46] = { ["E307400"] = 4 },
	[47] = { ["E302500"] = 29, ["E307400"] = 2, ["E302600"] = 50 },
	[48] = { ["E302500"] = 37, ["E307400"] = 2, ["E302600"] = 74 },
	[49] = { ["E305400"] = 126, ["E302500"] = 41, ["E307400"] = 18, ["C307801"] = 1, ["E302600"] = 11, ["E307B01"] = 50 },
	[50] = { ["E305400"] = 40, ["E302500"] = 1, ["C307800"] = 1, ["E302600"] = 8, ["E307B00"] = 34 },
	[51] = { ["E305400"] = 94 },
	[52] = { ["E302500"] = 30, ["E307300"] = 6, ["E302600"] = 48 },
	[53] = { ["E302500"] = 30, ["E307300"] = 6, ["E302600"] = 48 },
	[54] = { ["E302500"] = 54, ["E307300"] = 6, ["E302600"] = 24 },
	[55] = { ["E302500"] = 61, ["C307801"] = 1, ["E307300"] = 6, ["E302600"] = 10, ["E307B01"] = 32 },
	[56] = { ["E302500"] = 19, ["E307400"] = 4, ["C307801"] = 1, ["E302600"] = 10, ["E307B01"] = 76 },
	[57] = { ["E302500"] = 15, ["E307000"] = 4, ["C307801"] = 1, ["E302600"] = 10, ["E307B01"] = 80 },
	[58] = { ["E308400"] = 6, ["E302500"] = 57, ["E307000"] = 4, ["E302600"] = 10 },
	[59] = { ["E302500"] = 18, ["E307000"] = 4, ["C307801"] = 1, ["E302600"] = 10, ["E307B01"] = 76 },
	[60] = { ["E305400"] = 42, ["E302500"] = 3, ["E302600"] = 68 },
	[61] = { ["E305400"] = 72, ["E302500"] = 7, ["E302600"] = 12, ["E307802"] = 22 },
	[62] = { ["E305400"] = 52, ["E307900"] = 22, ["E302500"] = 27, ["C307801"] = 1, ["E302600"] = 6, ["E307B01"] = 18 },
	[63] = { ["E305400"] = 72, ["E302500"] = 58 },
	[64] = { ["E305400"] = 72, ["E302500"] = 58, ["E302600"] = 7 },
	[65] = { ["E305400"] = 52, ["E302500"] = 59, ["E307400"] = 20, ["C307801"] = 1, ["E302600"] = 12, ["E307B01"] = 14 },
	[66] = { ["E302500"] = 1, ["E302600"] = 1 },
	[67] = { ["E302500"] = 1, ["E302600"] = 1 },
	[68] = { ["E302500"] = 1 },
	[69] = {
		["E302500"] = 7, ["E307400"] = 30, ["C307800"] = 1, ["E307300"] = 4, ["E302600"] = 14, ["E307B00"] = 32,
		["E308000"] = 12,
	},
	[70] = { ["E305400"] = 90, ["E302600"] = 14 },
	[71] = { ["E305400"] = 34, ["E302500"] = 57, ["C307800"] = 1, ["E302600"] = 6, ["E307B00"] = 2 },
	[72] = { ["E305400"] = 90, ["E302500"] = 1, ["C307800"] = 1, ["E302600"] = 12, ["E307B00"] = 2 },
	[73] = { ["E305400"] = 78, ["E302500"] = 1, ["E307400"] = 12, ["C307800"] = 1, ["E302600"] = 12, ["E307B00"] = 2 },
	[74] = { ["E305400"] = 78, ["E302500"] = 18, ["E307400"] = 68, ["C307801"] = 1, ["E307B01"] = 10 },
	[75] = { ["E305400"] = 74, ["E302500"] = 18, ["E307400"] = 72, ["C307801"] = 1, ["E000202"] = 2, ["E307B01"] = 8 },
	[76] = { ["E305400"] = 62, ["E302500"] = 18, ["E307400"] = 84, ["C307801"] = 1, ["E307B01"] = 10 },
	[77] = { ["E302500"] = 56, ["E307400"] = 86, ["E307000"] = 22, ["C307800"] = 1, ["E302600"] = 10, ["E307B00"] = 20 },
	[78] = { ["E302500"] = 3, ["E302600"] = 10 },
	[79] = { ["E302500"] = 2, ["E302600"] = 4 },
	[80] = { ["E302500"] = 3, ["C307800"] = 1, ["E307B00"] = 4 },
	[81] = { ["E302500"] = 3, ["C307800"] = 1, ["E307B00"] = 4 },
	[82] = { ["E305400"] = 18, ["E307300"] = 7 },
	[83] = { ["C307800"] = 1, ["E307300"] = 2, ["E307B00"] = 4 },
	[84] = { ["E302500"] = 1, ["E302600"] = 10 },
	[85] = { ["E305400"] = 24 },
	[86] = { ["E302500"] = 5, ["E307300"] = 2, ["E302600"] = 4 },
	[87] = { ["E302500"] = 7, ["E302600"] = 9 },
	[88] = { ["E307400"] = 12, ["C307800"] = 1, ["E307300"] = 1, ["E307B00"] = 32 },
	[89] = { ["E302500"] = 1, ["C307800"] = 1, ["E307200"] = 10, ["E307300"] = 3, ["E302600"] = 10, ["E307B00"] = 30 },
	[90] = {
		["E305400"] = 112, ["E302500"] = 3, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 16, ["E307B00"] = 20,
		["E307B01"] = 18,
	},
	[91] = { ["E305400"] = 178, ["E302500"] = 10 },
	[92] = { ["E305400"] = 112, ["E302500"] = 38, ["C307800"] = 1, ["E302600"] = 2, ["E307B00"] = 22 },
	[93] = { ["E302500"] = 1, ["E302600"] = 12 },
	[94] = { ["E302500"] = 1, ["E302600"] = 12 },
	[95] = { ["E302500"] = 1, ["E302600"] = 12 },
	[96] = { ["E307300"] = 2, ["E302600"] = 10 },
	[97] = { ["E305400"] = 90, ["E302500"] = 15, ["E307400"] = 14, ["C307801"] = 1, ["E302600"] = 3, ["E307B01"] = 12 },
	[98] = { ["C307800"] = 1, ["E307B00"] = 36 },
	[99] = { ["E305400"] = 2, ["E302600"] = 39 },
	[100] = { ["E305400"] = 2, ["C307800"] = 1, ["E307B00"] = 34 },
	[101] = { ["E305400"] = 2, ["C307800"] = 1, ["E307B00"] = 34 },
	[102] = { ["E305400"] = 20, ["C307800"] = 1, ["E302600"] = 5, ["E307B00"] = 8 },
	[103] = { ["E305400"] = 26, ["E302500"] = 1, ["C307800"] = 1, ["E302600"] = 1, ["E307B00"] = 20 },
	[104] = { ["E305400"] = 20, ["E307900"] = 10, ["E307400"] = 34, ["C307801"] = 1, ["E302600"] = 6, ["E307B01"] = 6 },
	[105] = {
		["E305400"] = 26, ["E302500"] = 15, ["E307400"] = 60, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 2,
		["E307B00"] = 54, ["E307B01"] = 34,
	},
	[106] = { ["E305400"] = 32 },
	[107] = { ["E302500"] = 1, ["E302600"] = 28 },
	[108] = { ["E305400"] = 26, ["E307400"] = 10, ["E307300"] = 1 },
	[109] = { ["E307400"] = 8, ["E307000"] = 28, ["E307300"] = 1, ["E302600"] = 4 },
	[110] = { ["E305400"] = 4, ["E302500"] = 3, ["E302600"] = 34 },
	[111] = { ["E305400"] = 12, ["E302500"] = 1, ["E302600"] = 28 },
	[112] = { ["E305400"] = 12, ["E302600"] = 6 },
	[113] = { ["E305400"] = 12, ["E302600"] = 9 },
	[114] = { ["E305400"] = 12, ["E302600"] = 9 },
	[115] = { ["E305400"] = 12, ["E302600"] = 6 },
	[116] = { ["E305400"] = 12, ["E302600"] = 6 },
	[117] = { ["E305400"] = 12, ["E302600"] = 9 },
	[118] = { ["E307100"] = 14 },
	[119] = { ["E302500"] = 1 },
	[120] = { ["E302500"] = 1 },
	[121] = { ["E302500"] = 15, ["E302600"] = 10 },
	[122] = { ["E302500"] = 1 },
	[123] = {},
	[124] = {
		["E302500"] = 7, ["E307400"] = 28, ["E307000"] = 18, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 1,
		["E307B00"] = 12, ["E307B01"] = 20,
	},
	[125] = {
		["E302500"] = 1, ["E307400"] = 34, ["E307000"] = 18, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 1,
		["E307B00"] = 12, ["E307B01"] = 20,
	},
	[126] = {
		["E302500"] = 15, ["E307400"] = 12, ["C307800"] = 1, ["E307200"] = 18, ["C307801"] = 1, ["E302600"] = 30,
		["E307B00"] = 20, ["E307B01"] = 26,
	},
	[127] = { ["E307400"] = 30, ["E302600"] = 14 },
	[128] = { ["E302500"] = 15, ["E302600"] = 29 },
	[129] = { ["E302500"] = 14, ["E307400"] = 30, ["E302600"] = 4 },
	[130] = { ["E302500"] = 18, ["E307400"] = 26 },
	[131] = { ["E302500"] = 18, ["E307400"] = 26 },
	[132] = { ["E305400"] = 26, ["E302500"] = 1, ["E307400"] = 124, ["C307800"] = 1, ["E302600"] = 17, ["E307B00"] = 10 },
	[133] = { ["E305400"] = 26, ["E302500"] = 18 },
	[134] = { ["E305400"] = 26, ["E302500"] = 13, ["C307800"] = 1, ["E307B00"] = 14 },
	[135] = { ["E305400"] = 26, ["E302500"] = 7, ["C307801"] = 1, ["E307B01"] = 16 },
	[136] = { ["E305400"] = 26, ["E302500"] = 7, ["C307801"] = 1, ["E302600"] = 35, ["E307B01"] = 22 },
	[137] = { ["E305400"] = 24, ["E302500"] = 1, ["E307400"] = 8 },
	[138] = { ["E305400"] = 30, ["E302500"] = 1, ["E307400"] = 2 },
	[139] = { ["C307801"] = 1, ["E307B01"] = 6 },
	[140] = { ["E302600"] = 2 },
	[141] = { ["E302600"] = 5 },
	[142] = { ["E302600"] = 5 },
	[143] = { ["E305400"] = 2 },
	[144] = { ["E305400"] = 2, ["E302500"] = 37, ["E307400"] = 30, ["C307800"] = 1, ["E302600"] = 9, ["E307B00"] = 62 },
	[145] = { ["E305400"] = 58, ["E302500"] = 1, ["E307400"] = 16, ["C307800"] = 1, ["E302600"] = 1, ["E307B00"] = 52 },
	[146] = { ["E305400"] = 58, ["E302500"] = 1, ["E307400"] = 84 },
	[147] = { ["E305400"] = 58, ["E307400"] = 84 },
	[148] = { ["E305400"] = 58, ["E307400"] = 22, ["C307801"] = 1, ["E307300"] = 1, ["E000202"] = 18, ["E307B01"] = 24 },
	[149] = { ["E308400"] = 2, ["E305400"] = 58, ["E307400"] = 24, ["C307800"] = 1, ["E302600"] = 1, ["E307B00"] = 62 },
	[150] = { ["E305400"] = 46, ["E307400"] = 34, ["C307801"] = 1, ["E307300"] = 1, ["E302600"] = 38, ["E307B01"] = 14 },
	[151] = { ["E305400"] = 46, ["E302500"] = 9, ["E307400"] = 36, ["C307801"] = 1, ["E302600"] = 1, ["E307B01"] = 2 },
	[152] = { ["E305400"] = 46, ["E307400"] = 50, ["C307800"] = 1, ["E302600"] = 9, ["E307B00"] = 48 },
	[153] = { ["E305400"] = 46, ["E302500"] = 1, ["E307400"] = 50, ["C307800"] = 1, ["E302600"] = 4, ["E307B00"] = 52 },
	[154] = {
		["E305400"] = 46, ["E302500"] = 25, ["E307400"] = 20, ["C307800"] = 1, ["E302600"] = 42, ["E307B00"] = 58,
		["E308000"] = 4,
	},
	[155] = { ["E000201"] = 14, ["E305400"] = 46, ["E307400"] = 8, ["E302600"] = 12 },
	[156] = { ["E302500"] = 1, ["C307801"] = 1, ["E302600"] = 7, ["E307B01"] = 20 },
	[157] = { ["E000201"] = 14, ["E305400"] = 46, ["E307400"] = 8, ["E302600"] = 5 },
	[158] = { ["E305400"] = 46, ["E302500"] = 1, ["E307400"] = 12, ["C307800"] = 1, ["E302600"] = 12, ["E307B00"] = 4 },
	[159] = { ["E305400"] = 46, ["E302500"] = 1, ["E307400"] = 2, ["C307800"] = 1, ["E302600"] = 12, ["E307B00"] = 14 },
	[160] = { ["E305400"] = 46, ["E302500"] = 1, ["E307400"] = 2, ["C307800"] = 1, ["E302600"] = 12, ["E307B00"] = 14 },
	[161] = { ["E305400"] = 34, ["E302500"] = 1, ["E307400"] = 14, ["C307800"] = 1, ["E302600"] = 12, ["E307B00"] = 14 },
	[162] = { ["E305400"] = 34, ["E302500"] = 1, ["E307400"] = 14, ["C307800"] = 1, ["E307B00"] = 14 },
	[163] = { ["E305400"] = 34, ["E302500"] = 1, ["E307400"] = 14, ["C307800"] = 1, ["E307B00"] = 14 },
	[164] = { ["E302500"] = 24, ["E302600"] = 30 },
	[165] = { ["E307900"] = 2, ["E302600"] = 10 },
	[166] = { ["E302600"] = 10, ["E307E00"] = 2 },
	[167] = {},
	[168] = { ["E302500"] = 1 },
	[169] = { ["E305400"] = 10, ["E307400"] = 14 },
	[170] = { ["E305400"] = 10, ["E307400"] = 14 },
	[171] = { ["E305400"] = 10, ["E307400"] = 14 },
	[172] = { ["E305400"] = 4, ["E302500"] = 1, ["E000202"] = 2 },
	[173] = { ["E305400"] = 4, ["E302500"] = 31, ["C307801"] = 1, ["E000202"] = 14, ["E307B01"] = 40, ["E307F00"] = 16 },
	[174] = { ["E305400"] = 60, ["E302500"] = 1, ["E307400"] = 8, ["C307801"] = 1, ["E302600"] = 5, ["E307B01"] = 20 },
	[175] = { ["E305400"] = 60, ["E302500"] = 1, ["E307400"] = 8, ["C307801"] = 1, ["E302600"] = 5, ["E307B01"] = 20 },
	[176] = { ["E305400"] = 60, ["E302500"] = 1, ["E307400"] = 8, ["C307801"] = 1, ["E302600"] = 5, ["E307B01"] = 20 },
	[177] = { ["E305400"] = 60, ["E302500"] = 1, ["E307400"] = 8, ["C307801"] = 1, ["E302600"] = 5, ["E307B01"] = 20 },
	[178] = { ["E305400"] = 72, ["E302500"] = 43, ["E307400"] = 26, ["E302600"] = 20 },
	[179] = { ["E305400"] = 60, ["E302500"] = 43, ["E307400"] = 38, ["E302600"] = 20 },
	[180] = { ["E305400"] = 60, ["E307400"] = 38 },
	[181] = { ["E302500"] = 1, ["E307400"] = 12, ["E302600"] = 18 },
	[182] = { ["E302500"] = 1, ["E307400"] = 12, ["E302600"] = 12 },
	[183] = { ["E302500"] = 31, ["E307400"] = 98, ["C307800"] = 1, ["E302600"] = 35, ["E307B00"] = 36 },
	[184] = { ["E302500"] = 1, ["E307000"] = 12, ["E302600"] = 14 },
	[185] = { ["E305400"] = 80, ["E302500"] = 31, ["C307800"] = 1, ["E307300"] = 18, ["E302600"] = 48, ["E307B00"] = 36 },
	[186] = { ["E305400"] = 48, ["E302500"] = 53, ["C307800"] = 1, ["E302600"] = 10, ["E307B00"] = 30, ["E307100"] = 28 },
	[187] = { ["E305400"] = 112, ["E302500"] = 6, ["E307400"] = 10, ["C307800"] = 1, ["E302600"] = 24, ["E307B00"] = 48 },
	[188] = { ["E307400"] = 8, ["E307000"] = 8, ["E302600"] = 9 },
	[189] = { ["E307400"] = 8, ["E307000"] = 8, ["E302600"] = 9 },
	[190] = { ["E307400"] = 8, ["E307000"] = 8, ["E302600"] = 9 },
	[191] = {
		["E302500"] = 71, ["E307400"] = 12, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 10, ["E307B00"] = 38,
		["E307B01"] = 38,
	},
	[192] = {
		["E302500"] = 29, ["E307400"] = 10, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 12, ["E307B00"] = 76,
		["E307B01"] = 28, ["E307100"] = 6,
	},
	[193] = { ["E302500"] = 15, ["E307400"] = 16, ["C307800"] = 1, ["E302600"] = 24, ["E307B00"] = 124 },
	[194] = { ["E302500"] = 67, ["E307400"] = 16, ["C307800"] = 1, ["E302600"] = 54, ["E307B00"] = 72 },
	[195] = { ["E305400"] = 6, ["E302500"] = 67, ["E307400"] = 10, ["C307800"] = 1, ["E302600"] = 54, ["E307B00"] = 72 },
	[196] = { ["E305400"] = 6, ["E302500"] = 67, ["E307400"] = 10, ["C307800"] = 1, ["E302600"] = 48, ["E307B00"] = 72 },
	[197] = {
		["E305400"] = 6, ["E302500"] = 1, ["E307400"] = 78, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 7,
		["E307B00"] = 120, ["E307B01"] = 10,
	},
	[198] = {
		["E305400"] = 6, ["E302500"] = 1, ["E307400"] = 72, ["C307800"] = 1, ["C307801"] = 1, ["E307B00"] = 106,
		["E307B01"] = 30,
	},
	[199] = { ["E305400"] = 6, ["E302500"] = 1, ["E307400"] = 72, ["C307800"] = 1, ["E302600"] = 3, ["E307B00"] = 134 },
	[200] = { ["E305400"] = 6 },
	[201] = { ["E305400"] = 6, ["E302600"] = 14 },
	[202] = { ["E302500"] = 1, ["E307400"] = 52, ["E302600"] = 10 },
	[203] = { ["E307400"] = 78 },
	[204] = { ["E307400"] = 78 },
	[205] = { ["E302500"] = 1, ["E307400"] = 52, ["C307800"] = 1, ["C307801"] = 1, ["E307B00"] = 18, ["E307B01"] = 10 },
	[206] = { ["E307400"] = 50, ["C307800"] = 1, ["E307200"] = 2, ["E302600"] = 14, ["E307B00"] = 18 },
	[207] = { ["E305400"] = 80, ["E302500"] = 15, ["E302600"] = 7 },
	[208] = { ["E302500"] = 1, ["E307400"] = 8, ["C307800"] = 1, ["E302600"] = 16, ["E307B00"] = 58, ["E307100"] = 4 },
	[209] = { ["E302500"] = 1, ["E307400"] = 6, ["C307801"] = 1, ["E302600"] = 10, ["E307B01"] = 34 },
	[210] = { ["E305400"] = 30, ["E302500"] = 15, ["E307400"] = 40, ["E302600"] = 7 },
	[211] = { ["E302500"] = 15, ["E307400"] = 68, ["E307200"] = 2, ["E302600"] = 7 },
	[212] = { ["E302600"] = 1 },
	[213] = { ["E302600"] = 8 },
	[214] = { ["E302600"] = 8 },
	[215] = { ["E302600"] = 8 },
	[216] = { ["E302600"] = 8 },
	[217] = {},
	[218] = { ["E307400"] = 28, ["E000202"] = 4 },
	[219] = { ["E307400"] = 14, ["E307200"] = 14, ["E000202"] = 4 },
	[220] = { ["E302500"] = 1, ["E307400"] = 14, ["E307200"] = 14, ["E302600"] = 3 },
	[221] = { ["E302500"] = 5, ["E307400"] = 14, ["E307200"] = 14, ["E302600"] = 18 },
	[222] = { ["E302500"] = 33, ["E302600"] = 18 },
	[223] = { ["E302500"] = 29, ["E302600"] = 30 },
	[224] = {
		["E305400"] = 14, ["E302500"] = 1, ["E307400"] = 56, ["C307800"] = 1, ["C307801"] = 1, ["E307300"] = 1,
		["E302600"] = 8, ["E307B00"] = 32, ["E307B01"] = 44,
	},
	[225] = { ["E305400"] = 34, ["E307300"] = 5, ["E302600"] = 1 },
	[226] = { ["E308501"] = 2, ["E305400"] = 14, ["E302500"] = 89, ["E307400"] = 74, ["E302600"] = 10 },
	[227] = { ["E302500"] = 1, ["C307800"] = 1, ["E307300"] = 3, ["E302600"] = 7, ["E307B00"] = 12 },
	[228] = { ["E307400"] = 6, ["C307801"] = 1, ["E302600"] = 9, ["E307B01"] = 10 },
	[229] = { ["E302500"] = 1, ["E307400"] = 6, ["C307801"] = 1, ["E302600"] = 10, ["E307B01"] = 6 },
	[230] = { ["E302500"] = 1, ["E307400"] = 6, ["C307801"] = 1, ["E302600"] = 4, ["E307B01"] = 6 },
	[231] = { ["E302500"] = 1, ["E307400"] = 8, ["C307801"] = 1, ["E302600"] = 12, ["E307B01"] = 4 },
	[232] = { ["E302500"] = 1, ["E307400"] = 4, ["E307000"] = 2, ["C307801"] = 1, ["E302600"] = 10, ["E307B01"] = 8 },
	[233] = { ["E305400"] = 48, ["E302500"] = 5, ["E307400"] = 10, ["E302600"] = 24, ["E000501"] = 6 },
	[234] = {
		["E302500"] = 3, ["E307400"] = 36, ["E307000"] = 2, ["C307801"] = 1, ["E302600"] = 28, ["E000501"] = 8,
		["E307B01"] = 12,
	},
	[235] = { ["E305400"] = 42, ["E000600"] = 4, ["E302500"] = 5, ["E307400"] = 16, ["E302600"] = 24 },
	[236] = {},
	[237] = {},
	[238] = { ["E305400"] = 42, ["E302500"] = 21, ["E302600"] = 23 },
	[239] = { ["E302500"] = 19, ["E307400"] = 22, ["C307801"] = 1, ["E302600"] = 4, ["E307B01"] = 2 },
	[240] = { ["E302500"] = 9, ["E307400"] = 18, ["E307200"] = 4, ["C307801"] = 1, ["E302600"] = 60, ["E307B01"] = 24 },
	[241] = { ["E302500"] = 7, ["E307400"] = 20, ["E307200"] = 4, ["C307801"] = 1, ["E307B01"] = 24 },
	[242] = { ["E302500"] = 7, ["E307400"] = 18, ["C307801"] = 1, ["E302600"] = 26, ["E307B01"] = 24, ["E307100"] = 6 },
	[243] = { ["E302500"] = 7, ["E307400"] = 24, ["C307800"] = 1, ["E302600"] = 22, ["E307B00"] = 22 },
	[244] = { ["E307400"] = 36, ["C307800"] = 1, ["E302600"] = 20, ["E307B00"] = 18 },
	[245] = {
		["E307400"] = 32, ["C307800"] = 1, ["E307200"] = 4, ["C307801"] = 1, ["E302600"] = 5, ["E307B00"] = 18,
		["E307B01"] = 22,
	},
	[246] = { ["E302500"] = 1, ["E307400"] = 56, ["E307200"] = 4, ["E302600"] = 10 },
	[247] = { ["E305400"] = 10, ["E302500"] = 1, ["E307400"] = 32, ["C307801"] = 1, ["E307B01"] = 22, ["E307100"] = 18 },
	[248] = { ["E305400"] = 10, ["E302500"] = 35, ["E307400"] = 50 },
	[249] = {
		["E302500"] = 1, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 10, ["E307B00"] = 52, ["E000202"] = 4,
		["E307B01"] = 26,
	},
	[250] = { ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 32, ["E307B00"] = 54, ["E307B01"] = 28 },
	[251] = { ["E302500"] = 1, ["C307800"] = 1, ["C307801"] = 1, ["E302600"] = 12, ["E307B00"] = 48, ["E307B01"] = 32 },
	[252] = { ["C307800"] = 1, ["C307801"] = 1, ["E307B00"] = 50, ["E307B01"] = 92 },
	[253] = { ["E305400"] = 76, ["E302500"] = 7, ["E307400"] = 14, ["C307801"] = 1, ["E307B01"] = 50 },
	[254] = { ["E305400"] = 76, ["E302500"] = 7, ["E307400"] = 14, ["C307800"] = 1, ["E307B00"] = 2 },
	[255] = { ["E305400"] = 70, ["E302500"] = 7, ["E307400"] = 20, ["C307800"] = 1, ["E302600"] = 1, ["E307B00"] = 2 },
}


--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.reset()
	_M.set_enabled(true)
end

function _M.set_enabled(value)
	_enabled = value
end

function _M.get_best_split_frame(split)
	return _M.splits[ROUTE][split]
end

function _M.get_final_split_frame()
	if ROUTE == "paladin" then
		return _M.splits[ROUTE]["Paladin"]
	else
		return _M.splits[ROUTE]["Zeromus Death"]
	end
end

function _M.get_inventory(formation)
	if _M.inventory[ROUTE][formation] then
		return _M.inventory[ROUTE][formation]
	elseif _M.inventory["no64-excalbur"][formation] then
		return _M.inventory["no64-excalbur"][formation]
	else
		return {}
	end
end

function _M.get_value(variable)
	if not FULL_RUN or not _enabled then
		return 0
	end

	if _M.routes[ROUTE][ENCOUNTER_SEED][variable] ~= nil then
		return _M.routes[ROUTE][ENCOUNTER_SEED][variable]
	else
		return 0
	end
end

return _M
