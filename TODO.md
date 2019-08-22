# Edge TODO

This list of features and bug fixes isn't necessarily exhaustive, but it does
provide a good list of improvements that can be made.

## Critical Issues

* If Cecil isn't properly muted in the Calbrena fight, the Golbez fight can fail
  to fully set up the nocw inventory in the event that Kain+Rydia is enough to
  defeat Golbez. Probably no solution other than adding a backup inventory swap
  after the battle.

* Find a way to get the git version info into the script.

* Step routes need to be updated to the latest version as they become available.

* Fix the potential for a failed CatClaw duplication.

* The no64-rosa route occasionally runs out of Cure2 options during the final descent.

* Find a way to reliably detect NoCW bacon.

## Major Features

* Find a way to keep track of battle goals and properly queueing characters to
  take care of them. The major motivation is to be able to specify that an
  enemy needs to be attacked or that a character needs to be revived, and ensure
  that only one character attempts this action at a time. Such an infrastructure
  would benefit (for example) the grind fight significantly.

* Provide a way to detect and react to events that occur in the battle (such as
  enemy attacks). This should be more robust than trying to simply wait for an
  event on a particular character, as weird level combinations can result in
  battle timing being significantly different. Some battles could benefit from
  knowing what recent actions have been and who the target was.

* Revamp the inventory management system. (This could either rely more heavily
  on scripted times to manipulate the inventory, or do a better job of detecting
  when it's safe to do inventory management.) In either case, we could also
  drastically improve the actual decisions on how to manage the inventory. Each
  run should be largely the same, so there is little need for a dynamic
  infrastructure. Additionally, allow inventory management to take place during
  times when a character is waiting for some event to complete (such as Rydia's
  first turn in the Dr. Lugae/Balnab battle). Need to identify why the bot's
  inventory usually ends up more cluttered than a human's.

* Consider making the bot less tolerant of serious time penalties. Currently,
  the bot simply tries to finish as best it can, continuing even after events
  that many human runners would choose to give up after. This would probably be
  best implemented by creating two subroutes for every route: a less tolerant
  route which simply tries to get a good time, and a marathon/race-safe route
  which tries to complete the game quickly but prioritizes actually finishing.
  That said, there's probably no need for the bot to end the run after an 11
  minute grind fight, even if that eliminates any PB possibility. The data
  gathered is still valuable. However, the non-safe version of the route could
  definitely take more risks and not worry so much about dying. The current
  version of the bot is very much a compromise on this front.

* Consider dynamically preventing softlocks by adding code to automatically
  handle situations where a spell caster hasn't enough MP for a requested spell
  or when a requested item is unavailable. This has the disadvantage of masking
  bugs in actual battle code.

* Use data on encounter formations to make decisions. (Examples include healing
  before Arachne or Red Worm battles, delaying the grind fight menu until
  immediately prior to the grind fight, and so on.)

* Improve NPC-safe walking to better avoid NPCs, without simply stopping. In
  areas where the step route is not affected, the bot should be rerouting
  around the NPCs.

* Improve the routing of character levels. There is ongoing research on the
  ideal combination of levels and it may vary by route.

* Simulate human reactions better during battle with regard to decision-making.
  For instance, the bot currently makes its decisions approximately 12 frames
  earlier than a human would. This may require a more dynamic way to code the
  battle, making decisions more often than only once a turn. Second, the bot has
  an advantage in that it can detect a particular character is dead before the
  animation that kills them takes place. This allows it to queue Life potions
  earlier than a human possibly could.

* Improve the party restoration code to allow target HP or MP values. This would
  allow us to reduce the unneeded restoring of MP to maximum in cases where we
  only need to ensure that the character can cast a particular spell (such as
  Edge potentially needing to cast Flood during the grind fight).

* Change formation changes so that we can simply specify the target formation.
  This makes changes easier if two routes have different formations, for
  example, but need to come together again.

* For nocw, figure out a system for pausing during battle to eliminate or at
  least mitigate the need for the wait at the end.

* If the FireClaw dupe fails for whatever reason during the Gargoyle fight, set
  up a backup later in the run (requires an extra shop visit).

* The NoCW route glitch navigation should probably be rewritten to use a
  function whose job is to advance to the next floor, which allows for easier
  cleanup of state. Eventually the program could be programmed to know exactly
  what to do on each floor, though that doesn't really match how a human would
  approach it.

## Minor Issues

* Check healing strategy upon immediately entering Zot. Death was observed with
  only Tellah and Yang alive with a total of approximately ~500 HP.

* Move the IceClaw dupe away from the Magus Sisters battle to avoid needing to
  revive Yang unconditionally.

* On the off chance the GP is wrong on the nocw route, implement a system to
  fix it.

* Ensure that Yang always equips his IceClaw from the stack of 58 in the nocw
  route.

* Improve the yellow chocobo handling on the nocw route to fix the bad yellow
  chocobo. Not really useful for PB attempts, but for potential marathon runs.

## Battle-Specific Issues

### Fabul Battles

* Prevent attacking the General if possible.

### Milon

* Don't double use Cure2 when healing the twins.

* Restore the Twins' MP if they don't have enough to Twin.

* Rewrite the carrot strategy to use modern strategies and backups.

### Milon Z

* Ensure that we switch to backup strats as quickly as possible.

### Magus Sisters

* Avoid healing after the second delta attack, unless necessary.

### Calbrena

* Not sure how feasible it is, but Yang and/or Rosa being dead at the end of
  this fight seems to be a bad thing, so attempting to revive them may be
  very desirable.

### Dark Elf

### Golbez

### Dr. Lugae

* During the fight with both Dr. Lugae and Balnab, the bot should probably do a
  better job of distributing attacks dynamically depending on remaining HP.
  Otherwise, an important damage dealer such as Kain dying can have serious
  consequences with regard to defeating the pair simultaneously, which can make
  starting the second battle more difficult.

* Yang should be at least level 15. There are potentially dire consequences if
  he is not.

### Dark Imps

### Grind Fight

* This fight needs to be almost reworked entirely. There is highly specific
  timing that needs to be investigated, and the exact nature of this timing may
  depend on the enemy agilities and the party levels. Ideally, the bot should
  only use information available to a human player. (That is, reading the enemy
  agilities should only be done if a human player could determine the same thing
  by observing something in battle.) Recovery needs to be made more reliable.
  Recovery should not needlessly begin early preventing double Lifes. This is a
  very complicated battle to get right.

* If the dragon fighting sequence is going well, don't shift into cure mode
  until the dragon is dead. (Avoid Rydia using a Cure2 on FuSoYa instead of
  fighting the dragon.)

* Additional work on mitigating the Life/Elixir cycle being interrupted. A fix
  is nominally in place, but it may have been partially counteracted.

* At least one case was observed (v0.0.6 on seed 26, 30) where two characters
  attacked in short succession, leading to bad things. (The scenario in seed 30
  is nothing short of ridiculous, and I have no idea what happened there.)

* If FuSoYa gives up on waiting for the dragon to appear, he really shouldn't
  Weak the searcher.

### Zeromus

* Investigate adding code to dynamically recover in the event of a Big Bang that
  kills Edge. A more dynamic approach may well be required eventually when
  adding the Drain route. This would also be useful in the event the first Big
  Bang nearly kills Cecil (and risks his dying by sap before the second Big
  Bang).

* Map out damage in fight to determine the probability that Zeromus creeps in a
  Virus and see if there is a way to mitigate that risk. (Only seen so far in
  Cecil nuke scenario.)
