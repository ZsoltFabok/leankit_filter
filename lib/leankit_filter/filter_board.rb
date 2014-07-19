module LeankitFilter
  class FilterBoard
    def initialize(files_and_json)
      @files_and_json = files_and_json
    end

    def filter(boards_json, board_dump_location)
      board_name = File.basename(board_dump_location)
      content = @files_and_json.from_file(boards_json)
      mapping = nil
      content["boards"].each do |board, mapping_|
        if board == board_name
          mapping = mapping_
          break
        end
      end

      [board_name, get_work_items(board_dump_location, board_name, mapping)]
    end

    def self.create
      new(Common::FilesAndJson.new)
    end

    private
    def get_work_items(board_dump_location, board_name, mapping)
      work_items = []
      find_history_files(board_dump_location, board_name).each do |card_id, history_file_location|
        work_item = {:id => card_id}
        history = @files_and_json.from_file(history_file_location)[0]
        work_item.merge!(get_first_appearance_date(:backlog, history, mapping))
        work_item.merge!(find_committed(history, mapping))
        work_item.merge!(get_first_appearance_date(:started, history, mapping))
        work_item.merge!(find_finished(history, mapping))
        work_items << work_item
      end
      work_items
    end

    def find_history_files(board_dump_location, board_name)
      files = []
      Dir.foreach(board_dump_location) do |file_name|
        if file_name =~ /([0-9]+)_history.json/
          card_id = $1
          files << [card_id, File.join(board_dump_location, "#{card_id}_history.json")]
        end
      end
      files
    end

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

    def get_first_appearance_date(column, history, mapping)
      index = find_first_entry_in_history(history, mapping[column.to_s])
      if index
        {column => get_date(history[index])}
      else
        {}
      end
    end

    def get_last_appearance_date(column, history, mapping)
      index = find_last_entry_in_history(history, mapping[column.to_s])
      if index
        {column => get_date(history[index])}
      else
        {}
      end
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

    def find_committed(history, mapping)
      started_index = find_first_entry_in_history(history, mapping[:started.to_s])
      if started_index
        get_last_appearance_date(:committed, history[0..started_index-1], mapping)
      else
        {}
      end
    end

    def find_finished(history, mapping)
      column = :finished
      pattern = mapping[column.to_s]
      index = find_last_entry_in_history(history, pattern)
      if index
        next_relevant_entries = history[index+1..-1].select {|entry| relevant_event?(entry)}
        if matching_event?(history[index-1], pattern)
          return {column => get_date(history[index-1])}
        elsif next_relevant_entries.empty? || next_relevant_entries[0]["ToLaneTitle"] == "Archive"
          return {column => get_date(history[index])}
        end
      end
      return {}
    end
  end
end
