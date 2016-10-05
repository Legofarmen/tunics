# About Tunics!

 * Tunics is a roguelike-like Zelda game for the [Solarus](http://solarus-games.org) game engine.

 * Tunics requires Solarus 1.4.x.

 * Tunics consists in part of materials under various free and open-source and public licenses, and in part of unlicensed materials under fair use. See license.txt for details.


# Play Tunics!

## Windows
 
 1. Install the latest Solarus 1.4.x engine from http://www.solarus-games.org/engine/download/.

 2. Download the Source code (zip) for Tunics.

 3. Extract the `data` folder from the Tunics zip and put it in the directory where you installed Solarus.
 
 4. Run solarus.exe


## Ubuntu

 1. Install the latest Solarus 1.4.x engine from http://www.solarus-games.org/engine/download/.

 2. Download the Source code (tar.gz) for Tunics.

 3. Extract the contents of the tar.gz into your home directory.

 4. Run `solarus $HOME/tunics-master`


## OS X

 1. Install the latest Solarus 1.4.x engine from http://www.solarus-games.org/engine/download/.

 2. Download the Source code (tar.gz) for Tunics.

 3. Copy the ”data” directory from the Tunics tar.gz.

 4. In the Solarus package, open the solars_bundle directory to find Solarus.app

 5. Right click on Solarus.app and click ”show contents of package”.

 6. Find the directory ”Resources” in ”Contents”. Paste ”data” into the ”Resources" directory.

 7. Run ”solarus” in the same directory to start the game.

 8. For reasons at the moment unknown, you can not start tunics by simply running Solarus.app, instead you always need to run ”solarus” in ”Resources”. You can, however create an alias(shortcut) directly to ”solarus”.


# Install Tunics!

## Ubuntu

 1. Install build dependencies

        $ sudo apt-get install cmake

 2. Generate the "data.solarus" archive containing all data files of the quest:

        $ cmake .
        $ make

 3. Install the "tunics" launch script and the "data.solarus" archive:

        $ sudo make install

 4. Play Tunics!

        $ tunics
