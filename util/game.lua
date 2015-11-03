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

_M.character = {}
_M.enemy = {}

local memory = require "util.memory"

--------------------------------------------------------------------------------
-- Public Constants
--------------------------------------------------------------------------------

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

_M.HAND = {
	RIGHT = 0x00,
	LEFT  = 0x01,
}

_M.ITEM = {
	NONE         = 0x00,
	HELM = {
		TIARA    = 0x7B,
	},
	ITEM = {
		TENT     = 0xE2,
	},
	SHIELD = {
		SHADOW   = 0x62,
	},
	WEAPON = {
		CHANGE   = 0x0B,
		DANCING  = 0x3C,
		DARKNESS = 0x17,
		STAFF    = 0x0F,
	},
}

_M.MAGIC = {
	BLACK = {
		LIT1  = 0x23,
		STOP  = 0x2C,
	},
	WHITE = {
		CURE2 = 0x0F,
		LIFE1 = 0x13,
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
	return bit.band(memory.read("character", "id", slot), 0x0F)
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

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

function _M.character.get_stat(character, stat)
	return memory.read("character", stat, _M.character.get_slot(character))
end

function _M.character.get_weapon(character)
	local slot = _M.character.get_slot(character)
	local hand, weapon

	if bit.band(memory.read("character", "id", slot), 0x40) > 0 then
		return _M.HAND.LEFT, memory.read("character", "l_hand", slot)
	else
		return _M.HAND.RIGHT, memory.read("character", "r_hand", slot)
	end
end

function _M.enemy.get_stat(enemy, stat)
	return memory.read("enemy", stat, enemy)
end

return _M
