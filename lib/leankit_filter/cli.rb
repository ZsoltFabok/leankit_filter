module LeankitFilter
  class Cli
    def self.run(argv)
      renderer = nil
      if ["--json", "--csv"].include? argv[0]
        renderer = argv[0].scan(/--([a-z]+)/)[0][0]
        argv.shift
      else
        renderer = "csv"
      end

      boards_json = argv[0]
      board_dump_location = argv[1]

      board_name, work_items = ProcessBoard.create.process(boards_json, board_dump_location)

      if renderer == "csv"
        self.save_to_csv(board_dump_location, board_name, work_items)
      else
        self.save_to_json(board_dump_location, board_name, work_items)
      end
    end

    private
    def self.save_to_csv(board_dump_location, board_name, work_items)
      csv_file = CsvFile.new
      csv_file_location = File.join(File.split(board_dump_location)[0], "#{board_name}.csv")
      csv_file.open(csv_file_location, [:id, :backlog, :committed, :started, :finished])
      work_items.each do |entry|
        csv_file.put(entry)
      end
      csv_file.close
      # FIXME
      csv_file_location
    end

    def self.save_to_json(board_dump_location, board_name, work_items)
    end
  end
end
