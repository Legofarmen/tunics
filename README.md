# About Tunics!

 * Tunics is a roguelike-like Zelda game for the [Solarus](http://solarus-games.org) game engine.

 * Tunics requires Solarus 1.5.x.

 * Tunics consists in part of materials under various free and open-source and public licenses, and in part of unlicensed materials under fair use. See license.txt for details.


# Play Tunics!

## Windows
 
 1. Install the latest Solarus 1.5.x engine from http://www.solarus-games.org/engine/download/.

 2. Download the Source code (zip) for Tunics.

 3. Extract the `data` folder from the Tunics zip and put it in the directory where you installed Solarus.
 
 4. Run solarus-run.exe


## Ubuntu

 1. Install the latest Solarus 1.5.x engine from http://www.solarus-games.org/engine/download/.

 2. Download the Source code (zip) for Tunics.

 3. Extract the contents of the zip into your home directory.

 4. Run `solarus-run $HOME/tunics-master`


## OS X

 1. Install the latest Solarus 1.5.x engine from http://www.solarus-games.org/engine/download/.

 2. Download and extract the Source code (zip) for Tunics.

 3. Copy the Solarus-run application from the Solarus bundle to the Tunics directory.
 
 4. Run the Solarus-run application.

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
