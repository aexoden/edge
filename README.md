# Edge

Edge is a script for the BizHawk emulator to speed run Final Fantasy IV. It
currently can run the following routes:

* Any% No64 (Edge+Excalbur)
* Any% No64 (Rosa) (partial support)
* Paladin%

## Prerequisites

* BizHawk (currently tested with v1.11.8.2)
* Final Fantasy IV US 1.0 (originally released as Final Fantasy II)
* luasocket (optional: for LiveSplit integration)

## Configuration

After extracting Edge to a directory, preferably within BizHawk's lua directory,
copy the config.lua.default file to config.lua and open it. There are a few
configuration variables:

### ROUTE

By default, this is set to nil, which will cause the script to choose a random
route for its runs. You can also set this to any valid route to do only runs of
that particular route. Currently supported routes are no64-excalbur, no64-rosa,
and paladin. The route name should be surrounded by double quotation marks.

### ENCOUNTER_SEED

By default, this is set to nil, which will cause the script to choose an
encounter seed randomly. If you instead specify this value, it will only do runs
on that particular encounter seed.

### SEED

By default, this is set to nil, which will cause the script to do random runs.
If you set this to an integer, it will instead do that specific run. Runs are
generally only repeatable with the same version of Edge.

### AUTOMATIC

This controls whether the bot executes a single run or continuously does
automatic runs. By default, it is set to false, which will result in a single
run. If SEED is nil, the bot will continuously do runs for random seeds. If SEED
is set to a particular seed, the bot will do runs incrementally starting from
the given seed. (For example, if SEED is set to 5, the bot will do runs with
seeds 5, 6, 7, etc.)

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

### EXTENDED_ENDING

This option only has meaning when AUTOMATIC is enabled. When enabled, the bot
will allow the ending to play out before rebooting to the next seed. This is
useful if streaming the runs. If the bot dies, it will wait five minutes before
rebooting.

### RESET_FOR_TIME

This option will tell the bot to automatically reset if it falls behind its PB
for the current route by too much. It is disabled by default.

### OVERLAY

This option displays an informational overlay to provide some basic information
about the run. It is disabled by default.

## LiveSplit Integration Requirements (optional and difficult)

Integration with LiveSplit requires functional luasocket support. As of BizHawk
v1.11.8.2, this appears to be an arduous process. Roughly speaking, you need to
(within the BizHawk source tree) build a version of lua51.dll using the
"Release-LUAPERKS" target and replace the lua51.dll in the dll directory. You
must additionally obtain a copy of socket.lua and place this in the root BizHawk
directory. (Other directories may also work.)

On the LiveSplit end, you must add the LiveSplit server to your layout.

Again, this is entirely optional and is only useful if you want to record or
stream runs with LiveSplit.

## Usage

1. Ensure the SRAM file is cleared. (The easiest way to do this is to load the
   Final Fantasy II ROM image, right click on the display, and choose "Close and
   Clear SRAM".)
2. Open the Final Fantasy II ROM image.
3. Ensure the emulator is not paused.
4. Open the BizHawk Lua Console, and load main.lua.
5. From BizHawk's "Emulation" menu, choose "Reboot Core". The script should
   begin a run from the beginning.
