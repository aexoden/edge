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

local log = require "util.log"

memory.usememorydomain("CARTROM")

--------------------------------------------------------------------------------
-- Text Conversion
--------------------------------------------------------------------------------

local _characters = {
	[0x3F] = " ",
	[0x42] = "A",
	[0x43] = "B",
	[0x44] = "C",
	[0x45] = "D",
	[0x46] = "E",
	[0x47] = "F",
	[0x48] = "G",
	[0x49] = "H",
	[0x4A] = "I",
	[0x4B] = "J",
	[0x4C] = "K",
	[0x4D] = "L",
	[0x4E] = "M",
	[0x4F] = "N",
	[0x50] = "O",
	[0x51] = "P",
	[0x52] = "Q",
	[0x53] = "R",
	[0x54] = "S",
	[0x55] = "T",
	[0x56] = "U",
	[0x57] = "V",
	[0x58] = "W",
	[0x59] = "X",
	[0x5A] = "Y",
	[0x5B] = "Z",
	[0x5C] = "a",
	[0x5D] = "b",
	[0x5E] = "c",
	[0x5F] = "d",
	[0x60] = "e",
	[0x61] = "f",
	[0x62] = "g",
	[0x63] = "h",
	[0x64] = "i",
	[0x65] = "j",
	[0x66] = "k",
	[0x67] = "l",
	[0x68] = "m",
	[0x69] = "n",
	[0x6A] = "o",
	[0x6B] = "p",
	[0x6C] = "q",
	[0x6D] = "r",
	[0x6E] = "s",
	[0x6F] = "t",
	[0x70] = "u",
	[0x71] = "v",
	[0x72] = "w",
	[0x73] = "x",
	[0x74] = "y",
	[0x75] = "z",
	[0x80] = "0",
	[0x81] = "1",
	[0x82] = "2",
	[0x83] = "3",
	[0x84] = "4",
	[0x85] = "5",
	[0x86] = "6",
	[0x87] = "7",
	[0x88] = "8",
	[0x89] = "9",
	[0xC2] = "-",
	[0xC3] = ".",
	[0xC8] = ":",
	[0xFF] = " ",
}

local function _read_character(address)
	return(_characters[mainmemory.read_u8(address)])
end

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

