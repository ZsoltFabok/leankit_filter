module LeankitFilter
  class Cli
    def self.run(argv)
    	boards_json = argv[0]
    	board_dump_location = argv[1]

    	ProcessBoard.create.process(boards_json, board_dump_location)
    end
  end
end
