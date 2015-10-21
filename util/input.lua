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
-- Variables
--------------------------------------------------------------------------------

_q = {}
_previous = {}

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	if #_q > 0 then
		local buttons = table.remove(_q, 1)

		for k, v in pairs(buttons) do
			if _previous[k] then
				buttons[k] = nil
			end
		end

		joypad.set(buttons)

		_previous = buttons
	else
		_previous = {}
	end
end

function _M.press(button, delay)
	if not delay then
		delay = 0
	end

	while not _q[delay + 1] do
		_q[#_q + 1] = {}
	end

	_q[delay + 1][button] = true
end

return _M
