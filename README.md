### Leankit Convert
[![Build Status](https://travis-ci.org/ZsoltFabok/leankit_convert.png)](https://travis-ci.org/ZsoltFabok/leankit_convert)
[![Dependency Status](https://gemnasium.com/ZsoltFabok/leankit_convert.png)](https://gemnasium.com/ZsoltFabok/leankit_convert)
[![Code Climate](https://codeclimate.com/github/ZsoltFabok/leankit_convert.png)](https://codeclimate.com/github/ZsoltFabok/leankit_convert)
[![Coverage Status](https://coveralls.io/repos/ZsoltFabok/leankit_convert/badge.png?branch=master)](https://coveralls.io/r/ZsoltFabok/leankit_convert?branch=master)

Converts Leankit json to other formats.

#### Install
    gem install leankit_convert

#### Usage

First you will need a `boards.json` file that tells the application how to find certain columns:

    {
      "boards": {
        "<case sensitive board name>" : { 
          "backlog": ["Backlog"],
          "committed" : ["ToDo"],
          "started": ["^Doing"],
          "finished": ["Done"]
        }
      }
    }

For command line:

     leankit_convert <boards.json location> <destination>

For ruby code:

    require 'leankit_convert'

    locations = []
    process_board = LeankitConvert::ProcessBoard.create
    location = process_board.process("./boards.json", "./leankit_dump")

The `process_board.process` returns the path where the processed/converted data is located.

### Copyright

Copyright (c) 2014 Zsolt Fabok and Contributors. See [LICENSE](LICENSE.md) for details.
