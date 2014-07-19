module LeankitFilter
  class ProcessBoard
    def initialize(files_and_json, csv_file)
      @files_and_json = files_and_json
      @csv_file = csv_file
    end

    def process(boards_json, board_dump_location)
      board_name = File.basename(board_dump_location)
      content = @files_and_json.from_file(boards_json)
      mapping = nil
      content["boards"].each do |board, mapping_|
        if board == board_name
          mapping = mapping_
          break
        end
      end

      to_csv(board_dump_location, board_name, mapping)
    end

    def to_csv(board_dump_location, board_name, mapping)
      csv_file_location = File.join(File.split(board_dump_location)[0], "#{board_name}.csv")
      Dir.foreach(board_dump_location) do |file_name|
        if file_name =~ /([0-9]+)_history.json/
          card_id = $1
          # FIXME: hard coded header -> not cool
          @csv_file.open(csv_file_location, [:id, :backlog, :committed, :started, :finished])
          history_file_location = File.join(board_dump_location, "#{card_id}_history.json")
          if File.exists?(history_file_location)
            entry = {id: card_id}
            history = @files_and_json.from_file(history_file_location)[0]
            backlog_index = find_backlog(history, mapping)
            if backlog_index
              entry[:backlog] = get_date(history[backlog_index])

              started_index = find_started(history, mapping)
              if started_index
                entry[:started] = get_date(history[started_index])
                committed_index = find_committed_before_started(history, mapping, started_index)
                if committed_index
                  entry[:committed] = get_date(history[committed_index])
                end
                finished_index = find_finished(history, mapping)
                if finished_index && finished_index > find_last_ongoing(history, mapping)
                  entry[:finished] = get_date(history[finished_index])
                end
              end
            end
            @csv_file.put(entry)
          end
          @csv_file.close
        end
      end
      csv_file_location
    end

    def self.create
      new(Common::FilesAndJson.new, CsvFile.new)
    end

    private
    def relevant_event?(entry)
      ["CardMoveEventDTO", "CardCreationEventDTO"].include?(entry["Type"])
    end

    def matching_event?(entry, patterns)
      if patterns && !patterns.empty?
        patterns.each do |pattern|
          if entry["ToLaneTitle"] =~ Regexp.new(pattern)
            return true
          end
        end
      end
      false
    end

    def get_date(entry)
      Date.parse(entry["DateTime"]).to_date.to_s
    end

    def find_started(history, mapping)
      history.each_with_index do |entry, index|
        if relevant_event?(entry) && matching_event?(entry, mapping[:started.to_s])
          return index
        end
      end
      nil
    end

    def find_committed_before_started(history, mapping, started_index)
      history[0..started_index].reverse.each_with_index do |entry, index|
        if relevant_event?(entry) && matching_event?(entry, mapping[:committed.to_s])
          return started_index - index
        end
      end
      nil
    end

    def find_finished(history, mapping)
      find_last_entry_in_history(history, mapping[:finished.to_s])
    end

    def find_backlog(history, mapping)
      find_first_entry_in_history(history, mapping[:backlog.to_s])
    end

    def find_last_ongoing(history, mapping)
      find_last_entry_in_history(history, mapping[:started.to_s])
    end

    def find_last_entry_in_history(history, pattern)
      history.reverse.each_with_index do |entry, index|
        if relevant_event?(entry) && matching_event?(entry, pattern)
          return history.length - 1 - index
        end
      end
      nil
    end

    def find_first_entry_in_history(history, pattern)
      history.each_with_index do |entry, index|
        if relevant_event?(entry) && matching_event?(entry, pattern)
          return index
        end
      end
      nil
    end
  end
end
