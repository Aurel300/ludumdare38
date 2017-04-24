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
   - building on your land (must be empty) - cost of the unit
   - attacking someone's unit - your unit must be in range
     - ATK is dealt to the enemy, if it survives, its ATK is dealt back (counterattack)
   - capturing someone's land - 1 SL (0+1 NRG)
     - successful only if the unit is not attacked
   - capturing nobody's land - same as ^ but - 1 SL (1+1 NRG)

## Unit list ##

 - SL = starlight cost (one time)
 - NRG = energy cost (one time + upkeep)
 - MOV = movement speed in tiles (attack is not a move)
 - DEF = defense (absorbs DEF damage before going to HP from any attack)
 - HP = hit points (don't regenerate)

| NAME          | SL | NRG | MOV | ATK | DEF | HP  | NOTES |
| ------------- | --:| ---:| ---:| ---:| ---:| ---:| ----- |
| generator     | 10 | 0+0 | 1   | 0   | 2   | 10  | generates 15 NRG (*) |
| SL catcher    | 15 | 1+1 | 1   | 1   | 1   | 2   | SL caught is worth 3x (*) |
| boot          | 2  | 0+1 | 2   | 3   | 1   | 5   |       |
| bow and arrow | 3  | 0+1 | 2   | 2   | 0   | 4   | ranged attack (2 range) |
| trebuchet     | 5  | 0+2 | 1   | 2   | 1   | 1   | 3x damage against shields; ranged attack (2 range) |
| dynamite      | 7  | 5+5 | 2   | 10  | 0   | 1   | cannot attack or capture; if killed, explodes, dealing its damage to all surrounding units (friendly or not) |
| cloak & dagger| 10 | 0+5 | 3   | 5   | 0   | 1   | starts cloaked (invisible to enemies); ignores DEF and counterattack when attacking cloaked; attacking or capturing decloaks; not moving, attack, or being attacked for one turn on home land cloaks again |
| tower block   | 2  | 0+4 | 0   | 0   | 0   | 1   |       |
| shield        | 3  | 2+2 | 0   | 0   | 0   | 5   | lasts 3 turns; another unit can be underneath; absorbs all the damage of an attack, even if it dies (the unit underneath is not damaged) |

(*) applies when the unit has not moved, attacked or been attacked this turn

## Damage table ##

Column is attacker, line is defender.

|   | G | S | B | B | T | D  | C | T | S | CC |
|---|---|---|---|---|---|----|---|---|---|----|
| G | 0 | 0 | 1 | 0 | 0 | 8  | 3 | 0 | 0 | 5  |
| S | 0 | 0 | 2 | 1 | 1 | 9  | 4 | 0 | 0 | 5  |
| B | 0 | 0 | 1 | 1 | 1 | 9  | 4 | 0 | 0 | 5  |
| B | 0 | 1 | 3 | 2 | 2 | 10 | 5 | 0 | 0 | 5  |
| T | 0 | 0 | 1 | 1 | 1 | 9  | 4 | 0 | 0 | 5  |
| D | 0 | 1 | 3 | 2 | 2 | 10 | 5 | 0 | 0 | 5  |
| C | 0 | 1 | 3 | 2 | 2 | 10 | 5 | 0 | 0 | 5  |
| T | 0 | 1 | 3 | 2 | 2 | 10 | 5 | 0 | 0 | 5  |
| S | 0 | 1 | 3 | 2 | 6 | 10 | 5 | 0 | 0 | 5  |

## Sound fx list ##

 - [x] GUI drawer
 - [ ] GUI click (mechanical pen click?)
 - unit select:
   - [ ] generator ???
   - [x] SL catcher
   - [x] boot
   - [x] bow and arrow
   - [x] trebuchet
   - [x] dynamite
   - [x] cloak and dagger
 - unit attack:
   - [x] SL catcher
   - [ ] boot
   - [x] bow and arrow
   - [ ] trebuchet
   - [x] dynamite
   - [x] cloak and dagger
 - [x] low time
 - [x] unit movement (like in Civ 2)
 - [ ] land captured
 - [x] SL collected (coin sounds?)
 - [x] SL caught from sky
 - [x] new player spawn = meteorite crash
 - [x] invalid action (trying to build without resources)

## Features / TODO ##

 - [ ] gameplay system
   - [x] design
   - [x] moving
   - [x] attacking - range?
   - [ ] building
   - [ ] resources
 - [ ] realtime multiplayer
   - [x] "logins" / sessions
   - [.] gamestate
     - [x] push turns
     - [x] resolve turns
     - [ ] animate turns back
   - [ ] events
   - [ ] karma
 - [.] visuals
   - [x] canvas
   - [x] tile grid
   - [.] GUI
   - [x] sprites + deformation
   - [ ] towers
   - [.] interaction
     - [x] selection
     - [.] rotation (rotate to tile automatically)
     - [ ] zoom
   - [ ] better shading
   - [ ] space
   - [x] terrain
     - [ ] layers
     - [ ] water
 - [ ] loading optimisations
   - javascript preloader / screen
   - sprite generation with progress bar
