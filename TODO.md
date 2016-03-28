# Edge TODO

This list of features and bug fixes isn't necessarily exhaustive, but it does
provide a good list of improvements that can be made.

## Critical Fixes

* Fix the grind fight to be more reliable. We need to prevent Rydia jumps and
  otherwise make the battle safer. Current test runs are dying at the grind
  fight upward of 70% of the time.

## Major Features

* Add some sort of goal/action based system to battles. The primary motivation
  is to ensure only one character attempts to Life a fallen party member, as an
  example. This additionally requires tracking if a character currently queued
  to perform an action is no longer able to perform that action for some reason
  (from death or some other status effect).

* Clean up the individual battles starting from the beginning. Almost every
  battle can stand some level of improvement.

* Ensure inventory actions (such as during Q.Eblan/K.Eblan battle) are executed
  during animations as much as possible.

* Integrate waiting with inventory management so that management can take place
  during waits, while still checking the wait conditions each frame.

* Enhance inventory management to behave closer to how a human manages
  inventory. The goal is to have items exactly where we need them when we need
  them there.

* Allow for specific item placement. This is necessary for Yes64 and is useful
  for making sure certain items end up in good locations.

* Build an external log analyzer to collect statistics from multiple runs.

* Add additional strategies and branches to the run. (Drain spear and Yes64 are
  two examples.)

* Automatically end the run or reset if possible in situations where the run is
  more or less over. Example conditions include: getting an encounter on the
  first step after resetting at Mist, accidentally killing the Searcher in the
  grind fight, dying in the Land of Monsters.

* If items are missing or otherwise not as expected, come up with a backup plan
  to avoid softlocking.

* Use data on encounter formations (heal before Arachne, delay grind fight menu
  until just before grind fight, only heal before the Moon if encountering Red
  Worms, etc.)

* Improve NPC-safe walking to better avoid NPCs, without damaging the step
  route.

## Minor Fixes

* Make sure anything that uses walk.interact() is robust. (At least one run
  failed when the bot failed to collect the Darkness sword for some unknown
  reason.)

* Fix step routing at the tile before the Elements battle. (The bot decides
  whether to take two more extra steps before the grind fight begins if it
  occurs on the last tile.)

* Improve the code for Level 19 Kain. It should be possible to script the Baigan
  fight to kill Yang and the twins off almost every time. Ideally, a completely
  dynamic system would be designed depending on how many people were alive at
  various junctures, but this would be a simpler adjustment. This goes along
  with ensuring that Cecil and Rosa reach level 20 when they are supposed to.

* Characters are, in general, making their battle decisions something like 12
  frames earlier than a human would. (Assuming a human knew exactly what they
  wanted to do and entered it the instant the menu appeared.) The only real
  input that can be made before that 12 frames is up is a run buffer. Creating
  a more advanced battle status that can a) delay most decisions until
  appropriate while b) allowing for run buffers and interruptible wait commands
  would be desirable.

* Find a way to reduce or eliminate the 15 frame safety delays in the menu.

## Battle-Specific Fixes

### Fabul battles

* Prevent attacking the General if possible.

### Milon

* Don't double use Cure2 when healing the twins.
