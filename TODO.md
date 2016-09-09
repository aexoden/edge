# Edge TODO

This list of features and bug fixes isn't necessarily exhaustive, but it does
provide a good list of improvements that can be made.
121
## Critical Fixes

This section includes any critical must-fixes before the next release. This will
generally be limited to either crashes or softlocks (where the bot is for
whatever reason stuck and unable to continue, but hasn't crashed).

* Clear the log console between runs. (Runs become slower as the console fills.)

* Fix the problem of attempting to dump inventory using the trash can in
  situations when the trash can was already used.

* Investigate unknown menuing softlock on seed 181, which occurs while curing
  the party after the Lugae battle.

## Major Features

This section is for major improvements that represent a major undertaking to
successfully implement.

* Implement the capability to execute different routes. This includes both Yes64
  and the multitude of available No64 routes. Ideally, the bot should be capable
  of executing any one of these (and thus allowing us to ultimately compare them
  with large sample sizes). There are two options for specifying the route.
  First, the route could be a parameter, and then the randomization seed applies
  within that route. This has the advantage of being able to specify a given
  route directly. The second option is to have the bot determine the route
  randomly as part of the given randomization seed. This means a randomization
  seed is once again globally deterministic, but it does make it harder to
  request a random run of a given route.

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

* Improve menuing code to eliminate the substantial safety delays in place to
  prevent softlocks.

* Improve the party restoration code to allow target HP or MP values. This would
  allow us to reduce the unneeded restoring of MP to maximum in cases where we
  only need to ensure that the character can cast a particular spell (such as
  Edge potentially needing to cast Flood during the grind fight).

* Build an external log analyzer to collect statistics from multiple runs and
  display them in some kind of visually appealing fashion.

## Minor Fixes

This section is for minor bugs or improvements that should probably be fixed
before the next release.

* Ensure that step routing is correct at the tile before the Elements battle if
  the grind fight begins on that last tile.

* Eliminate the multi_change variable and instead determine the current state
  dynamically by counting the number of available Change rods.

* Check healing strategy upon immediately entering Zot. Death was observed with
  only Tellah and Yang alive with a total of approximately ~500 HP.

* Ensure that a random seed is always random, even in automatic mode.

* Provide a stream-friendly mode that plays through the ending before any
  reboot.

## Battle Fixes

This section is for any battle-specific fixes that need to be made. These may be
either simple or complicated in their nature.

### Fabul Battles

* Prevent attacking the General if possible.

* Do not do inventory management as the first action.

### Milon

* Don't double use Cure2 when healing the twins.

* Investigate abandoning the Carrot strat in certain cases.

### Milon Z

* Ensure everyone has enough MP for the spells they may have to cast before the
  battle.

* Work on the TrashCan timing or abandon its attempt in cases where it's
  unlikely to work successfully.

### Dark Elf

* Tellah should prioritize casting Weak, though it may be a question of balance.

### Magus Sisters

* Cecil needs to be able to revive Tellah, especially.

* Cecil should be a little more willing to use Cure2s on Tellah, or even
  himself.

* Make sure Tellah is not muted before this fight.

### Valvalis

* Cecil waiting indefinitely for Weak is probably a bad idea, in case the turn
  order ends up slightly odd.

* Verify that everyone can participate in recovery as necessary.

### Calbrena

* Watch Cecil's health, especially toward the end. If he gets wiped immediately
  prior to his last turn, a battle with the big doll will result. Regardless,
  Cecil should really survive this battle.

### Golbez

* In the worst case, ensure Rydia has a more viable strat than simply attacking.

### Dr. Lugae

* During the fight with both Dr. Lugae and Balnab, the bot should probably do a
  better job of distributing attacks dynamically depending on remaining HP.
  Otherwise, an important damage dealer such as Kain dying can have serious
  consequences with regard to defeating the pair simultaneously, which can make
  starting the second battle more difficult.

* Yang should be at least level 15. There are potentially dire consequences if
  he is not.

* Recovery needs to be made more robust. Giving characters other than Rosa and
  Cecil the ability to aid in recovery is vital for some of the worst-case
  scenarios.

### Rubicant

* Edge and perhaps other characters need some ability to participate in
  recovery. It does the team little good if he parries away his life when he's
  the only one alive.

### Grind Fight

* This fight needs to be almost reworked entirely. There is highly specific
  timing that needs to be investigated, and the exact nature of this timing may
  depend on the enemy agilities and the party levels. Ideally, the bot should
  only use information available to a human player. (That is, reading the enemy
  agilities should only be done if a human player could determine the same thing
  by observing something in battle.) Recovery needs to be made more reliable.
  Recovery should not needlessly begin early preventing double Lifes. This is a
  very complicated battle to get right.

* In weird level setups, Rydia won't necessarily go directly after FuSoYa. Make
  sure that in that event, people don't pointlessly wait for Quake, and just
  get the battle started and make the most of it.

* If the dragon fighting sequence is going well, don't shift into cure mode
  until the dragon is dead. (Avoid Rydia using a Cure2 on FuSoYa instead of
  fighting the dragon.)

* Try to mitigate the situation where FuSoYa is dead, and the Life/Elixir
  pattern is consistently interrupted by Fire in between. (This prevents FuSoYa
  from ever getting up.)

### Zeromus

* Investigate adding code to dynamically recover in the event of a Big Bang that
  kills Edge. A more dynamic approach may well be required eventually when
  adding the Drain route. This would also be useful in the event the first Big
  Bang nearly kills Cecil (and risks his dying by sap before the second Big
  Bang).

* Map out damage in fight to determine the probability that Zeromus creeps in a
  Virus and see if there is a way to mitigate that risk. (Only seen so far in
  Cecil nuke scenario.)
