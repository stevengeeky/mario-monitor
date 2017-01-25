# Mario Monitor

## Go from

![raw game](https://raw.githubusercontent.com/stevengeeky/mario-monitor/master/images/example_cc_nodraw.png)

## To

![lua version](https://raw.githubusercontent.com/stevengeeky/mario-monitor/master/images/example_cc.png)

## About

This is a basic lua script inspired by a mixture of Bahamete's original [SMWUtils.lua](https://github.com/gocha/gocha-tas-legacy/blob/master/Scripts/SMWUtils.lua) and masterjun's revision of it with block-info.lua, and then with the nuanced efforts of ShadowDragon to create a 'finalized' [newLua.lua](http://bin.smwcentral.net/u/18906/newLua.lua). The only problem with these scripts is that they are created for the now considerably deprecated, though still very usable, Snes9x.

This was made as a port of specifically the latter script for the stable *lsnes rr1-&Delta;18&epsilon;3* with self-derived calculations (which I may later transcribe in detail).

If you are searching for a script created for *lsnes rr2-&beta;23* or higher, you can currently refer to [smw-tas](https://github.com/rodamaral/smw-tas), a great, highly functional, and very comprehensive script created by Amaraticando, the same person who has now authored [smw-tas.blogspot.com](http://smw-tas.blogspot.com) and the most recent [amaraticando.blogspot.com](http://amaraticando.blogspot.com). His specific project is a mixture of all of the aforementioned scripts, as well as [amaurea's script](http://tasvideos.org/forum/viewtopic.php?p=219824&highlight=#219824) for outputting TAS movie ghosts and re-drawing them during new runs for real-time comparison. He also adds a hint of [Masterjun's SMW Atlas](http://pastebin.com/raw/DgVn8cEA) script for drawing offscreen map16 objects by directly referencing the game's appropriately named atlas for all layer-specific objects.

## Requirements