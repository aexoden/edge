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

local _file = nil
local _base_frame = nil

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _get_time()
	if _base_frame then
		local time = (emu.framecount() - _base_frame) / 60.0988

		return string.format("%s:%05.2f", os.date("!%H:%M", time), time % 60)
	else
		return string.format("%11s", "-")
	end
end

local function _log(message)
	message = string.format("%s :: %6s :: %s :: %s", os.date("!%Y-%m-%d %X+0000"), emu.framecount(), _get_time(), message)
	console.log(message)

	if _file then
		_file:write(message)
		_file:write("\n")
		_file:flush()
	end

	return true
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.error(message)
	return _log(string.format("ERROR :: %s", message))
end

function _M.warning(message)
	return _log(string.format("WARNING :: %s", message))
end

function _M.log(message)
	return _log(message)
end

function _M.start()
	_base_frame = emu.framecount()
end

function _M.reset()
	console.clear()
	
	if _file then
		_file:close()
		_file = nil
	end

	_base_frame = nil

	if FULL_RUN then
		_file, err = io.open(string.format("logs/edge-%s-%03d-%010d-%s.log", ROUTE, ENCOUNTER_SEED, SEED, os.date("!%Y%m%d-%H%M%S")), "w")
	end
end

return _M
