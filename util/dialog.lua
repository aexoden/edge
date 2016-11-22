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

local bridge = require "util.bridge"
local game = require "util.game"
local input = require "util.input"
local memory = require "util.memory"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _mash_button = "P1 A"
local _pending_spoils

--------------------------------------------------------------------------------
-- Dialog Splits
--------------------------------------------------------------------------------

local _splits = {
	["Sage Tel"] = {message = "Tellah", done = false},
	["Prince E"] = {message = "Edward", done = false},
	["Palom th"] = {message = "Twins", done = false},
	["Cecil be"] = {message = "Paladin", done = false},
	["Ninja Ed"] = {message = "Edge", done = false},
	[" The Big"] = {message = "Big Whale", done = false},
	["Lost the"] = {message = "Lost the Dark Crystal!", done = false},
	["Lunarian"] = {message = "FuSoYa", done = false},
}

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _get_text(category, key, base, characters)
	local text = ""

	if not characters then
		characters = 24
	end

	for i = base, base + characters - 1 do
		local character = memory.read(category, key, i)

		if character then
			text = text .. character
		end
	end

	return text
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.is_dialog()
	local battle_dialog_state = memory.read("battle_dialog", "state")
	local dialog_height = memory.read("dialog", "height")
	local dialog_state = memory.read("dialog", "state")
	local dialog_prompt = memory.read("dialog", "prompt")
	local spoils = memory.read("dialog", "spoils_state") > 0

	if _pending_spoils == 1 and spoils then
		_pending_spoils = 2
	elseif _pending_spoils == 2 and memory.read("menu", "state") == 0 then
		_pending_spoils = nil
	end

	return battle_dialog_state == 1 or spoils or _pending_spoils ~= nil or dialog_height == 7 or (dialog_height > 0 and (dialog_state == 0 or dialog_prompt == 0))
end

function _M.cycle()
	if _M.is_dialog() then
		local text = _M.get_text(8)

		if _splits[text] and not _splits[text].done then
			bridge.split(_splits[text].message)
			_splits[text].done = true
		end

		input.press({_mash_button}, input.DELAY.MASH)

		return true
	end

	return false
end

function _M.get_battle_spell()
	if game.battle.get_type() == game.battle.TYPE.BACK_ATTACK then
		return _get_text("battle_dialog", "text", 0, 6)
	else
		return _get_text("battle_dialog", "text", 18, 6)
	end
end

function _M.get_battle_text(characters)
	return _get_text("battle_dialog", "text", 1, characters)
end

function _M.get_save_text(characters)
	return _get_text("menu_save", "text", 0, characters)
end

function _M.get_text(characters)
	return _get_text("dialog", "text", 0, characters)
end

function _M.reset()
	for key, _ in pairs(_splits) do
		_splits[key].done = false
	end

	_pending_spoils = nil

	_M.set_mash_button("P1 A")
end

function _M.set_mash_button(mash_button)
	_mash_button = mash_button
	return true
end

function _M.set_pending_spoils()
	_pending_spoils = 1
end

return _M
