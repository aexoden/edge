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
local socket = nil

if CONFIG.LIVESPLIT then
	socket = require "socket"
end

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _q = {}
local _socket = nil

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _connect()
	_socket = socket.connect("127.0.0.1", 16834)

	if _socket then
		_socket:settimeout(0.005)
		_socket:setoption("keepalive", true)
		log.log("Connected to LiveSplit")
		return true
	else
		log.error("Could not connect to LiveSplit")
	end
end

local function _send(message)
	if not _socket and FULL_RUN and CONFIG.LIVESPLIT then
		_connect()
	end

	if _socket then
		_socket:send(message .. "\r\n")
		return true
	else
		return not (CONFIG.LIVESPLIT and FULL_RUN)
	end
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.send(message)
	table.insert(_q, message)
	return true
end

function _M.split(message)
	log.log("Split: " .. message)

	return _M.send("startorsplit")
end

function _M.cycle()
	if #_q > 0 then
		if _send(_q[1]) then
			table.remove(_q, 1)
		end
	end
end

function _M.reset()
	return _M.send("reset")
end

return _M
