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

local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"
local walk = require "action.walk"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _q = {}

--------------------------------------------------------------------------------
-- Sequences
--------------------------------------------------------------------------------

local function _sequence_prologue()
	-- Change Battle Speed/Battle Message
	table.insert(_q, {menu.open, {}})
	table.insert(_q, {menu.select, {menu.MENU.CUSTOM}})
	table.insert(_q, {menu.select_custom, {menu.MENU_CUSTOM.SPEED}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {menu.select_custom, {menu.MENU_CUSTOM.MESSAGE}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {menu.close_custom, {}})
	table.insert(_q, {menu.close, {}})

	-- Walk to and pick up tent
	table.insert(_q, {walk.walk, {43, 14, 9}})
	table.insert(_q, {walk.walk, {42, 8, 10}})
	table.insert(_q, {walk.walk, {42, 14, 10}})
	table.insert(_q, {walk.walk, {42, 14, 8}})
	table.insert(_q, {walk.walk, {42, 13, 8}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {42, 14, 8}})
	table.insert(_q, {walk.walk, {42, 14, 4}})
	table.insert(_q, {walk.walk, {42, 15, 4}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})

	-- Walk to Cecil's room
	table.insert(_q, {walk.walk, {42, 14, 4}})
	table.insert(_q, {walk.walk, {42, 14, 10}})
	table.insert(_q, {walk.walk, {42, 1, 10}})
	table.insert(_q, {walk.walk, {42, 1, 5}})
	table.insert(_q, {walk.walk, {36, 8, 13}})
	table.insert(_q, {walk.walk, {45, 2, 12}})
	table.insert(_q, {walk.walk, {36, 6, 18}})
	table.insert(_q, {walk.walk, {36, 6, 9}})
	table.insert(_q, {walk.walk, {50, 5, 4}})
	table.insert(_q, {walk.walk, {51, 6, 4}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {51, 9, 4}})
	table.insert(_q, {walk.walk, {52, 3, 4}})
end

local function _sequence_d_mist()
	-- Walk to Chocobo's Forest and get chocobo
	table.insert(_q, {walk.walk, {nil, 102, 160}})
	table.insert(_q, {walk.walk, {nil, 89, 160}})
	table.insert(_q, {walk.walk, {nil, 89, 163}})
	table.insert(_q, {walk.chase, {210, {6, 7, 8}}})

	-- Walk to the Misty Cave
	table.insert(_q, {walk.walk, {nil, 89, 147}})
	table.insert(_q, {walk.walk, {nil, 77, 147}})
	table.insert(_q, {walk.walk, {nil, 77, 145}})
	table.insert(_q, {walk.walk, {nil, 72, 145}})
	table.insert(_q, {walk.walk, {nil, 72, 137}})
	table.insert(_q, {walk.walk, {nil, 75, 137}})
	table.insert(_q, {walk.walk, {nil, 75, 133}})
	table.insert(_q, {walk.walk, {nil, 76, 133}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {walk.walk, {nil, 76, 132}})

	-- Walk through the Misty Cave
	table.insert(_q, {walk.walk, {108, 2, 27}})
	table.insert(_q, {walk.walk, {108, 11, 27}})
	table.insert(_q, {walk.walk, {108, 11, 28}})
	table.insert(_q, {walk.walk, {108, 12, 28}})
	table.insert(_q, {walk.walk, {108, 12, 29}})
	table.insert(_q, {walk.walk, {108, 13, 29}})
	table.insert(_q, {walk.walk, {108, 13, 30}})
	table.insert(_q, {walk.walk, {108, 20, 30}})
	table.insert(_q, {walk.walk, {108, 20, 25}})
	table.insert(_q, {walk.walk, {108, 13, 25}})
	table.insert(_q, {walk.walk, {108, 13, 21}})
	table.insert(_q, {walk.walk, {108, 6, 21}})
	table.insert(_q, {walk.walk, {108, 6, 18}})
	table.insert(_q, {walk.walk, {108, 4, 18}})
	table.insert(_q, {walk.walk, {108, 4, 7}})
	table.insert(_q, {walk.walk, {108, 16, 7}})
	table.insert(_q, {walk.walk, {108, 16, 11}})
	table.insert(_q, {walk.walk, {108, 19, 11}})
	table.insert(_q, {walk.walk, {108, 19, 16}})
	table.insert(_q, {walk.walk, {108, 23, 16}})
	table.insert(_q, {walk.walk, {108, 23, 19}})
	table.insert(_q, {walk.walk, {108, 24, 19}})
	table.insert(_q, {walk.walk, {108, 24, 20}})
	table.insert(_q, {walk.walk, {108, 27, 20}})
	table.insert(_q, {walk.walk, {108, 27, 2}})
end

local function _sequence_rydia()
	-- TODO: Detect and do something about the Mist Clip battle.

	-- Walk toward mist and begin the Mist Clip.
	table.insert(_q, {walk.walk, {nil, 86, 120}})
	table.insert(_q, {walk.walk, {nil, 86, 119}})
	table.insert(_q, {walk.walk, {nil, 86, 119}})
	table.insert(_q, {walk.walk, {nil, 95, 119}})
	table.insert(_q, {walk.step, {walk.DIRECTION.LEFT}})
	table.insert(_q, {menu.open, {input.DELAY.NONE}})
	table.insert(_q, {menu.select, {menu.MENU.ITEM}})
	table.insert(_q, {menu.select_item, {menu.ITEM.TENT, 1}})
	table.insert(_q, {menu.select_item, {menu.ITEM.TENT, 1}})
	table.insert(_q, {walk.walk, {nil, 95, 119, true}})
	table.insert(_q, {walk.step, {walk.DIRECTION.RIGHT}})
	table.insert(_q, {menu.open, {input.DELAY.NONE}})

	-- Remove Kain's Iron glove.
	table.insert(_q, {menu.select, {menu.MENU.EQUIP}})
	table.insert(_q, {menu.select_character, {menu.CHARACTER.KAIN}})
	table.insert(_q, {menu.select_equip, {menu.EQUIP.ARMS}})
	table.insert(_q, {menu.select_equip_item, {menu.ITEM.NONE, 1}})
	table.insert(_q, {menu.wait_frames, {5}})
	table.insert(_q, {menu.close, {}})

	-- Equip and unequip the Shadow shield.
	table.insert(_q, {menu.select, {menu.MENU.EQUIP}})
	table.insert(_q, {menu.select_character, {menu.CHARACTER.CECIL}})
	table.insert(_q, {menu.select_equip, {menu.EQUIP.L_HAND}})
	table.insert(_q, {menu.select_equip_item, {menu.ITEM.SHIELD.SHADOW, 1}})
	table.insert(_q, {menu.wait_frames, {5}})
	table.insert(_q, {menu.select_equip, {menu.EQUIP.L_HAND}})
	table.insert(_q, {menu.select_equip_item, {menu.ITEM.NONE, 1}})
	table.insert(_q, {menu.wait_frames, {5}})
	table.insert(_q, {menu.close, {}})

	-- Save and reset.
	table.insert(_q, {menu.select, {menu.MENU.SAVE}})
	table.insert(_q, {menu.select_save, {1}})
	table.insert(_q, {menu.confirm, {}})
	table.insert(_q, {input.press, {{"Reset"}, input.DELAY.NORMAL}})
	table.insert(_q, {menu.wait_frames, {132}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {menu.wait_frames, {132}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {menu.confirm, {}})

	-- Walk to the shop and buy Dancing daggers.
	table.insert(_q, {walk.walk, {nil, 98, 119}})
	table.insert(_q, {walk.walk, {nil, 97, 119}})
	table.insert(_q, {walk.walk, {1, 19, 16}})
	table.insert(_q, {walk.walk, {1, 19, 24}})
	table.insert(_q, {walk.walk, {1, 18, 24}})
	table.insert(_q, {walk.walk, {1, 18, 26}})
	table.insert(_q, {walk.walk, {1, 14, 26}})
	table.insert(_q, {walk.walk, {1, 14, 25}})
	table.insert(_q, {walk.walk, {225, 4, 5}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.shop.select, {menu.shop.MENU.SELL}})
	table.insert(_q, {menu.shop.select_count, {1}})
	table.insert(_q, {menu.shop.select_sell, {menu.ITEM.SHIELD.SHADOW}})
	table.insert(_q, {menu.wait_frames, {3}})
	table.insert(_q, {menu.confirm, {}})
	table.insert(_q, {menu.wait_frames, {3}})
	table.insert(_q, {menu.close, {}})
	table.insert(_q, {menu.shop.select, {menu.shop.MENU.BUY}})
	table.insert(_q, {menu.shop.select_count, {10}})
	table.insert(_q, {menu.shop.select_buy, {menu.ITEM.DAGGER.DANCING}})
	table.insert(_q, {menu.confirm, {}})
	table.insert(_q, {menu.wait_frames, {3}})
	table.insert(_q, {menu.close, {}})
	table.insert(_q, {menu.wait_frames, {3}})
	table.insert(_q, {menu.close, {}})

	-- Collect the Tiara and Change rod.
	table.insert(_q, {walk.walk, {225, 4, 10}})
	table.insert(_q, {walk.walk, {1, 14, 26}})
	table.insert(_q, {walk.walk, {1, 12, 26}})
	table.insert(_q, {walk.walk, {1, 12, 8}})
	table.insert(_q, {walk.walk, {1, 11, 8}})
	table.insert(_q, {walk.walk, {1, 11, 7}})
	table.insert(_q, {walk.walk, {15, 3, 13}})
	table.insert(_q, {walk.walk, {15, 3, 10}})
	table.insert(_q, {walk.walk, {15, 4, 10}})
	table.insert(_q, {walk.walk, {15, 4, 6}})
	table.insert(_q, {walk.walk, {15, 22, 6}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {15, 26, 6}})
	table.insert(_q, {walk.walk, {15, 26, 10}})
	table.insert(_q, {walk.walk, {15, 22, 10}})
	table.insert(_q, {walk.walk, {15, 22, 24}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {15, 22, 10}})
	table.insert(_q, {walk.walk, {15, 26, 10}})
	table.insert(_q, {walk.walk, {15, 26, 6}})
	table.insert(_q, {walk.walk, {15, 4, 6}})
	table.insert(_q, {walk.walk, {15, 4, 10}})
	table.insert(_q, {walk.walk, {15, 3, 10}})
	table.insert(_q, {walk.walk, {15, 3, 13}})
	table.insert(_q, {walk.walk, {15, 4, 13}})
	table.insert(_q, {walk.walk, {15, 4, 16}})
	table.insert(_q, {walk.walk, {1, 11, 10}})
	table.insert(_q, {walk.walk, {1, 12, 10}})
	table.insert(_q, {walk.walk, {1, 12, 16}})
	table.insert(_q, {walk.walk, {1, 8, 16}})
end

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _check_sequence()
	if #_q == 0 and walk.is_ready() and not walk.is_mid_tile() then
		local map_area = memory.read("walk", "map_area")
		local map_id = memory.read("walk", "map_id")
		local map_x = memory.read("walk", "x")
		local map_y = memory.read("walk", "y")

		if map_area == 3 and map_id == 43 and map_x == 14 and map_y == 5 then
			log.log("Beginning Sequence: Prologue")
			_sequence_prologue()
		elseif map_area == 0 and map_x == 102 and map_y == 158 then
			log.log("Beginning Sequence: D.Mist")
			_sequence_d_mist()
		elseif map_area == 0 and map_x == 84 and map_y == 120 then
			log.log("Beginning Sequence: Rydia")
			_sequence_rydia()
		end
	end
end

local function _execute_next_command()
	while true do
		local command = _q[1]

		if command then
			local result = command[1](unpack(command[2]))

			if result == nil or result == true then
				table.remove(_q, 1)
			end

			if result ~= nil then
				break
			end
		else
			break
		end
	end
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	_check_sequence()
	_execute_next_command()

	return true
end

function _M.reset()
	_q = {}
end

return _M
