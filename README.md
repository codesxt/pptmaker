# PPT Maker

![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

PPT Maker is a command line tool that uses the Gemini API to generate basic Power Point Presentations.

To use it, you can compile it using the Dart SDK or you can download the binary file for your specific file system in the Releases section.

A sample command-line application providing basic argument parsing with an entrypoint in `bin/`.

## Instructions

### To compile

1. Install the Dart SDK ([instructions here](https://dart.dev/get-dart)).
2. Run from the root of the project the following command
   `dart compile exe bin/pptmaker.dart -o output_filename`

### To run compiled file

1. Move the file to your bin folder or add it to path

### To run without compilation

1. Install Dart (or Flutter with dart)
2. Run `dart bin/pptmaker.dart --config` to set you API Key
2. Run `dart bin/pptmaker.dart` to generate Power Points

## Commands

### Config

`pptmaker --config`: allows you to set your Gemini API Key
`pptmaker --clear-config`: removes configuration information
`pptmaker`: runs the Power Point generator


## How to use

After running the pptmaker command you have to input the following information:

* Topic: The topic of the presentation
* File name: The name of the file. If it does not end with '.pptx' it will be added automatically.
* Author: The author's name.

After that you have to wait for the process to end and your file will be generated in the folder where the command is executed.

## Disclaimer

This program might fail to build the presentation if some weird character breaks the parsing process. Sorry for that.