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

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- Specify a number to do a specific run. Set this value to nil to do random runs.
SEED = nil

-- Enable/Disable LiveSplit integration (requires luasocket and LiveSplit)
LIVESPLIT = false

-- Automatically create save states at the beginning of each battle.
SAVESTATE = false

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

local battle = require "ai.battle"
local bridge = require "util.bridge"
local dialog = require "util.dialog"
local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"
local sequence = require "ai.sequence"
local walk = require "action.walk"

FULL_RUN = emu.framecount() == 1

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function _set_seed()
	local seed = SEED

	if not seed then
		math.randomseed(os.time())
		math.random()
		math.random()
		math.random()
		seed = math.random(0, 2147483646)
	end

	math.randomseed(seed)
	math.random()
	math.random()
	math.random()

	return seed
end

local function _reset()
	SEED = _set_seed()

	log.reset()

	log.log("Edge Final Fantasy IV Speed Run Bot")
	log.log("-----------------------------------")

	if FULL_RUN then
		log.log("Beginning Full Run")
		log.log(string.format("RNG Seed: %d", SEED))
	else
		log.log("Beginning Test Mode")
	end

	bridge.reset()
	menu.reset()
	walk.reset()

	dialog.reset()
	battle.reset()

	sequence.reset()
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

_reset()

--------------------------------------------------------------------------------
-- Main Loop
--------------------------------------------------------------------------------

while true do
	dialog.cycle()

	if sequence.is_active() then
		local result = battle.cycle() or sequence.cycle()
	end

	input.cycle()
	emu.frameadvance()
end
