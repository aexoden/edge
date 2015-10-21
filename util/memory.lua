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

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

local _addresses = {
	counter = {
		walking = {f = mainmemory.read_u8,     address = 0x00067B, record_size = 1}
	},
	flag = {
		dialog  = {f = mainmemory.read_u8,     address = 0x00067D, record_size = 1},
		moving  = {f = mainmemory.read_u8,     address = 0x0006D5, record_size = 1},
		ready   = {f = mainmemory.read_u8,     address = 0x0006B1, record_size = 1},
	},
	map = {
		id      = {f = mainmemory.read_u16_be, address = 0x001701, record_size = 1},
		x       = {f = mainmemory.read_u8,     address = 0x001706, record_size = 1},
		y       = {f = mainmemory.read_u8,     address = 0x001707, record_size = 1},
	},
	menu = {
		open    = {f = mainmemory.read_u8,     address = 0x000500, record_size = 1},
		ready   = {f = mainmemory.read_u8,     address = 0x000302, record_size = 1},
		cursor  = {f = mainmemory.read_u8,     address = 0x001A76, record_size = 1},
	},
	menu_custom = {
		open    = {f = mainmemory.read_u8,     address = 0x00030A, record_size = 1},
		cursor  = {f = mainmemory.read_u8,     address = 0x001BA7, record_size = 1},
	}
}

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.read(section, key, index)
	local var = _addresses[section][key]

	if not index then
		index = 0
	end

	return var.f(var.address + index * var.record_size)
end

return _M
