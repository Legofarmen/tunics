# About Tunics!

 * Tunics is a roguelike-like Zelda game for the [Solarus](http://solarus-games.org) game engine.

 * Tunics requires Solarus 1.3.x.

 * Tunics consists in part of materials under various free and open-source and public licenses, and in part of unlicensed materials under fair use. See license.txt for details.


# Play Tunics!

## Windows
 
 1. Clone the tunics repository.

 2. Download the latest Solarus 1.3.x package from http://www.solarus-games.org/downloads/solarus/win32/ 
 
 3. Extract the content of the solarus folder in the Solarus package to the root of the cloned repository.
 
 4. Run solarus.exe

## Ubuntu

 1. Clone the tunics repository.
 
 2. Add repositories (to satisfy libluajit and libstdc++6 >= 4.9)

        sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
        sudo add-apt-repository ppa:ubuntu-toolchain-r/test
        sudo apt-get update

 3. Download and install the latest Solarus 1.3.x package from here:
    * [amd64](http://www.solarus-games.org/downloads/solarus/debian-amd64) or
    * [i386](http://www.solarus-games.org/downloads/solarus/debian-i386)

 4. Run the following commands:

        $ solarus $PATH_TO_REPOSITORY

    or

        $ cd $PATH_TO_REPOSITORY
        $ solarus


## OS X

 1. Clone the tunics repository.

 2. Download the latest Solarus 1.3.x package from http://www.solarus-games.org/downloads/solarus/macosx/

 3. Copy the ”data” directory from the tunics repository.

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
