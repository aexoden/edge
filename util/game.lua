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

_M.battle = {}
_M.character = {}
_M.enemy = {}
_M.item = {}
_M.magic = {}

local memory = require "util.memory"

--------------------------------------------------------------------------------
-- Public Constants
--------------------------------------------------------------------------------

_M.battle.ACTOR = {
	PARTY   = 0x00,
	ENEMY   = 0x80,
}

_M.battle.ACTION = {
	NONE    =  0x00,
	COMMAND =  0x10,
	ITEM    =  0x20,
	MAGIC   =  0x40,
	ATTACK  =  0x80,
	CRITICAL = 0x84,
}

_M.battle.FORMATION = {
	MAGE     = 96,
	GRIND    = 200,
	ELEMENTS = 220,
	CPU      = 221,
	D_MIST   = 222,
	OCTOMAMM = 223,
	ANTLION  = 224,
	MOMBOMB  = 225,
	MILON    = 226,
	MILON_Z  = 227,
	BAIGAN   = 228,
	KAINAZZO = 229,
	DARK_ELF = 231,
    SISTERS  = 232,
	VALVALIS = 234,
	GIRL     = 236,
	OFFICER  = 237,
	WATERHAG = 239,
	DRAGOON  = 241,
	KARATE   = 242,
	D_KNIGHT = 246,
	GENERAL  = 247,
	WEEPER   = 248,
	GARGOYLE = 249,
	GUARDS   = 250,
	EBLAN    = 254,
	RUBICANT = 255,
	DARK_IMP = 256,
	RED_D_1  = 409,
	RED_D_2  = 410,
	RED_D_B  = 411,
	RED_D_3  = 415,
	CALBRENA = 423,
	LUGAE1   = 425,
	ZEMUS    = 435,
	LUGAE2   = 437,
	GOLBEZ   = 438,
	ZEROMUS  = 439,
	FLAMEDOG = 451,
}

_M.battle.TYPE = {
	NORMAL       = 0,
	STRIKE_FIRST = 1,
	SURPRISED    = 2,
	BACK_ATTACK  = 3,
}

_M.CHARACTER = {
	CECIL  = 0,
	KAIN   = 1,
	RYDIA  = 2,
	TELLAH = 3,
	EDWARD = 4,
	ROSA   = 5,
	YANG   = 6,
	PALOM  = 7,
	POROM  = 8,
	CID    = 9,
	EDGE   = 10,
	FUSOYA = 11,
	GOLBEZ = 12,
}

_M.ENEMY = {
	FIGHTER  = 0x2C,
	BOMB     = 0x55,
	GRAYBOMB = 0x56,
	CAL      = 0xB2,
	BRENA    = 0xD2,
	GHAST    = 0xD3,
}

_M.EQUIP = {
	R_HAND = 0x00,
	L_HAND = 0x01,
	HEAD   = 0x02,
	BODY   = 0x03,
	ARMS   = 0x04,
}

_M.FORMATION = {
	THREE_FRONT = 0,
	TWO_FRONT   = 1,
}

_M.INVENTORY = {
	BATTLE = 0,
	FIELD = 1,
	DIALOG = 2,
}

_M.ITEM = {
	NONE         = 0x00,
	SORT         = 0xFE,
	TRASHCAN     = 0xFF,
	ARMOR = {
		BL_BELT  = 0x99,
		GAEA     = 0x8F,
		KARATE   = 0x98,
		PRISONER = 0x96,
		SAMURAI  = 0x8A,
		WHITE    = 0x93,
		WIZARD   = 0x90,
	},
	ARMS = {
		IRON     = 0x9C,
		PALADIN  = 0xA0,
	},
	CLAW = {
		CATCLAW  = 0x06,
		ICECLAW  = 0x02,
		THUNDER  = 0x03,
	},
	HELM = {
		BANDANNA = 0x7E,
		CAP      = 0x77,
		GAEA     = 0x79,
		HEADBAND = 0x7D,
		SAMURAI  = 0x74,
		TIARA    = 0x7B,
		WIZARD   = 0x7A,
	},
	ITEM = {
		ADAMANT  = 0xF7,
		BARON    = 0xEF,
		CARROT   = 0xEB,
		CRYSTAL  = 0xC8,
		DARKNESS = 0xF5,
		CURE2    = 0xCF,
		EARTH    = 0xF1,
		ELIXIR   = 0xD3,
		ETHER1   = 0xD1,
		HEAL     = 0xDD,
		LIFE     = 0xD4,
		MAGMA    = 0xF2,
		RAT      = 0xF6,
		SANDRUBY = 0xF0,
		TENT     = 0xE2,
		TOWER    = 0xFA,
		TRASHCAN = 0xFF,
	},
	RING = {
		PROTECT  = 0xAE,
		RUNE     = 0xAB,
		SILVER   = 0xA9,
		STRENGTH = 0xAA,
	},
	SHIELD = {
		ICE      = 0x67,
		PALADIN  = 0x64,
		SHADOW   = 0x62,
	},
	STAR = {
		NINJA    = 0x41,
	},
	WEAPON = {
		BLACK    = 0x18,
		BLIZZARD = 0x26,
		CHANGE   = 0x0B,
		DANCING  = 0x3C,
		DARKNESS = 0x17,
		EXCALBUR = 0x1B,
		FIRE     = 0x1C,
		ICEBRAND = 0x1D,
		LEGEND   = 0x19,
		LUNAR    = 0x13,
		STAFF    = 0x0F,
		THUNDER  = 0x0A,
	},
}

