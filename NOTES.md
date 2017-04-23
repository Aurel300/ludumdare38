#### LD38 - A small world ####

# Planet of Babel #

A planet is shared by aliens / shipwrecks of all worlds and cultures (realtime multiplayer). They cannot understand each other, but to succeed, they must cooperate.

The gameplay is turn-based and consists of trying to control and maintain territories, gathering resources, defending and attacking other players. There is a karma system, which punishes people for attacking newcomers and people with good karma, while rewarding them for helping and sharing and attacking people with bad karma. Retribution is delivered by "gods".

The ultimate goal of the game is to build a tower. This consists of putting in immense amounts of resources. These can be stolen by other players, who can try to build the tower on their own. Leaderboards motivator?

The gameplay has a slower pace, but it keeps running in the background. Encourage players to connect more than once?

## Gameplay details ##

 - global timer: 1 minute per turn
 - new players:
   - meteorite crashes -> replaces crashed land with 4 tiles:
     - generator in the middle
     - three empty tiles around, activated shields
     - 5 SL
 - resources
   - SL  - starlight - gathered, kept over turns (like minerals)
   - NRG - energy - generated, doesn't keep over turns (like supply / AP)
 - random comet strikes contain resources
   - frequency is dependent on number of players playing
   -> crashing into somebody's land gives them resources
   -> crashing into nobody's land creates a starlight cache
 - land
   - at least one tile required to survive
   - more land = more SL caught
   - more land = more NRG upkeep needed
 - actions:
   - taking nobody's land - 1 SL (1+1 NRG onetime + upkeep)
   - building on your land (must be empty) - cost of the unit
   - attacking someone's land - your unit must be on an adjacent tile

## Unit list ##

 - SL = starlight cost (one time)
 - NRG = energy cost (one time + upkeep)
 - MOV = movement speed in tiles (attack is not a move)
 - DEF = defense (absorbs DEF damage before going to HP from any attack)
 - HP = hit points (don't regenerate)

| NAME          | SL | NRG | MOV | ATK | DEF | HP  | NOTES |
| ------------- | --:| ---:| ---:| ---:| ---:| ---:| ----- |
| tower block   | 2  | 0+4 | 0   | 0   | 0   | 1   |       |
| shield        | 3  | 2+2 | 0   | 0   | 0   | 5   | lasts 3 turns; another unit can be underneath; absorbs all the damage of an attack, even if it dies (the unit underneath is not damaged) |
| generator     | 10 | 0+0 | 1   | 0   | 2   | 10  | generates 15 NRG (*) |
| SL catcher    | 15 | 1+1 | 1   | 1   | 1   | 2   | SL caught is worth 3x (*) |
| bow and arrow | 3  | 0+1 | 4   | 2   | 0   | 4   | ranged attack (2 range) |
| trebuchet     | 5  | 0+2 | 2   | 2   | 1   | 1   | 3x damage against shields |
| dynamite      | 7  | 5+5 | 3   | 10  | 0   | 1   | can move on enemy land; cannot attack; if killed, explodes, dealing its damage to all surrounding units (friendly or not) |

(*) applies when the unit has not moved, attacked or been attacked this turn

## Features / TODO ##

 - [ ] gameplay system
   - [ ] moving
   - [ ] building
   - [ ] attacking
 - [ ] realtime multiplayer
   - [ ] events
   - [ ] karma
 - [.] visuals
   - [x] canvas
   - [x] tile grid
   - [ ] GUI
   - [.] sprites + deformation
   - [.] interaction
     - [x] selection
     - [.] rotation (rotate to tile automatically)
   - [x] terrain
     - [ ] layers
     - [ ] water
   - [ ] space
 - [ ] loading optimisations
   - javascript preloader / screen
   - sprite generation with progress bar
