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
-- Constants
--------------------------------------------------------------------------------

_M.DELAY = {
	NONE = 0,
	MASH = 1,
	NORMAL = 2,
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

_next = nil

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	if _next then
		if _next.frames == 0 then
			joypad.set(_next.buttons)
			_next = nil
		else
			_next.frames = _next.frames - 1
		end
	end
end

function _M.press(buttons, delay_type)
	if _next then
		return false
	end

	if not delay_type then
		delay_type = _M.DELAY.NORMAL
	end

	delay = 0

	if delay_type == _M.DELAY.MASH then
		delay = math.random(3, 5)
	elseif delay_type == _M.DELAY.NORMAL then
		delay = math.random(5, 15)
	end

	send_buttons = {}

	for k, v in pairs(buttons) do
		send_buttons[v] = true
	end

	_next = {
		frames = delay,
		buttons = send_buttons
	}

	return true
end

return _M
