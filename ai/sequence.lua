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

local dialog = require "util.dialog"
local game = require "util.game"
local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"
local walk = require "action.walk"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

_M.state = {
	multi_change = false,
}

local _q = nil

--------------------------------------------------------------------------------
-- Sequences
--------------------------------------------------------------------------------

local function _sequence_prologue()
	-- Change Battle Speed/Battle Message
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.custom.open, {}})
	table.insert(_q, {menu.field.custom.select, {menu.field.custom.CHOICE.SPEED}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {menu.field.custom.select, {menu.field.custom.CHOICE.MESSAGE}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {menu.field.custom.close, {}})
	table.insert(_q, {menu.field.close, {}})

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

local function _sequence_girl()
	-- TODO: Detect and do something about the Mist Clip battle.

	-- Walk toward mist and begin the Mist Clip.
	table.insert(_q, {walk.walk, {nil, 86, 120}})
	table.insert(_q, {walk.walk, {nil, 86, 119}})
	table.insert(_q, {walk.walk, {nil, 86, 119}})
	table.insert(_q, {walk.walk, {nil, 95, 119}})
	table.insert(_q, {walk.step, {walk.DIRECTION.LEFT}})
	table.insert(_q, {menu.field.open, {input.DELAY.NONE}})
	table.insert(_q, {menu.field.item.open, {}})
	table.insert(_q, {menu.field.item.select, {game.ITEM.ITEM.TENT}})
	table.insert(_q, {menu.field.item.select, {game.ITEM.ITEM.TENT}})
	table.insert(_q, {walk.walk, {nil, 95, 119}})
	table.insert(_q, {walk.step, {walk.DIRECTION.RIGHT}})
	table.insert(_q, {menu.field.open, {input.DELAY.NONE}})

	-- Remove Kain's Iron arms.
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.KAIN}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.close, {}})

	-- Equip and unequip the Shadow shield.
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.SHIELD.SHADOW}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.close, {}})

	-- Save and reset.
	table.insert(_q, {menu.field.save.save, {1}})
	table.insert(_q, {input.press, {{"Reset"}, input.DELAY.NORMAL}})
	table.insert(_q, {menu.wait, {132}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {menu.wait, {132}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {menu.confirm, {}})

	-- Walk to the shop and open the shopping menu.
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

	-- Sell the Shadow shield.
	table.insert(_q, {menu.shop.sell.open, {1}})
	table.insert(_q, {menu.shop.sell.sell, {game.ITEM.SHIELD.SHADOW}})
	table.insert(_q, {menu.shop.sell.close, {}})

	-- Buy 10 Dancing daggers.
	table.insert(_q, {menu.shop.buy.open, {10}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.WEAPON.DANCING}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

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

local function _sequence_officer()
	table.insert(_q, {walk.walk, {nil, 103, 117}})
	table.insert(_q, {walk.walk, {nil, 104, 117}})
	table.insert(_q, {walk.walk, {nil, 104, 109}})
	table.insert(_q, {walk.walk, {nil, 125, 109}})
	table.insert(_q, {walk.walk, {nil, 125, 104}})
	table.insert(_q, {walk.walk, {2, 15, 26}})
end

local function _sequence_tellah()
	-- Equip the Tiara on Rydia.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.RYDIA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.TIARA}})
	table.insert(_q, {menu.field.equip.close, {}})

	-- Change formation.
	table.insert(_q, {menu.field.form.move, {game.CHARACTER.RYDIA, 1}})
	table.insert(_q, {menu.field.close, {}})

	-- Visit Rosa.
	table.insert(_q, {walk.walk, {16, 18, 12}})
	table.insert(_q, {walk.walk, {16, 18, 14}})
	table.insert(_q, {walk.walk, {16, 20, 14}})
	table.insert(_q, {walk.walk, {16, 20, 17}})
	table.insert(_q, {walk.walk, {2, 14, 18, true}})
	table.insert(_q, {walk.walk, {2, 18, 18, true}})
	table.insert(_q, {walk.walk, {2, 18, 16, true}})
	table.insert(_q, {walk.walk, {2, 24, 16, true}})
	table.insert(_q, {walk.walk, {2, 24, 15, true}})
	table.insert(_q, {walk.walk, {2, 28, 15, true}})
	table.insert(_q, {walk.walk, {2, 28, 13, true}})
	table.insert(_q, {dialog.set_mash_button, {"P1 B"}})
	table.insert(_q, {walk.walk, {18, 4, 6}})

	-- Leave Kaipo and head to Tellah.
	table.insert(_q, {walk.walk, {18, 6, 5}})
	table.insert(_q, {dialog.set_mash_button, {"P1 A"}})
	table.insert(_q, {walk.walk, {18, 4, 5}})
	table.insert(_q, {walk.walk, {18, 4, 18}})
	table.insert(_q, {walk.walk, {2, 23, 14, true}})
	table.insert(_q, {walk.walk, {2, 23, 19, true}})
	table.insert(_q, {walk.walk, {2, 23, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 26, true}})
	table.insert(_q, {walk.walk, {2, 15, 26, true}})
	table.insert(_q, {walk.walk, {2, 15, 30, true}})
	table.insert(_q, {walk.walk, {2, 16, 30}})
	table.insert(_q, {walk.walk, {2, 16, 31}})
	table.insert(_q, {walk.walk, {nil, 135, 104}})
	table.insert(_q, {walk.walk, {nil, 135, 84}})
	table.insert(_q, {walk.walk, {nil, 138, 84}})
	table.insert(_q, {walk.walk, {nil, 138, 83}})
	table.insert(_q, {walk.walk, {111, 26, 28}})
	table.insert(_q, {walk.walk, {111, 21, 28}})
	table.insert(_q, {walk.walk, {111, 21, 25}})
	table.insert(_q, {walk.walk, {111, 15, 25}})
	table.insert(_q, {walk.walk, {111, 15, 22}})
	table.insert(_q, {walk.walk, {111, 7, 22}})
	table.insert(_q, {walk.walk, {111, 7, 16}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {111, 7, 13}})