_M.MAGIC = {
	BLACK = {
		PIGGY = 0x1A,
		WARP  = 0x1B,
		FIRE1 = 0x1D,
		FIRE2 = 0x1E,
		FIRE3 = 0x1F,
		ICE1  = 0x20,
		ICE2  = 0x21,
		ICE3  = 0x22,
		LIT1  = 0x23,
		LIT3  = 0x25,
		VIRUS = 0x26,
		WEAK  = 0x27,
		QUAKE = 0x28,
		STOP  = 0x2C,
		METEO = 0x2F,
		NUKE  = 0x30,
	},
	CALL = {
		SHIVA = 0x36,
		TITAN = 0x39,
	},
	NINJA = {
		FLOOD = 0x43,
		BLITZ = 0x44,
		SMOKE = 0x45,
	},
	WHITE = {
		HOLD  = 0x01,
		MUTE  = 0x02,
		SLOW  = 0x07,
		BERSK = 0x09,
		WALL  = 0x0A,
		WHITE = 0x0B,
		CURE1 = 0x0E,
		CURE2 = 0x0F,
		CURE4 = 0x11,
		LIFE1 = 0x13,
		LIFE2 = 0x14,
		EXIT  = 0x16,
		SIGHT = 0x17,
	},
}

_M.STATUS = {
	CRITICAL = 0x00000001,
	HIDING   = 0x00000080,
	JUMPING  = 0x00000200,
	PARALYZE = 0x00200000,
	POISON   = 0x01000000,
	MUTE     = 0x04000000,
	PIG      = 0x08000000,
	STONE    = 0x40000000,
}

--------------------------------------------------------------------------------
-- Private Constants
--------------------------------------------------------------------------------

local _CHARACTERS = {
	[0x01] = _M.CHARACTER.CECIL,
	[0x02] = _M.CHARACTER.KAIN,
	[0x03] = _M.CHARACTER.RYDIA,
	[0x04] = _M.CHARACTER.TELLAH,
	[0x05] = _M.CHARACTER.EDWARD,
	[0x06] = _M.CHARACTER.ROSA,
	[0x07] = _M.CHARACTER.YANG,
	[0x08] = _M.CHARACTER.PALOM,
	[0x09] = _M.CHARACTER.POROM,
	[0x0A] = _M.CHARACTER.TELLAH,
	[0x0B] = _M.CHARACTER.CECIL,
	[0x0C] = _M.CHARACTER.TELLAH,
	[0x0D] = _M.CHARACTER.YANG,
	[0x0E] = _M.CHARACTER.CID,
	[0x0F] = _M.CHARACTER.KAIN,
	[0x10] = _M.CHARACTER.ROSA,
	[0x11] = _M.CHARACTER.RYDIA,
	[0x12] = _M.CHARACTER.EDGE,
	[0x13] = _M.CHARACTER.FUSOYA,
	[0x14] = _M.CHARACTER.KAIN,
	[0x15] = _M.CHARACTER.GOLBEZ,
}

local _CHARACTER_NAMES = {
	[_M.CHARACTER.CECIL]  = "Cecil",
	[_M.CHARACTER.CID]    = "Cid",
	[_M.CHARACTER.EDGE]   = "Edge",
	[_M.CHARACTER.EDWARD] = "Edward",
	[_M.CHARACTER.FUSOYA] = "FuSoYa",
	[_M.CHARACTER.GOLBEZ] = "Golbez",
	[_M.CHARACTER.KAIN]   = "Kain",
	[_M.CHARACTER.PALOM]  = "Palom",
	[_M.CHARACTER.POROM]  = "Porom",
	[_M.CHARACTER.ROSA]   = "Rosa",
	[_M.CHARACTER.RYDIA]  = "Rydia",
	[_M.CHARACTER.TELLAH] = "Tellah",
	[_M.CHARACTER.YANG]   = "Yang",
}

