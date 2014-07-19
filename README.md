### Leankit Filter
[![Build Status](https://travis-ci.org/ZsoltFabok/leankit_filter.png)](https://travis-ci.org/ZsoltFabok/leankit_filter)
[![Dependency Status](https://gemnasium.com/ZsoltFabok/leankit_filter.png)](https://gemnasium.com/ZsoltFabok/leankit_filter)
[![Code Climate](https://codeclimate.com/github/ZsoltFabok/leankit_filter.png)](https://codeclimate.com/github/ZsoltFabok/leankit_filter)
[![Coverage Status](https://coveralls.io/repos/ZsoltFabok/leankit_filter/badge.png?branch=master)](https://coveralls.io/r/ZsoltFabok/leankit_filter?branch=master)

Filters out information from downloaded Leankit card histories.

#### Install
    gem install leankit_filter

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

     leankit_filter <boards.json location> <destination>

For ruby code:

    require 'leankit_filter'

    locations = []
    process_board = LeankitConvert::ProcessBoard.create
    location = process_board.process("./boards.json", "./leankit_dump")

The `process_board.process` returns the path where the processed/converted data is located.

### Copyright

Copyright (c) 2014 Zsolt Fabok and Contributors. See [LICENSE](LICENSE.md) for details.
