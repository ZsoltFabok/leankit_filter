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
      work_item_data(board_dump_location, board_name).each do |card_id, content|
        work_item = {:id => card_id}
        work_item.merge!(get_first_appearance_date(:backlog, content[:history], mapping))
        work_item.merge!(find_committed(content[:history], mapping))
        work_item.merge!(get_first_appearance_date(:started, content[:history], mapping))
        work_item.merge!(find_finished(content[:history], mapping))
        work_item.merge!(get_card_size(content[:info]))
        work_items << work_item
      end
      work_items
    end

    def work_item_data(board_dump_location, board_name)
      work_item_data = {}
      Dir.foreach(board_dump_location) do |file_name|
        if file_name =~ /([0-9]+)(_history)?.json/
          card_id = $1
          if !work_item_data.has_key?(card_id)
            work_item_data[card_id] = {}
          end

          content = @files_and_json.from_file(File.join(board_dump_location, file_name))
          if file_name.include?("history")
            work_item_data[card_id][:history] = content[0]
          else
            work_item_data[card_id][:info] = content[0]
          end
        end
      end
      work_item_data
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

    def get_card_size(info)
      size = info["Size"]
      if size != 0
        {:size => size}
      else
        {}
      end
    end
  end
end
