# About
This is the official IDE and interpreter for the esolang [Kawa](https://esolangs.org/wiki/Kawa).

## What is Kawa?
Kawa is an esoteric programming language inspired by Japanese radicals, APL and Uiua. The langage itself isn't typable by any means, so the interpreter serves as a way to actually build and run said programs.

Read more at https://esolangs.org/wiki/Kawa.

## How do I run this?
You'll need to have [LÖVE](https://love2d.org/) downloaded. Then, either download the [/kawa] folder or the .love from the releases, and drag into LÖVE.

## How do I *use* it?
### When editing
- Type with your keyboard to begin placing a command, then press `Enter` to confirm. You can also simply press `Enter` on a blank spot to create a new command slot.
- Press `Escape` to exit a selection.
- Use the left and right arrow keys to move between commands. Hold `Ctrl` to jump to either end.
- Use the up and down arrow keys to move between diacritics.
- `Ctrl`+`I` inserts a new command or diacritic in front of where you currently are.
- Press `Backspace` to blank the command/diacritic you are on, or entirely delete it if it is blank (signified with a pulsing plus). `Ctrl`+`Backspace` delets it immediately.
- Press `Ctrl`+`R` to run the program.
- Press `Ctrl`+`S` to save the program as an image file and present it.

### When running
- Use `Escape` to halt execution and exit.
- Use `Ctrl`+`X` to halt execution.
- A blinking cursor indicates the program is awaiting input, type something in and press enter to confirm.
  - Note: Your input will not be read if it doesn't follow the `Input` command's restrictions.