end

local function _sequence_octomamm()
	-- Walk to the Watery Pass Save Room.
	table.insert(_q, {walk.walk, {111, 6, 13}})
	table.insert(_q, {walk.walk, {111, 6, 10}})
	table.insert(_q, {walk.walk, {111, 7, 10}})
	table.insert(_q, {walk.walk, {111, 7, 7}})
	table.insert(_q, {walk.walk, {111, 4, 7}})
	table.insert(_q, {walk.walk, {111, 4, 6}})
	table.insert(_q, {walk.walk, {111, 2, 6}})
	table.insert(_q, {walk.walk, {111, 2, 2}})
	table.insert(_q, {walk.walk, {112, 26, 21}})
	table.insert(_q, {walk.walk, {112, 29, 21}})
	table.insert(_q, {walk.walk, {112, 29, 13}})
	table.insert(_q, {walk.walk, {112, 28, 13}})
	table.insert(_q, {walk.walk, {112, 28, 9}})
	table.insert(_q, {walk.walk, {112, 26, 9}})
	table.insert(_q, {walk.walk, {112, 26, 12}})
	table.insert(_q, {walk.walk, {112, 23, 12}})
	table.insert(_q, {walk.walk, {112, 23, 19}})
	table.insert(_q, {walk.walk, {112, 24, 19}})
	table.insert(_q, {walk.walk, {112, 24, 25}})
	table.insert(_q, {walk.walk, {112, 22, 25}})
	table.insert(_q, {walk.walk, {112, 22, 20}})
	table.insert(_q, {walk.walk, {112, 18, 20}})
	table.insert(_q, {walk.walk, {112, 18, 25}})
	table.insert(_q, {walk.walk, {112, 12, 25}})
	table.insert(_q, {walk.walk, {112, 12, 27}})
	table.insert(_q, {walk.walk, {112, 10, 27}})
	table.insert(_q, {walk.walk, {112, 10, 28}})
	table.insert(_q, {walk.walk, {112, 5, 28}})
	table.insert(_q, {walk.walk, {112, 5, 19}})
	table.insert(_q, {walk.walk, {112, 2, 19}})
	table.insert(_q, {walk.walk, {112, 2, 17}})
	table.insert(_q, {walk.walk, {84, 4, 10}})

	-- Walk to the Darkness sword chest.
	table.insert(_q, {walk.walk, {84, 4, 2}})
	table.insert(_q, {walk.walk, {112, 2, 8}})
	table.insert(_q, {walk.walk, {112, 10, 8}})
	table.insert(_q, {walk.walk, {112, 10, 12}})
	table.insert(_q, {walk.walk, {112, 8, 12}})
	table.insert(_q, {walk.walk, {112, 8, 15}})
	table.insert(_q, {walk.walk, {112, 12, 15}})
	table.insert(_q, {walk.walk, {112, 12, 16}})
	table.insert(_q, {walk.walk, {112, 13, 16}})
	table.insert(_q, {walk.walk, {112, 13, 17}})
	table.insert(_q, {walk.walk, {112, 16, 17}})
	table.insert(_q, {walk.walk, {112, 16, 7}})
	table.insert(_q, {walk.walk, {113, 22, 9}})
	table.insert(_q, {walk.walk, {113, 22, 13}})
	table.insert(_q, {walk.walk, {113, 15, 13}})
	table.insert(_q, {walk.walk, {113, 15, 18}})
	table.insert(_q, {walk.walk, {113, 7, 18}})
	table.insert(_q, {walk.walk, {113, 7, 17}})
	table.insert(_q, {walk.walk, {113, 6, 17}})
	table.insert(_q, {walk.walk, {113, 6, 9}})
	table.insert(_q, {walk.walk, {114, 13, 17}})
	table.insert(_q, {walk.walk, {114, 11, 17}})
	table.insert(_q, {walk.walk, {114, 11, 14}})
	table.insert(_q, {walk.walk, {114, 7, 14}})
	table.insert(_q, {walk.walk, {114, 7, 10}})
	table.insert(_q, {walk.walk, {115, 10, 16}})
	table.insert(_q, {walk.walk, {115, 13, 16}})
	table.insert(_q, {walk.walk, {115, 13, 9}})
	table.insert(_q, {walk.walk, {115, 21, 9}})
	table.insert(_q, {walk.walk, {115, 21, 11}})
	table.insert(_q, {walk.walk, {115, 23, 11}})
	table.insert(_q, {walk.walk, {115, 23, 19}})
	table.insert(_q, {walk.walk, {115, 21, 19}})
	table.insert(_q, {walk.walk, {115, 21, 17}})
	table.insert(_q, {walk.walk, {115, 18, 17}})
	table.insert(_q, {walk.interact, {}})

	-- Walk to Octomamm.
	table.insert(_q, {walk.walk, {115, 21, 17}})
	table.insert(_q, {walk.walk, {115, 21, 19}})
	table.insert(_q, {walk.walk, {115, 23, 19}})
	table.insert(_q, {walk.walk, {115, 23, 11}})
	table.insert(_q, {walk.walk, {115, 24, 11}})
	table.insert(_q, {walk.walk, {115, 24, 8}})
	table.insert(_q, {walk.walk, {nil, 135, 78}})
	table.insert(_q, {walk.walk, {nil, 135, 73}})
	table.insert(_q, {walk.walk, {nil, 134, 73}})
	table.insert(_q, {walk.walk, {nil, 134, 72}})
	table.insert(_q, {walk.walk, {116, 16, 11}})
	table.insert(_q, {walk.walk, {117, 18, 7}})
	table.insert(_q, {walk.walk, {117, 18, 5}})
	table.insert(_q, {walk.walk, {117, 21, 5}})
	table.insert(_q, {walk.walk, {117, 21, 8}})
	table.insert(_q, {walk.walk, {117, 22, 8}})
	table.insert(_q, {walk.walk, {117, 22, 10}})
	table.insert(_q, {walk.walk, {117, 20, 10}})
	table.insert(_q, {walk.walk, {117, 20, 21}})
	table.insert(_q, {walk.walk, {117, 11, 21}})
	table.insert(_q, {walk.walk, {117, 11, 12}})
	table.insert(_q, {walk.walk, {117, 10, 12}})
	table.insert(_q, {walk.walk, {117, 10, 11}})
	table.insert(_q, {walk.walk, {118, 13, 23}})
	table.insert(_q, {walk.walk, {118, 13, 22}})
	table.insert(_q, {walk.walk, {118, 21, 22}})
	table.insert(_q, {walk.walk, {118, 21, 17}})
	table.insert(_q, {walk.walk, {118, 19, 17}})
	table.insert(_q, {walk.walk, {118, 19, 20}})
	table.insert(_q, {walk.walk, {118, 16, 20}})
	table.insert(_q, {walk.walk, {118, 16, 10}})
