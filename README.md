# Edge

Edge is a script for the BizHawk emulator to speed run Final Fantasy IV. It
currently follows the Edge+Excalbur route of the Any% No64 run.

## Prerequisites

* BizHawk (currently tested with v1.11.6)
* Final Fantasy IV US 1.0 (originally released as Final Fantasy II)
* luasocket (optional: for LiveSplit integration)

Instructions for installing and using luasocket along with LiveSplit are
currently unavailable. This integration is not required to use the script.
Instructions may appear here eventually, once exact instructions are determined.

## Configuration

After extracting Edge to a directory, preferably within BizHawk's lua directory,
open the main.lua file. There are a few configuration variables:

### SEED

By default, this is set to nil, which will cause the script to do random runs.
If you set this to an integer, it will instead do that specific run. Runs are
generally only repeatable with the same version of Edge.

### LIVESPLIT

Enables or disables LiveSplit integration. By default this is disabled. Enabling
this requires luasocket and a correctly configured LiveSplit. USE OF THIS
INTEGRATION IS CURRENTLY UNSUPPORTED. IT MAY OR MAY NOT WORK DEPENDING ON YOUR
EXACT SETUP.

### SAVESTATE

When enabled, save states will automatically be created at the start of every
battle for which a battle function exists. (This is generally boss battles and
the grind fight.) This option is disabled by default, as it's primarily useful
for debugging.

## Usage

1. Ensure the SRAM file is cleared. (The easiest way to do this is to load the
   Final Fantasy II ROM image, right click on the display, and choose "Close and
   Clear SRAM".)
2. Open the Final Fantasy II ROM image.
3. Ensure the emulator is not paused.
4. Open the BizHawk Lua Console, and load main.lua.
5. From BizHawk's "Emulation" menu, choose "Reboot Core". The script should
   begin a run from the beginning.
