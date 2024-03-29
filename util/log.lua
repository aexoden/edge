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
local _final_frame = nil

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _log(message)
	message = string.format("%s :: %6s :: %s :: %s :: %s", os.date("!%Y-%m-%d %H:%M:%S+0000"), emu.framecount(), _M.get_time(true), _M.game_time(), message)
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

function _M.game_time()
	local time = mainmemory.read_u24_le(0x0016A4)
	local frames = mainmemory.read_u8(0x0016A3)

	if time > 36000 then
		return string.format("%11s", "-")
	else
		return string.format("%02d:%02d:%02d.%02d", time // 3600, (time // 60) % 60, time % 60, frames)
	end
end

function _M.get_time(actual)
	local end_frame = _final_frame

	if not end_frame or actual then
		end_frame = emu.framecount()
	end

	if _base_frame then
		local time = (end_frame - _base_frame) * 655171.0 / 39375000

		return string.format("%02d:%02d:%05.2f", time // 3600, (time // 60) % 60, time % 60)
	else
		return string.format("%11s", "-")
	end
end

function _M.freeze()
	_final_frame = emu.framecount()
end

function _M.clear()
	console.clear()
end

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
	_final_frame = nil

	local err

	if FULL_RUN then
		_file, err = io.open(string.format("logs/edge-%s-%03d-%010d-%s.log", ROUTE, ENCOUNTER_SEED, SEED, os.date("!%Y%m%d-%H%M%S")), "w")
	end
end

return _M