local _addresses = {
	battle = {
		action_type         = {f = mainmemory.read_u8,     address = 0x0034C7, record_size = {0x01, 0x01}},
		action_index        = {f = mainmemory.read_u8,     address = 0x0034C8, record_size = {0x01, 0x01}},
		actor_group         = {f = mainmemory.read_u8,     address = 0x0034C2, record_size = {0x01, 0x01}},
		actor_slot          = {f = mainmemory.read_u8,     address = 0x0034C3, record_size = {0x01, 0x01}},
		active              = {f = mainmemory.read_u8,     address = 0x007508, record_size = {0x01, 0x01}},
		back                = {f = mainmemory.read_u8,     address = 0x003581, record_size = {0x01, 0x01}},
		back2               = {f = mainmemory.read_u8,     address = 0x00030B, record_size = {0x01, 0x01}},
		calculations_left   = {f = mainmemory.read_u8,     address = 0x00354D, record_size = {0x01, 0x01}},
		damage              = {f = mainmemory.read_u16_le, address = 0x0034D4, record_size = {0x02, 0x01}},
		dropped_gp          = {f = mainmemory.read_u24_le, address = 0x00359A, record_size = {0x01, 0x01}},
		ending              = {f = mainmemory.read_u8,     address = 0x0000A8, record_size = {0x01, 0x01}},
		enemies             = {f = mainmemory.read_u8,     address = 0x0029CD, record_size = {0x01, 0x01}},
		flash               = {f = mainmemory.read_u8,     address = 0x00EF87, record_size = {0x01, 0x01}},
		formation           = {f = mainmemory.read_u16_le, address = 0x001800, record_size = {0x01, 0x01}},
		enemy_target        = {f = mainmemory.read_u8,     address = 0x0000CE, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x000203, record_size = {0x01, 0x01}},
		monster_cursor      = {f = mainmemory.read_u8,     address = 0x006CE3, record_size = {0x01, 0x01}},
		party_level         = {f = mainmemory.read_u8,     address = 0x0038D4, record_size = {0x01, 0x01}},
		enemy_level         = {f = mainmemory.read_u8,     address = 0x0038D5, record_size = {0x01, 0x01}},
		target_group        = {f = mainmemory.read_u8,     address = 0x0034C4, record_size = {0x01, 0x01}},
		target_mask         = {f = mainmemory.read_u8,     address = 0x0034C5, record_size = {0x01, 0x01}},
		type                = {f = mainmemory.read_u8,     address = 0x0038D8, record_size = {0x01, 0x01}},
	},
	battle_dialog = {
		state               = {f = mainmemory.read_u8,     address = 0x00F43A, record_size = {0x01, 0x01}},
		text                = {f = _read_character,        address = 0x00DB6C, record_size = {0x02, 0x01}},
	},
	battle_menu = {
		command             = {f = mainmemory.read_u8,     address = 0x003303, record_size = {0x1C, 0x04}},
		cursor              = {f = mainmemory.read_u8,     address = 0x000060, record_size = {0x01, 0x01}},
		item_count          = {f = mainmemory.read_u8,     address = 0x00321C, record_size = {0x04, 0x01}},
		item_id             = {f = mainmemory.read_u8,     address = 0x00321B, record_size = {0x04, 0x01}},
		item_selected       = {f = mainmemory.read_u8,     address = 0x00EF94, record_size = {0x01, 0x01}},
		menu                = {f = mainmemory.read_u8,     address = 0x001823, record_size = {0x01, 0x01}},
		open                = {f = mainmemory.read_u8,     address = 0x0000D7, record_size = {0x01, 0x01}},
		opening             = {f = mainmemory.read_u8,     address = 0x001820, record_size = {0x01, 0x01}},
		slot                = {f = mainmemory.read_u8,     address = 0x001822, record_size = {0x01, 0x01}},
		spell_id            = {f = mainmemory.read_u8,     address = 0x002C7B, record_size = {0x120, 0x04}},
		subcursor           = {f = mainmemory.read_u8,     address = 0x000063, record_size = {0x01, 0x01}},
		target              = {f = mainmemory.read_u8,     address = 0x00EF8D, record_size = {0x01, 0x01}},
		target_valid        = {f = mainmemory.read_u8,     address = 0x00F123, record_size = {0x01, 0x01}},
		target_up_down      = {f = mainmemory.read_u8,     address = 0x0029CF, record_size = {0x02, 0x01}},
		target_left_right   = {f = mainmemory.read_u8,     address = 0x0029D0, record_size = {0x02, 0x01}},
		target_default_down = {f = mainmemory.read_u8,     address = 0x00F34B, record_size = {0x01, 0x01}},
		target_default_up   = {f = mainmemory.read_u8,     address = 0x00F343, record_size = {0x01, 0x01}},
	},
	dialog = {
		height              = {f = mainmemory.read_u8,     address = 0x0006DF, record_size = {0x01, 0x01}},
		prompt              = {f = mainmemory.read_u8,     address = 0x000654, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x00067D, record_size = {0x01, 0x01}},
		cursor_x            = {f = mainmemory.read_u8,     address = 0x00068B, record_size = {0x01, 0x01}},
		cursor_y            = {f = mainmemory.read_u8,     address = 0x00068C, record_size = {0x01, 0x01}},
		cursor_scroll       = {f = mainmemory.read_u8,     address = 0x0006BA, record_size = {0x01, 0x01}},
		cursor_wait         = {f = mainmemory.read_u8,     address = 0x000689, record_size = {0x01, 0x01}},
		height_lower        = {f = mainmemory.read_u8,     address = 0x0006DA, record_size = {0x01, 0x01}},
		item_id             = {f = mainmemory.read_u8,     address = 0x000712, record_size = {0x02, 0x01}},
		item_count          = {f = mainmemory.read_u8,     address = 0x000713, record_size = {0x02, 0x01}},
		spoils_item         = {f = mainmemory.read_u8,     address = 0x001804, record_size = {0x01, 0x01}},
		spoils_state        = {f = mainmemory.read_u8,     address = 0x001BC6, record_size = {0x01, 0x01}},
		text                = {f = _read_character,        address = 0x000774, record_size = {0x01, 0x01}},
	},
	enemy = {
		type                = {f = mainmemory.read_u8,     address = 0x0029B5, record_size = {0x01, 0x01}},
		id                  = {f = mainmemory.read_u8,     address = 0x0029AD, record_size = {0x01, 0x01}},
		kills               = {f = mainmemory.read_u8,     address = 0x003585, record_size = {0x01, 0x01}},
	},
	game = {
		counter             = {f = mainmemory.read_u8,     address = 0x000FFF, record_size = {0x01, 0x01}},
		frames              = {f = mainmemory.read_u8,     address = 0x0016A3, record_size = {0x01, 0x01}},
		timer               = {f = mainmemory.read_u24_le, address = 0x0016A4, record_size = {0x01, 0x01}},
	},
	menu = {
		character           = {f = mainmemory.read_u8,     address = 0x0001E7, record_size = {0x01, 0x01}},
		cursor              = {f = mainmemory.read_u8,     address = 0x001A76, record_size = {0x01, 0x01}},
		cursor_state        = {f = mainmemory.read_u8,     address = 0x000302, record_size = {0x01, 0x01}},
		selected            = {f = mainmemory.read_u8,     address = 0x001A77, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x000500, record_size = {0x01, 0x01}},
		subcursor_state     = {f = mainmemory.read_u8,     address = 0x000312, record_size = {0x01, 0x01}},
		submenu_open        = {f = mainmemory.read_u8,     address = 0x0002F0, record_size = {0x01, 0x01}},
		cursor3_state       = {f = mainmemory.read_u8,     address = 0x00031E, record_size = {0x01, 0x01}},
		active              = {f = mainmemory.read_u8,     address = 0x001BAD, record_size = {0x01, 0x01}},
	},
	menu_custom = {
		cursor              = {f = mainmemory.read_u8,     address = 0x001BA7, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x001BAA, record_size = {0x01, 0x01}},
	},
	menu_equip = {
		cursor              = {f = mainmemory.read_u8,     address = 0x001B37, record_size = {0x01, 0x01}},
		phase               = {f = mainmemory.read_u8,     address = 0x001BAD, record_size = {0x01, 0x01}},
		scroll              = {f = mainmemory.read_u8,     address = 0x001B2A, record_size = {0x03, 0x01}},
		slot                = {f = mainmemory.read_u8,     address = 0x0001E8, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x001B1F, record_size = {0x01, 0x01}},
		subcursor_y         = {f = mainmemory.read_u8,     address = 0x001B28, record_size = {0x03, 0x01}},
		subcursor_x         = {f = mainmemory.read_u8,     address = 0x001B29, record_size = {0x03, 0x01}},
	},
	menu_form = {
		selected            = {f = mainmemory.read_u8,     address = 0x001B27, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x001BB8, record_size = {0x01, 0x01}},
	},
	menu_item = {
		character           = {f = mainmemory.read_u8,     address = 0x001B3E, record_size = {0x01, 0x01}},
		cursor_x            = {f = mainmemory.read_u8,     address = 0x001B22, record_size = {0x01, 0x01}},
		cursor_y            = {f = mainmemory.read_u8,     address = 0x001B23, record_size = {0x01, 0x01}},
		item_id             = {f = mainmemory.read_u8,     address = 0x001440, record_size = {0x02, 0x01}},
		item_count          = {f = mainmemory.read_u8,     address = 0x001441, record_size = {0x02, 0x01}},
		scroll              = {f = mainmemory.read_u8,     address = 0x001B1A, record_size = {0x01, 0x01}},
		selectable          = {f = mainmemory.read_u8,     address = 0x0002ED, record_size = {0x01, 0x01}},
		selected            = {f = mainmemory.read_u8,     address = 0x001B19, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x001BC9, record_size = {0x01, 0x01}},
	},
	menu_magic = {
		character           = {f = mainmemory.read_u8,     address = 0x001B8A, record_size = {0x01, 0x01}},
		cursor              = {f = mainmemory.read_u8,     address = 0x001B81, record_size = {0x01, 0x01}},
		list                = {f = mainmemory.read_u8,     address = 0x001B7E, record_size = {0x01, 0x01}},
		selecting           = {f = mainmemory.read_u8,     address = 0x001B87, record_size = {0x01, 0x01}},
		spell               = {f = mainmemory.read_u8,     address = 0x001560, record_size = {0x18, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x001BC4, record_size = {0x01, 0x01}},
		subcursor           = {f = mainmemory.read_u8,     address = 0x00011D, record_size = {0x01, 0x01}},
		unknown             = {f = mainmemory.read_u8,     address = 0x001BC4, record_size = {0x01, 0x01}},
	},
	menu_save = {
		cursor              = {f = mainmemory.read_u8,     address = 0x001A3C, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x001B47, record_size = {0x01, 0x01}},
		text                = {f = _read_character,        address = 0x00A686, record_size = {0x02, 0x01}},
	},
	menu_shop = {
		cursor              = {f = mainmemory.read_u8,     address = 0x001B79, record_size = {0x01, 0x01}},
		subcursor           = {f = mainmemory.read_u8,     address = 0x001B7A, record_size = {0x01, 0x01}},
		quantity            = {f = mainmemory.read_u8,     address = 0x001B7C, record_size = {0x01, 0x01}},
		buy                 = {f = mainmemory.read_u8,     address = 0x001B7B, record_size = {0x01, 0x01}},
		buy_item            = {f = mainmemory.read_u8,     address = 0x001B55, record_size = {0x04, 0x01}},
		buy_state           = {f = mainmemory.read_u8,     address = 0x00C79A, record_size = {0x01, 0x01}},
		sell_y              = {f = mainmemory.read_u8,     address = 0x001B94, record_size = {0x01, 0x01}},
		sell_x              = {f = mainmemory.read_u8,     address = 0x001B95, record_size = {0x01, 0x01}},
		sell_scroll         = {f = mainmemory.read_u8,     address = 0x001B96, record_size = {0x01, 0x01}},
		sell_state          = {f = mainmemory.read_u8,     address = 0x00B79A, record_size = {0x01, 0x01}},
	},
	npc = {
		count               = {f = mainmemory.read_u8,     address = 0x0008FE, record_size = {0x01, 0x01}},
		visible             = {f = mainmemory.read_u8,     address = 0x00090B, record_size = {0x0F, 0x01}},
		x                   = {f = mainmemory.read_u8,     address = 0x000904, record_size = {0x0F, 0x01}},
		y                   = {f = mainmemory.read_u8,     address = 0x000906, record_size = {0x0F, 0x01}},
	},
	party = {
		formation           = {f = mainmemory.read_u8,     address = 0x0016A8, record_size = {0x01, 0x01}},
		formation_battle    = {f = mainmemory.read_u8,     address = 0x00F014, record_size = {0x01, 0x01}},
		gp                  = {f = mainmemory.read_u24_le, address = 0x0016A0, record_size = {0x01, 0x01}},
	},
	walk = {
		battle              = {f = mainmemory.read_u8,     address = 0x00067E, record_size = {0x01, 0x01}},
		chocobo_x           = {f = mainmemory.read_u8,     address = 0x001710, record_size = {0x01, 0x01}},
		chocobo_y           = {f = mainmemory.read_u8,     address = 0x001711, record_size = {0x01, 0x01}},
		direction           = {f = mainmemory.read_u8,     address = 0x001705, record_size = {0x01, 0x01}},
		frames              = {f = mainmemory.read_u8,     address = 0x00067B, record_size = {0x01, 0x01}},
		index               = {f = mainmemory.read_u8,     address = 0x000686, record_size = {0x01, 0x01}},
		map_area            = {f = mainmemory.read_u8,     address = 0x001700, record_size = {0x01, 0x01}},
		map_history_index   = {f = mainmemory.read_s16_le, address = 0x00172C, record_size = {0x01, 0x01}},
		map_id              = {f = mainmemory.read_u16_be, address = 0x001701, record_size = {0x01, 0x01}},
		seed                = {f = mainmemory.read_u8,     address = 0x0017EF, record_size = {0x01, 0x01}},
		state               = {f = mainmemory.read_u8,     address = 0x0006B1, record_size = {0x01, 0x01}},
		transition          = {f = mainmemory.read_u8,     address = 0x000679, record_size = {0x01, 0x01}},
		vehicle             = {f = mainmemory.read_u8,     address = 0x001704, record_size = {0x01, 0x01}},
		x                   = {f = mainmemory.read_u8,     address = 0x001706, record_size = {0x01, 0x01}},
		y                   = {f = mainmemory.read_u8,     address = 0x001707, record_size = {0x01, 0x01}},
	}
}

local _stats = {
	id              = {f = mainmemory.read_u8,     address = 0x000000},
	level           = {f = mainmemory.read_u8,     address = 0x000002},
	status          = {f = mainmemory.read_u32_be, address = 0x000003},
	hp              = {f = mainmemory.read_u16_le, address = 0x000007},
	hp_max          = {f = mainmemory.read_u16_le, address = 0x000009},
	mp              = {f = mainmemory.read_u16_le, address = 0x00000B},
	mp_max          = {f = mainmemory.read_u16_le, address = 0x00000D},
	agility         = {f = mainmemory.read_u8,     address = 0x000015},
	stamina         = {f = mainmemory.read_u8,     address = 0x000016},
	will            = {f = mainmemory.read_u8,     address = 0x000018},
	defense_base    = {f = mainmemory.read_u8,     address = 0x00002A},
	head            = {f = mainmemory.read_u8,     address = 0x000030},
	body            = {f = mainmemory.read_u8,     address = 0x000031},
	arms            = {f = mainmemory.read_u8,     address = 0x000032},
	r_hand          = {f = mainmemory.read_u8,     address = 0x000033},
	r_hand_count    = {f = mainmemory.read_u8,     address = 0x000034},
	l_hand          = {f = mainmemory.read_u8,     address = 0x000035},
	l_hand_count    = {f = mainmemory.read_u8,     address = 0x000036},
	exp             = {f = mainmemory.read_u24_le, address = 0x000037},
	speed_modifier  = {f = mainmemory.read_u8,     address = 0x00003B},
}

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.read(category, key, index, subindex)
	if _addresses[category] and _addresses[category][key] then
		local var = _addresses[category][key]

		if not index then
			index = 0
		end

		if not subindex then
			subindex = 0
		end

		return var.f(var.address + index * var.record_size[1] + subindex * var.record_size[2])
	else
		log.error(string.format("Attempted to read invalid memory address: %s.%s", category, key))

		return 0
	end
end

function _M.read_stat(index, stat, battle)
	if _stats[stat] then
		local var = _stats[stat]

		if battle then
			return var.f(0x002000 + var.address + index * 0x80)
		else
			return var.f(0x001000 + var.address + index * 0x40)
		end
	else
		log.error(string.format("Attempted to read invalid stat: %s", stat))
	end

	return 0
end

return _M