end

local function _sequence_edward()
	-- Open the menu.
	table.insert(_q, {menu.field.open, {}})

	-- Deal with the Change rod.
	local weapon, quantity = game.character.get_equipment(game.character.get_slot(game.CHARACTER.TELLAH), game.EQUIP.R_HAND)

	if quantity == 255 then
		_M.state.multi_change = true
		table.insert(_q, {menu.field.equip.open, {game.CHARACTER.TELLAH}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.CHANGE}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.NONE}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.CHANGE}})
		table.insert(_q, {menu.field.equip.close, {}})
	elseif weapon == game.ITEM.WEAPON.CHANGE then
		table.insert(_q, {menu.field.equip.open, {game.CHARACTER.TELLAH}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.STAFF}})
		table.insert(_q, {menu.field.equip.close, {}})
	end

	-- Change formation.
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.TELLAH, game.CHARACTER.RYDIA, game.FORMATION.TWO_FRONT}})
	table.insert(_q, {menu.field.form.move, {game.CHARACTER.CECIL, 3}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to Damcyan.
	table.insert(_q, {walk.walk, {nil, 123, 67}})
	table.insert(_q, {walk.walk, {nil, 123, 68}})
	table.insert(_q, {walk.walk, {nil, 120, 68}})
	table.insert(_q, {walk.walk, {nil, 120, 64}})
	table.insert(_q, {walk.walk, {nil, 119, 64}})
	table.insert(_q, {walk.walk, {nil, 119, 58}})
	table.insert(_q, {walk.walk, {37, 16, 11}})
	table.insert(_q, {walk.walk, {63, 8, 7}})
	table.insert(_q, {walk.walk, {64, 8, 10}})
	table.insert(_q, {walk.walk, {64, 7, 10}})
	table.insert(_q, {walk.walk, {64, 7, 13}})
	table.insert(_q, {walk.walk, {64, 8, 13}})
	table.insert(_q, {walk.walk, {65, 13, 11}})
end

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _check_sequence()
	if #_q == 0 and walk.is_ready() and not walk.is_mid_tile() and not walk.is_transition() then
		local map_area = memory.read("walk", "map_area")
		local map_id = memory.read("walk", "map_id")
		local map_x = memory.read("walk", "x")
		local map_y = memory.read("walk", "y")

		local title, sequence

		if map_area == 3 and map_id == 43 and map_x == 14 and map_y == 5 then
			title = "Prologue"
			sequence = _sequence_prologue
		elseif map_area == 0 and map_x == 102 and map_y == 158 then
			title = "D.Mist"
			sequence = _sequence_d_mist
		elseif map_area == 0 and map_x == 84 and map_y == 120 then
			title = "Girl"
			sequence = _sequence_girl
		elseif map_area == 0 and map_x == 103 and map_y == 119 then
			title = "Officer"
			sequence = _sequence_officer
		elseif map_area == 3 and map_id == 16 and map_x == 14 and map_y == 12 then
			title = "Tellah"
			sequence = _sequence_tellah
		elseif map_area == 3 and map_id == 111 and map_x == 7 and map_y == 13 then
			title = "Octomamm"
			sequence = _sequence_octomamm
		elseif map_area == 0 and map_x == 125 and map_y == 67 then
			title = "Edward"
			sequence = _sequence_edward
		end

		if sequence then
			log.log(string.format("Beginning Sequence: %s", title))
			sequence()
		end
	end
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	while true do
		_check_sequence()

		local command = _q[1]

		if command then
			local result = command[1](unpack(command[2]))

			if result then
				table.remove(_q, 1)
			else
				return true
			end
		else
			return true
		end
	end
end

function _M.reset()
	_q = {}

	_state = {
		multi_change = false
	}
end

return _M