local _ITEMS = {
	[0x3C] = "Dancing",
	[0xC0] = "FireBomb",
	[0xC2] = "Lit-Bolt",
	[0xC8] = "Crystal",
	[0xCF] = "Cure2",
	[0xD3] = "Elixir",
	[0xD4] = "Life",
	[0xDD] = "Heal",
	[0xEB] = "Carrot",
	[0xFF] = "TrashCan",
}

local _MAGIC = {
	[0x01] = "Hold",
	[0x02] = "Mute",
	[0x03] = "Charm",
	[0x04] = "Blink",
	[0x05] = "Armor",
	[0x06] = "Shell",
	[0x07] = "Slow",
	[0x08] = "Fast",
	[0x09] = "Bersk",
	[0x0A] = "Wall",
	[0x0B] = "White",
	[0x0D] = "Peep",
	[0x0E] = "Cure1",
	[0x0F] = "Cure2",
	[0x11] = "Cure4",
	[0x13] = "Life1",
	[0x1D] = "Fire1",
	[0x1E] = "Fire2",
	[0x1F] = "Fire3",
	[0x20] = "Ice-1",
	[0x21] = "Ice-2",
	[0x22] = "Ice-3",
	[0x23] = "Lit-1",
	[0x24] = "Lit-2",
	[0x25] = "Lit-3",
	[0x26] = "Virus",
	[0x27] = "Weak",
	[0x28] = "Quake",
	[0x2C] = "Stop",
	[0x2D] = "Drain",
	[0x2F] = "Meteo",
	[0x30] = "Nuke",
	[0x40] = "Comet",
	[0x41] = "Flare",
	[0x42] = "Flame",
	[0x43] = "Flood",
	[0x45] = "Smoke",
	[0x52] = "Shiva",
	[0x55] = "Titan",
	[0x5E] = "W.Meteo",
	[0x68] = "Curse",
	[0x69] = "Ray",
	[0x70] = "Whisper",
	[0x71] = "Entangle",
	[0x74] = "ColdMist",
	[0x75] = "Explode (0x75)",
	[0x77] = "Hold Gas",
	[0x78] = "Gas",
	[0x79] = "Poison",
	[0x7A] = "Maser",
	[0x7C] = "Demolish",
	[0x7D] = "Blk.Hole",
	[0x84] = "Remedy",
	[0x86] = "Heal",
	[0x87] = "Big Bang",
	[0x88] = "Vampire",
	[0x8C] = "Alert",
	[0x8D] = "Call",
	[0x92] = "Retreat",
	[0x94] = "Beam",
	[0x96] = "Fire",
	[0x9D] = "Wave",
	[0x9E] = "Tornado",
	[0x9F] = "Laser",
	[0xA0] = "Explode (0xA0)",
	[0xA1] = "Quake",
	[0xA2] = "Emission",
	[0xA4] = "Glare",
}

local _CHARACTER_IDS = {}

for id, character in ipairs(_CHARACTERS) do
	if not _CHARACTER_IDS[character] then
		_CHARACTER_IDS[character] = {}
	end

	_CHARACTER_IDS[character][id] = true
end

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _get_character_id(slot)
	return bit.band(memory.read_stat(slot, "id", false), 0x1F)
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.battle.get_type()
	local type = _M.battle.TYPE.NORMAL
	local value = memory.read("battle", "type")

	if value == 1 then
		type = _M.battle.TYPE.STRIKE_FIRST
	elseif value == 128 then
		if memory.read("battle", "back") == 8 or memory.read("battle", "back2") == 113 then
			type = _M.battle.TYPE.BACK_ATTACK
		else
			type = _M.battle.TYPE.SURPRISED
		end
	end

	return type
end

function _M.character.get_character(slot)
	return _CHARACTERS[_get_character_id(slot)]
end

function _M.character.get_name(character)
	return _CHARACTER_NAMES[character]
end

function _M.character.get_slot(character)
	for i = 0, 9 do
		if _CHARACTER_IDS[character][_get_character_id(i)] then
			return i
		end
	end
end

function _M.character.get_index(slot)
	if slot == 1 then
		return 0
	elseif slot == 3 then
		return 1
	elseif slot == 0 then
		return 2
	elseif slot == 4 then
		return 3
	elseif slot == 2 then
		return 4
	end
