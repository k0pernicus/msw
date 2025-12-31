# msw

A recreational Point&Click game, using Odin and Raylib.

## Usage

This program can be used on GNU/Linux and macOS. 
There is **no** attempt to make a Windows version for the moment.

Please install the raylib static library on your system, and include it in the `lib` folder of this project.

## Build

A makefile is available to build the project:

```sh
# Debug version
make debug
# Release version
make release
```

## TODO

[ ] An asset storage
[ ] A level editor
[ ] Save and load the levels (format to determine - binary could be great)
[ ] An "Event processor" clicking or hovering game entities / game objects (replacement of OnClickAction and OnHoverAction events)
[ ] Store the state of each entity in the game (premisce to store / load game)
[ ] Sound and music basic management
[ ] Camera management (rotation / (de-)zoom / ...)
[ ] Option menu, with localization (English / French)
