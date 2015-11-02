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
	[0x4F] = "N",
	[0x55] = "T",
	[0x6A] = "o",
	[0x70] = "u",
}

local function _read_character(address)
	return(_characters[mainmemory.read_u8(address)])
end

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

local _addresses = {
	battle = {
		formation     = {f = mainmemory.read_u16_le, address = 0x001800, record_size = {0x01, 0x01}},
		state         = {f = mainmemory.read_u8,     address = 0x000203, record_size = {0x01, 0x01}},
	},
	battle_dialog = {
		state         = {f = mainmemory.read_u8,     address = 0x00F43A, record_size = {0x01, 0x01}},
		text          = {f = _read_character,        address = 0x00DB6E, record_size = {0x02, 0x01}},
	},
	battle_menu = {
		command       = {f = mainmemory.read_u8,     address = 0x003303, record_size = {0x1C, 0x04}},
		cursor        = {f = mainmemory.read_u8,     address = 0x000060, record_size = {0x01, 0x01}},
		item_count    = {f = mainmemory.read_u8,     address = 0x00321C, record_size = {0x04, 0x01}},
		item_id       = {f = mainmemory.read_u8,     address = 0x00321B, record_size = {0x04, 0x01}},
		menu          = {f = mainmemory.read_u8,     address = 0x001823, record_size = {0x01, 0x01}},
		opening       = {f = mainmemory.read_u8,     address = 0x001820, record_size = {0x01, 0x01}},
		slot          = {f = mainmemory.read_s8,     address = 0x0000D0, record_size = {0x01, 0x01}},
		subcursor     = {f = mainmemory.read_u8,     address = 0x000063, record_size = {0x01, 0x01}},
		target        = {f = mainmemory.read_u8,     address = 0x00EF8D, record_size = {0x01, 0x01}},
	},
	character = {
		id            = {f = mainmemory.read_u8,     address = 0x002000, record_size = {0x80, 0x01}},
		hp            = {f = mainmemory.read_u16_be, address = 0x002007, record_size = {0x80, 0x01}},
	},
	dialog = {
		height        = {f = mainmemory.read_u8,     address = 0x0006DF, record_size = {0x01, 0x01}},
		prompt        = {f = mainmemory.read_u8,     address = 0x000654, record_size = {0x01, 0x01}},
		state         = {f = mainmemory.read_u8,     address = 0x00067D, record_size = {0x01, 0x01}},
	},
	menu = {
		character     = {f = mainmemory.read_u8,     address = 0x0001E7, record_size = {0x01, 0x01}},
		cursor        = {f = mainmemory.read_u8,     address = 0x001A76, record_size = {0x01, 0x01}},
		ready         = {f = mainmemory.read_u8,     address = 0x000302, record_size = {0x01, 0x01}},
		state         = {f = mainmemory.read_u8,     address = 0x000500, record_size = {0x01, 0x01}},
		active        = {f = mainmemory.read_u8,     address = 0x001BAD, record_size = {0x01, 0x01}},
	},
	menu_custom = {
		cursor        = {f = mainmemory.read_u8,     address = 0x001BA7, record_size = {0x01, 0x01}},
		state         = {f = mainmemory.read_u8,     address = 0x00030A, record_size = {0x01, 0x01}},
	},
	menu_equip = {
		cursor        = {f = mainmemory.read_u8,     address = 0x001B37, record_size = {0x01, 0x01}},
		subcursor_y   = {f = mainmemory.read_u8,     address = 0x001B28, record_size = {0x03, 0x01}},
		subcursor_x   = {f = mainmemory.read_u8,     address = 0x001B29, record_size = {0x03, 0x01}},
		scroll        = {f = mainmemory.read_u8,     address = 0x001B2A, record_size = {0x03, 0x01}},
	},
	menu_item = {
		cursor_x      = {f = mainmemory.read_u8,     address = 0x001B22, record_size = {0x01, 0x01}},
		cursor_y      = {f = mainmemory.read_u8,     address = 0x001B23, record_size = {0x01, 0x01}},
		item_id       = {f = mainmemory.read_u8,     address = 0x001440, record_size = {0x02, 0x01}},
		item_count    = {f = mainmemory.read_u8,     address = 0x001441, record_size = {0x02, 0x01}},
		scroll        = {f = mainmemory.read_u8,     address = 0x001B1A, record_size = {0x01, 0x01}},
		state         = {f = mainmemory.read_u8,     address = 0x001BC9, record_size = {0x01, 0x01}},
	},
	menu_save = {
		cursor        = {f = mainmemory.read_u8,     address = 0x001A3C, record_size = {0x01, 0x01}},
		state         = {f = mainmemory.read_u8,     address = 0x001B47, record_size = {0x01, 0x01}},
	},
	menu_shop = {
		cursor        = {f = mainmemory.read_u8,     address = 0x001B79, record_size = {0x01, 0x01}},
		subcursor     = {f = mainmemory.read_u8,     address = 0x001B7A, record_size = {0x01, 0x01}},
		count         = {f = mainmemory.read_u8,     address = 0x001B7C, record_size = {0x01, 0x01}},
		buy           = {f = mainmemory.read_u8,     address = 0x001B7B, record_size = {0x01, 0x01}},
		buy_item      = {f = mainmemory.read_u8,     address = 0x001B55, record_size = {0x04, 0x01}},
		buy_state     = {f = mainmemory.read_u8,     address = 0x00C79A, record_size = {0x01, 0x01}},
		sell_y        = {f = mainmemory.read_u8,     address = 0x001B94, record_size = {0x01, 0x01}},
		sell_x        = {f = mainmemory.read_u8,     address = 0x001B95, record_size = {0x01, 0x01}},
		sell_scroll   = {f = mainmemory.read_u8,     address = 0x001B96, record_size = {0x01, 0x01}},
		sell_state    = {f = mainmemory.read_u8,     address = 0x00B79A, record_size = {0x01, 0x01}},
	},
	monster = {
		hp            = {f = mainmemory.read_u16_be, address = 0x002287, record_size = {0x80, 0x01}},
	},
	npc = {
		x             = {f = mainmemory.read_u8,     address = 0x000904, record_size = {0x0F, 0x01}},
		y             = {f = mainmemory.read_u8,     address = 0x000906, record_size = {0x0F, 0x01}},
	},
	walk = {
		direction     = {f = mainmemory.read_u8,     address = 0x001705, record_size = {0x01, 0x01}},
		frames        = {f = mainmemory.read_u8,     address = 0x00067B, record_size = {0x01, 0x01}},
		map_area      = {f = mainmemory.read_u8,     address = 0x001700, record_size = {0x01, 0x01}},
		map_id        = {f = mainmemory.read_u16_be, address = 0x001701, record_size = {0x01, 0x01}},
		state         = {f = mainmemory.read_u8,     address = 0x0006B1, record_size = {0x01, 0x01}},
		vehicle       = {f = mainmemory.read_u8,     address = 0x001704, record_size = {0x01, 0x01}},
		x             = {f = mainmemory.read_u8,     address = 0x001706, record_size = {0x01, 0x01}},
		y             = {f = mainmemory.read_u8,     address = 0x001707, record_size = {0x01, 0x01}},
	}
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

return _M
