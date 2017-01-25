# Mario Monitor

## Go from

![raw game](https://raw.githubusercontent.com/stevengeeky/mario-monitor/master/images/example_cc_nodraw.png)

## To

![lua version](https://raw.githubusercontent.com/stevengeeky/mario-monitor/master/images/example_cc.png)

## About

> Note: If you are searching for a lua script created for *lsnes rr2-&beta;23* or higher, you can currently refer to [smw-tas](https://github.com/rodamaral/smw-tas), a great, highly functional, and very comprehensive lua script created by Amaraticando, the same person who has now authored [smw-tas.blogspot.com](http://smw-tas.blogspot.com) and the most recent [amaraticando.blogspot.com](http://amaraticando.blogspot.com).

This is a basic lua script inspired by Bahamete's original [SMWUtils.lua](https://github.com/gocha/gocha-tas-legacy/blob/master/Scripts/SMWUtils.lua), Masterjun's block-info.lua, and ShadowDragon's nuanced yet mechanically 'finalized' [newLua.lua](http://bin.smwcentral.net/u/18906/newLua.lua). The only problem with these scripts is that they are created for the now considerably deprecated, though still very usable, Snes9x.

This project was created as a from-scratch remake of specifically the latter script for the stable *lsnes rr1-&Delta;18&epsilon;3* using self-derived calculations (which I may later transcribe in detail).

This is by no means an 'all-purpose' script. It has been intentionally designed around the mechanical aspects of the game only, as to avoid 'over-bloating' the features which this script represents.

Some other noteworthy Lua scripts to mention here are [amaurea's script](http://tasvideos.org/forum/viewtopic.php?p=219824&highlight=#219824) for outputting TAS movie ghosts and re-drawing them during new runs for real-time comparison; and [Masterjun's SMW Atlas](http://pastebin.com/raw/DgVn8cEA) script for drawing offscreen map16 objects by directly referencing the game's storage facility for all layer-specific objects. Both of these are also implemented in Amaraticando's project.

## Instructions
&rarr; Download or clone the repository into a memorable location.

&rarr; Open lsnes and go to *Tools &rarr; Run Lua Script*, then choose the lua script you downloaded in the previous step.

## Features

* Display of basic mechanistic values which are read directly from the in-game RAM: the player's velocity and position, sprites' velocities and positions, timers, etc.

* Prediction of walljumps and corner-clips for every tile on the screen; recalculated every frame.

## Requirements

* lsnes rr1-&Delta;18&epsilon;3, or any version of lsnes which supports global memory references.