module LeankitConvert
  class Runner
    def self.run(argv)
      files_and_json = Common::FilesAndJson.new
      content = files_and_json.from_file("boards.json")
      content["boards"].each do |board, mapping|
        DumpToCsv.new(files_and_json, CsvFile.new).convert(argv[0], board, mapping)
      end
    end
  end
end
