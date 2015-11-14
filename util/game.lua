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

local memory = require "util.memory"

--------------------------------------------------------------------------------
-- Public Constants
--------------------------------------------------------------------------------

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
}

_M.ENEMY = {
	FIGHTER  = 0x2C,
	BOMB     = 0x55,
	GRAYBOMB = 0x56,
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
	ARMOR = {
		GAEA     = 0x8F,
		KARATE   = 0x98,
	},
	ARMS = {
		PALADIN  = 0xA0,
	},
	CLAW = {
		ICECLAW  = 0x02,
		THUNDER  = 0x03,
	},
	HELM = {
		CAP      = 0x77,
		GAEA     = 0x79,
		HEADBAND = 0x7D,
		TIARA    = 0x7B,
	},
	ITEM = {
		BARON    = 0xEF,
		CURE2    = 0xCF,
		ETHER1   = 0xD1,
		HEAL     = 0xDD,
		LIFE     = 0xD4,
		SANDRUBY = 0xF0,
		TENT     = 0xE2,
	},
	RING = {
		SILVER   = 0xA9,
	},
	SHIELD = {
		PALADIN  = 0x64,
		SHADOW   = 0x62,
	},
	WEAPON = {
		BLACK    = 0x18,
		CHANGE   = 0x0B,
		DANCING  = 0x3C,
		DARKNESS = 0x17,
		LEGEND   = 0x19,
		STAFF    = 0x0F,
		THUNDER  = 0x0A,
	},
}

_M.MAGIC = {
	BLACK = {
		PIGGY = 0x1A,
		LIT1  = 0x23,
		STOP  = 0x2C,
		METEO = 0x2F,
	},
	WHITE = {
		CURE1 = 0x0E,
		CURE2 = 0x0F,
		CURE4 = 0x11,
		LIFE1 = 0x13,
		SIGHT = 0x17,
	},
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
	return bit.band(memory.read("character", "id", slot), 0x1F)
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

function _M.character.get_slot(character)
	for i = 0, 4 do
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

function _M.character.get_stat(character, stat)
	return memory.read("character", stat, _M.character.get_slot(character))
end

function _M.character.get_equipment(slot, location)
	if location == _M.EQUIP.R_HAND then
		return memory.read("character", "r_hand", slot), memory.read("character", "r_hand_count", slot)
	elseif location == _M.EQUIP.L_HAND then
		return memory.read("character", "l_hand", slot), memory.read("character", "l_hand_count", slot)
	elseif location == _M.EQUIP.HEAD then
		return memory.read("character", "head", slot), 1
	elseif location == _M.EQUIP.BODY then
		return memory.read("character", "body", slot), 1
	elseif location == _M.EQUIP.ARMS then
		return memory.read("character", "arms", slot), 1
	end
end

function _M.character.get_weapon(character)
	local slot = _M.character.get_slot(character)
	local hand, weapon

	if bit.band(memory.read("character", "id", slot), 0x40) > 0 then
		return _M.EQUIP.L_HAND, memory.read("character", "l_hand", slot)
	else
		return _M.EQUIP.R_HAND, memory.read("character", "r_hand", slot)
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
	return memory.read("enemy", stat, index)
end

function _M.enemy.get_closest(enemy)
	for i = 7, 0, -1 do
		if _M.enemy.get_id(i) == enemy then
			return i
		end
	end
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

function _M.item.get_index(item, index, inventory)
	local category, key

	if inventory == _M.INVENTORY.BATTLE then
		category, key = "battle_menu", "item_id"
	elseif inventory == _M.INVENTORY.DIALOG then
		category, key = "dialog", "item_id"
	else
		category, key = "menu_item", "item_id"
	end

	if not index then
		index = 0
	end

	local count = 0

	for i = 0, 47 do
		if memory.read(category, key, i) == item then
			if count == index then
				return i
			end

			count = count + 1
		end
	end

	return nil
end

return _M
