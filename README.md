# Common2Draconic

## Overview:
A CLI tool to convert regular text to draconic script based on the D&amp;D language.

Converts plain text files to an image which contains the translated text using the given symbols.

## Example:
Here is a simple example output for words "Hello, World!"
</br>
![Example of draconic script image output for the words, "Hello, World!"](/example.png)

## How to use:
The program can be run in either its default configuration, or using some flags.
To run the program in its default configuration place the text you want to translate in a file called "input.txt".
Then:
1. Open the folder containing "input.txt" in your terminal.
2. run the command `/path_to.../Common2Draconic`

You should then see an image names "output.png" in the same folder.

If you want to use specify specific files to use that can be done too:
1. Open your terminal and navigate to the folder containing the program
2. run the command `/path_to.../Common2Draconic -i "input.txt" -o "output.png"`, the -i and -o flags tell the program where the input text is and what to call the output image.
**Note**: Only .png files are currently supported.

You will either have to specify the path to the Common2Draconic executable, or add it to your PATH.

If you want to remove the image background run the command with the -no_background flag. E.g. `Common2Draconic -i "input.txt" -o "output.png" -no_background`
To change to font size the -fs flag can be used with a value of 1 to 10. E.g. `Common2Draconic -fs 5`. The default font size is the maximum.

## Using your own symbols:
I have only used the program thusfar to translate into draconic script but you can easily run it with any language you like. All you need are individual .png images for each symbol which you wish to translate. All symbol images should be names "symbol.png", for example A is represented by "A.png".

By default the program will use the symbols located in the "Symbols" folder. If you move this folder, or the application, or wish to use alternative symbols you will need to use the -s flag.

The -s flag tells the program where the symbols you want to use are, so simply run the program as follows `Common2Draconic -i "input.txt" -o "output.png" -s "path/to/symbols"`

Currently the all of the capital letters, A to Z are available along with the numbers 1 to 9 and !. Other characters may be added in the future, or you could add your own!

**Note**: The flags can be used in any order.
