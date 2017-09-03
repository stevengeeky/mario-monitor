# Mario Monitor

## Go from

![raw game](https://raw.githubusercontent.com/stevengeeky/mario-monitor/master/images/example_cc_nodraw.png)

## To

![lua version](https://raw.githubusercontent.com/stevengeeky/mario-monitor/master/images/example_cc.png)

## About

The life of a tool assisted speedrunner can be long, difficult, and repetitive. So we made a tool that streamlines your speedrunning experience&mdash;if you can stand the fact that you'll have less re-records at the end of your run.

Largely based upon the mechanistic aspect of ShadowDragon's NewLua. A lightweight version of Amaraticando's SMW-TAS. Get the essentials of Bahamete's SMWUtils, the astoundingly useful prediction mechanics in ShadowDragon's NewLua and Masterjun's BlockLua, all in a single 25kb package.

*Built for lsnes rr1-&Delta;18&epsilon;3*

## Instructions
&rarr; Download or clone the repository into a memorable location.

&rarr; Open lsnes and go to *Tools &rarr; Run Lua Script*, then choose the lua script you downloaded in the previous step.

## Features

* Keep track of all basic mechanistic values you're expecting, such as the position and velocity of the player and all normal sprites, basic timers, etc. every single frame.

* Never worry about spending hours on a walljump or corner clip again, predict where you can corner clip and walljump for every part of the screen, every frame.

* Streamline your corner clipping attempts with a timer that predicts how long you have to keep running in order to achieve corner clipping conditions.

## Requirements

* lsnes rr1-&Delta;18&epsilon;3, a beta- (rr2) compatible version might be made eventually, see issues for an update.
