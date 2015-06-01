# About

This package contains the data files of the game Tunics!

This quest is a free, open-source game that works with Solarus, an open-source
Zelda-like 2D game engine. To play this game, you need Solarus.

The current version of Tunics! only runs under Solarus 1.3.x.

See http://www.solarus-games.org for more information and 
documentation about Solarus.


# Play Tunics!

## Windows
 
 1. Clone the tunics repository.
 
 2. Download the latest Solarus 1.3.x package from http://www.solarus-games.org/downloads/solarus/win32/ 
 
 3. Extract the Solarus package to the root of the cloned repository.
 
 4. Run solarus.exe

## Debian Linux

 1. Download and install the latest Solarus 1.3.x package from
    http://www.solarus-games.org/downloads/solarus/debian-amd64 or
    http://www.solarus-games.org/downloads/solarus/debian-i386.

 2. Clone the tunics repository.

 3. Run the following commands:

        $ solarus $PATH_TO_REPOSITORY

    or

        $ cd $PATH_TO_REPOSITORY
        $ solarus


## OS X

todo

# Packaging


## Default settings

If you want to install tunics, cmake and zip are recommended.
Just type

    $ cmake .
    $ make

This generates the "data.solarus" archive that contains all data files
of the quest. You can then install it with

    # make install

This installs the following files (assuming that the install directory
is /usr/local):
- the quest data archive ("data.solarus") in /usr/local/share/solarus/zsdx/
- a script called "tunics" in /usr/local/bin/

The tunics script launches solarus with the appropriate command-line argument
to specify the quest path.
This means that you can launch the tunics quest with the command:

    $ tunics

which is equivalent to:

    $ solarus /usr/local/share/solarus/tunics


## Change the install directory 

You may want to install tunics in another directory
(e.g. so that no root access is necessary). You can specify this directory
as a parameter of cmake:

    $ cmake -D CMAKE_INSTALL_PREFIX=/home/your_directory .
    $ make
    $ make install

This installs the files described above, with the
/usr/local prefix replaced by the one you specified.
The script generated runs solarus with the appropriate quest path.


## Play directly

You need to specify to the solarus binary the path of the quest data files to
use.
solarus accepts two forms of quest paths:
- a directory having a subdirectory named "data" with all data inside,
- a directory having a zip archive "data.solarus" with all data inside.

Thus, to run tunics, if the current directory is the one that
contains the "data" subdirectory (and this readme), you can type

    $ solarus .

or without arguments:

    $ solarus

if solarus was compiled with the default quest set to ".".
