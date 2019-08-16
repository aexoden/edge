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
-- Setup
--------------------------------------------------------------------------------

CONFIG = require "config"

local battle = require "ai.battle"
local bridge = require "util.bridge"
local dialog = require "util.dialog"
local input = require "util.input"
local route = require "util.route"
local log = require "util.log"
local menu = require "action.menu"
local sequence = require "ai.sequence"
local walk = require "action.walk"

FULL_RUN = emu.framecount() == 1
INITIALIZED = false

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function _get_version()
	return "v0.0.8-176"
end

local function _set_route()
	ROUTES = {"no64-excalbur", "no64-rosa", "nocw", "paladin"}
	NO64_ROUTES = {"no64-excalbur", "no64-rosa"}

	math.randomseed(os.time())

	if CONFIG.ROUTE then
		if CONFIG.ROUTE == "no64" then
			return NO64_ROUTES[math.random(#NO64_ROUTES)]
		else
			return CONFIG.ROUTE
		end
	else
		return ROUTES[math.random(#ROUTES)]
	end
end

local function _set_encounter_seed()
	if CONFIG.ENCOUNTER_SEED then
		return CONFIG.ENCOUNTER_SEED
	else
		return math.random(0, 255)
	end
end

local function _set_seed()
	local seed = CONFIG.SEED

	if not seed then
		math.randomseed(os.time())
		math.random()
		math.random()
		math.random()
		seed = math.random(0, 2147483646)
	end

	if SEED and CONFIG.AUTOMATIC and CONFIG.SEED ~= nil then
		seed = SEED + 1
	end

	math.randomseed(seed)
	math.random()
	math.random()
	math.random()

	return seed
end

local function _reset()
	ROUTE = _set_route()
	ENCOUNTER_SEED = _set_encounter_seed()
	SEED = _set_seed()

	log.reset()

	log.log("Edge Final Fantasy IV Speed Run Bot")
	log.log("-----------------------------------")
	log.log(string.format("Version: %s", _get_version()))

	if FULL_RUN then
		log.log("Beginning Full Run")
		log.log(string.format("Route: %s", ROUTE))
		log.log(string.format("Encounter Seed: %d", ENCOUNTER_SEED))
		log.log(string.format("RNG Seed: %d", SEED))
	else
		log.log("Beginning Test Mode")
	end

	bridge.reset()
	menu.reset()
	route.reset()
	walk.reset()

	dialog.reset()
	battle.reset()

	sequence.reset()

	INITIALIZED = true
end

--------------------------------------------------------------------------------
-- Main Loop
--------------------------------------------------------------------------------

while true do
	if emu.framecount() == 1 or not INITIALIZED then
		FULL_RUN = emu.framecount() == 1
		_reset()
	end

	dialog.cycle()

	if not battle.cycle() and sequence.is_active() then
		sequence.cycle()
	end

	if FULL_RUN and sequence.is_end() then
		log.log("Rebooting...")
		client.reboot_core()
	end

	if CONFIG.OVERLAY then
		sequence.draw_overlay()
	end

	bridge.cycle()
	input.cycle()
	emu.frameadvance()
end
