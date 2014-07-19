require 'spec_helper_with_integration'

describe LeankitFilter::ProcessBoard do
  context "unit" do
  	before(:each) do
      @files_and_json = double
      @csv_file = double

      @dump_location = "leankit_dump"
      @board_location = "board"
      @location = File.join(@dump_location, @board_location)
      @board_name = "board"
      @card_id = "1034204"
      @mapping = {"backlog" => ["Backlog"], "committed" => ["TODO"], "started" => ["^DOING:"], "finished" => ["DONE"]}
    end

    describe "#to_csv" do
    	it "writes the committed, started, and finished to the csv" do
    		@card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:10:48 PM"}]]
        expect(Dir).to receive(:foreach).with("#{@location}").and_yield("#{@card_id}.json").and_yield("#{@card_id}_history.json")
        expect(File).to receive(:exists?).with("#{@location}/#{@card_id}_history.json").and_return(true)
        expect(@files_and_json).to receive(:from_file).with("#{@location}/#{@card_id}_history.json").and_return(@card_history)
        expect(@csv_file).to receive(:open).with("#{@dump_location}/#{@board_name}.csv", [:id, :backlog, :committed, :started, :finished])
        expect(@csv_file).to receive(:put).with({id: "#{@card_id}", :backlog=>"2013-09-15", committed: "2013-09-16", started: "2013-09-17", finished: "2013-09-18"})
        expect(@csv_file).to receive(:close)

    		csv_location = LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)

        expect(csv_location).to eql("#{@dump_location}/#{@board_name}.csv")
    	end

      it "recognises creation event" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardCreationEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:10:48 PM"}]]
        mock_card_info_and_history
        should_write_the_following_dates_to_csv("2013-09-15", "2013-09-16", "2013-09-17", "2013-09-18")
        LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)
      end

    	it "considers the first ongoing history entry" do
    		@card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Review", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        should_write_the_following_dates_to_csv("2013-09-15", "2013-09-16", "2013-09-17", "2013-09-19")
    		LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)
    	end

    	it "considers the last done history entry if there are more than one" do
    		@card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        should_write_the_following_dates_to_csv("2013-09-15", "2013-09-16", "2013-09-17", "2013-09-19")
    		LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)
    	end

      it "should consider the last committed entry if it moved between TODO and Backlog before" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "Backlog: ", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        should_write_the_following_dates_to_csv("2013-09-15", "2013-09-18", "2013-09-18", "2013-09-19")
        LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)
      end

      it "ignores the move in the same column" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        should_write_the_following_dates_to_csv("2013-09-15", "2013-09-16", "2013-09-18", "2013-09-19")
        LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)
      end

      it "is able to handle items moving back actions" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        should_write_the_following_dates_to_csv("2013-09-15", "2013-09-16", "2013-09-18")
        LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)
      end

      it "does not recognise done if it was moved back from the done column" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        should_write_the_following_dates_to_csv("2013-09-15", "2013-09-16", "2013-09-18")
        LeankitFilter::ProcessBoard.new(@files_and_json, @csv_file).to_csv(@location, @board_name, @mapping)
      end

      it "handles portofolio boards" # do
      #   card_info_1 = [{"Id" => @card_id + "1", "ParentCardId" => @card_id}]
      #   card_info_2 = [{"Id" => @card_id + "2", "ParentCardId" => @card_id}]
      #   card_info_3 = [{"Id" => @card_id + "3", "ParentCardId" => @card_id}]
      #   card_history = [[{"CardId" => @card_id + "1", "Type" => "CardCreationEventDTO"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "week", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "Done", "DateTime"=>"2013/09/19 at 03:16:48 PM"}]]
      #   card_history_1 = [[{"CardId" => @card_id + "1", "Type" => "CardCreationEventDTO"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:16:48 PM"}]]
      #   card_history_2 = [[{"CardId" => @card_id + "2", "Type" => "CardCreationEventDTO"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:16:48 PM"}]]
      #   card_history_3 = [[{"CardId" => @card_id + "3", "Type" => "CardCreationEventDTO"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
      #     {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:16:48 PM"}]]
      # end

      it "counts the backward movements"
    end

    def mock_card_info_and_history
      allow(Dir).to receive(:foreach).with("#{@location}").and_yield("#{@card_id}.json")
      allow(Dir).to receive(:foreach).with("#{@location}").and_yield("#{@card_id}_history.json")
      allow(File).to receive(:exists?).with("#{@location}/#{@card_id}_history.json").and_return(true)
      allow(@files_and_json).to receive(:from_file).with("#{@location}/#{@card_id}_history.json").and_return(@card_history)
    end

    def should_write_the_following_dates_to_csv(*dates)
      allow(@csv_file).to receive(:open).with("#{@dump_location}/#{@board_name}.csv", [:id, :backlog, :committed, :started, :finished])
      if dates[3]
        allow(@csv_file).to receive(:put).with({id: "#{@card_id}", backlog: dates[0], committed: dates[1], started: dates[2], finished: dates[3]})
      else
        allow(@csv_file).to receive(:put).with({id: "#{@card_id}", backlog: dates[0], committed: dates[1], started: dates[2]})
      end
      allow(@csv_file).to receive(:close)
    end
  end

  context "integration" do
    before(:each) do
      clean_test_data
      go_to_test_dir
    end

    after(:each) do
      go_back
    end

    it "writes the committed, started, and finished to the csv file" do
      add_board_column_mapping_to_config_file("board", \
        {"backlog" => ["Backlog"], "committed" => ["TODO"], "started" => ["^DOING:"], "finished" => ["DONE"]})
      copy_card_files("board", 5252, 7027)
      run_app(["boards.json", "leankit_dump/board"])
      files_are_the_same("leankit_dump/board.csv", "5252.csv")
    end
  end
end
