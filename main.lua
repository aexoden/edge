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

local battle = require "ai.battle"
local bridge = require "util.bridge"
local dialog = require "util.dialog"
local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"
local sequence = require "ai.sequence"
local walk = require "action.walk"

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

TEST_MODE = false

local SEED = nil

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function _reset()
	log.reset()

	log.log("Edge Final Fantasy IV Speed Run Bot")
	log.log("-----------------------------------")
	log.log("Beginning New Run")

	bridge.reset()
	menu.reset()
	walk.reset()

	dialog.reset()
	battle.reset()

	if not TEST_MODE then
		local seed = SEED

		if not seed then
			math.randomseed(os.time())
			math.random()
			math.random()
			math.random()
			seed = math.random(0, 2147483646)
		end

		log.log(string.format("RNG Seed: %d", seed))
		math.randomseed(seed)
		math.random()
		math.random()
		math.random()
	end

	sequence.reset(not TEST_MODE)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

_reset()

--------------------------------------------------------------------------------
-- Main Loop
--------------------------------------------------------------------------------

while true do
	local result = dialog.cycle() or battle.cycle() or sequence.cycle()

	input.cycle()
	emu.frameadvance()
end