end

function _M.character.get_slot_from_index(index)
	if index == 0 then
		return 1
	elseif index == 1 then
		return 3
	elseif index == 2 then
		return 0
	elseif index == 3 then
		return 4
	elseif index == 4 then
		return 2
	end
end

function _M.character.get_stat(character, stat, battle)
	local slot = _M.character.get_slot(character)

	if slot then
		return memory.read_stat(_M.character.get_slot(character), stat, battle)
	else
		return nil
	end
end

function _M.character.is_status(character, status)
	return bit.band(memory.read_stat(_M.character.get_slot(character), "status", true), status) > 0
end

function _M.character.is_status_by_slot(slot, status)
	return bit.band(memory.read_stat(slot, "status", true), status) > 0
end

function _M.character.get_equipment(slot, location, battle)
	if location == _M.EQUIP.R_HAND then
		return memory.read_stat(slot, "r_hand", battle), memory.read_stat(slot, "r_hand_count", battle)
	elseif location == _M.EQUIP.L_HAND then
		return memory.read_stat(slot, "l_hand", battle), memory.read_stat(slot, "l_hand_count", battle)
	elseif location == _M.EQUIP.HEAD then
		return memory.read_stat(slot, "head", battle), 1
	elseif location == _M.EQUIP.BODY then
		return memory.read_stat(slot, "body", battle), 1
	elseif location == _M.EQUIP.ARMS then
		return memory.read_stat(slot, "arms", battle), 1
	end
end

function _M.character.get_weapon(character, battle)
	local slot = _M.character.get_slot(character)
	local hand, weapon

	if bit.band(memory.read_stat(slot, "id", battle), 0x40) > 0 then
		return _M.EQUIP.L_HAND, memory.read_stat(slot, "l_hand", battle)
	else
		return _M.EQUIP.R_HAND, memory.read_stat(slot, "r_hand", battle)
	end
end

function _M.enemy.get_id(index)
	local type = memory.read("enemy", "type", index)

	if type < 0xFF then
		local id = memory.read("enemy", "id", type)

		if id < 0xFF then
			return id
		end
	end

	return nil
end

function _M.enemy.get_stat(index, stat)
	return memory.read_stat(index + 5, stat, true)
end

function _M.enemy.get_closest(enemy)
	for i = 7, 0, -1 do
		if _M.enemy.get_id(i) == enemy then
			return i
		end
	end
end

function _M.enemy.get_strongest(enemy)
	local strongest = {nil, 0}

	for i = 0, 7 do
		if _M.enemy.get_id(i) == enemy then
			local hp = _M.enemy.get_stat(i, "hp")

			if hp >= strongest[2] then
				strongest = {i, hp}
			end
		end
	end

	return strongest[1]
end

function _M.enemy.get_weakest(enemy)
	local weakest = {nil, 999999}

	for i = 0, 7 do
		if _M.enemy.get_id(i) == enemy then
			local hp = _M.enemy.get_stat(i, "hp")

			if hp <= weakest[2] then
				weakest = {i, hp}
			end
		end
	end

	return weakest[1]
end

function _M.item.get_count(item, inventory)
	local category

	if inventory == _M.INVENTORY.BATTLE then
		category = "battle_menu"
	elseif inventory == _M.INVENTORY.DIALOG then
		category = "dialog"
	else
		category = "menu_item"
	end

	local count = 0

	for i = 0, 47 do
		if memory.read(category, "item_id", i) == item then
			count = count + memory.read(category, "item_count", i)
		end
	end

	return count
end

function _M.item.get_index(item, index, inventory)
	local category, key

	if inventory == _M.INVENTORY.BATTLE then
		category, key = "battle_menu", "item_id"
	elseif inventory == _M.INVENTORY.DIALOG then
		category, key = "dialog", "item_id"
	else
		category, key = "menu_item", "item_id"
	end

	local count = 0

	local best = nil
	local best_count = 256

	for i = 0, 47 do
		if memory.read(category, key, i) == item then
			if index then
				if count == index then
					return i
				end
			else
				local number = memory.read(category, "item_count", i)

				if number < best_count then
					best = i
					best_count = number
				end
			end

			count = count + 1
		end
	end

	if best then
		return best
	end

	return nil
end

function _M.item.get_description(item)
	local result = _ITEMS[item]

	if not result then
		result = string.format("Item #%02X", item)
	end

	return result
end

function _M.magic.get_spell_description(spell)
	local result = _MAGIC[spell]

	if not result then
		result = string.format("Spell #%02X", spell)
	end

	return result
end

return _M
