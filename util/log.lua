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

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

local function _log(message)
	message = string.format("%s :: %s", os.date("!%Y-%m-%d %X+0000"), message)
	console.log(message)

	if _file then
		_file:write(message)
		_file:write("\n")
		_file:flush()
	end
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.error(message)
	_log(string.format("ERROR :: %s", message))
end

function _M.warning(message)
	_log(string.format("WARNING :: %s", message))
end

function _M.log(message)
	_log(message)
end

function _M.reset()
	if _file then
		_file:close()
		_file = nil
	end

	_file, err = io.open(string.format("edge-%s.log", os.date("!%Y%m%d%H%M%S")), "w")
end

return _M
