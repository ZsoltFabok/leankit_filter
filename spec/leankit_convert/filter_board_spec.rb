require 'spec_helper_with_integration'

describe LeankitFilter::FilterBoard do
  context "unit" do
  	before(:each) do
      allow_debugging

      @files_and_json = double
      @csv_file = double

      @dump_location = "leankit_dump"
      @board_location = "board"
      @location = File.join(@dump_location, @board_location)
      @board_name = "board"
      @card_id = "1034204"
      @card_type = "dev"
      @mapping = {"backlog" => ["Backlog"], "committed" => ["TODO"], "started" => ["^DOING:"], "finished" => ["DONE"]}
      @card_info = [{"Id" => @card_id, "Size" => 0, "TypeName" => @card_type}]
    end

    describe "#filter" do
    	it "collects backlog, committed, started and finished" do
    		@card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "Archive", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

        result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-16", :started => "2013-09-17", :finished => "2013-09-18"}]]
    	end

      it "recognises creation event" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardCreationEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

        result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-16", :started => "2013-09-17", :finished => "2013-09-18"}]]
      end

    	it "considers the first ongoing history entry" do
    		@card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Review", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

    		result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-16", :started => "2013-09-17", :finished => "2013-09-19"}]]
    	end

    	it "considers the last done history entry if there are more than one" do
    		@card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

    		result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-16", :started => "2013-09-17", :finished => "2013-09-18"}]]
    	end

      it "considers the last committed entry if it moved between TODO and Backlog before" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "Backlog: ", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

        result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-18", :started => "2013-09-18", :finished => "2013-09-19"}]]
      end

      it "ignores the move in the same column" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

        result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-16", :started => "2013-09-18", :finished => "2013-09-19"}]]
      end

      it "is able to handle items moving back actions" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

        result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-16", :started => "2013-09-18"}]]
      end

      it "does not recognise done if it was moved back from the done column" do
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

        result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :committed => "2013-09-16", :started => "2013-09-18"}]]
      end

      it "collects the card size from the info" do
        card_size = 3
        @card_info[0]["Size"] = card_size
        @card_history = [[
          {"CardId" => @card_id, "Type" => "CardCreationEventDTO", "ToLaneTitle" => "Backlog", "DateTime"=>"2013/09/15 at 03:10:44 PM"},
          {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"}]]
        mock_card_info_and_history
        mock_read_boards_json

        result = LeankitFilter::FilterBoard.new(@files_and_json).filter("boards.json", @location)
        expect(result).to eq [@board_name, [{:id => @card_id, :type => @card_type,
          :backlog => "2013-09-15", :size => card_size}]]
      end
    end

    def mock_card_info_and_history
      allow(Dir).to receive(:foreach).with("#{@location}").and_yield("#{@card_id}.json").and_yield("#{@card_id}_history.json")
      allow(File).to receive(:exists?).with("#{@location}/#{@card_id}_history.json").and_return(true)
      allow(@files_and_json).to receive(:from_file).with("#{@location}/#{@card_id}.json").and_return(@card_info)
      allow(@files_and_json).to receive(:from_file).with("#{@location}/#{@card_id}_history.json").and_return(@card_history)
    end

    def allow_debugging
      allow(File).to receive(:exists?).with("#{Dir.pwd}/.rdebugrc").and_return(false)
      allow(File).to receive(:exists?).with("#{Dir.home}/.rdebugrc").and_return(false)
    end

    def mock_read_boards_json
      allow(@files_and_json).to receive(:from_file).with("boards.json").and_return({"boards" => {@board_name => @mapping}})
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

    it "csv is the default renderer" do
      add_board_column_mapping_to_config_file("board", \
        {"backlog" => ["Backlog"], "committed" => ["TODO"], "started" => ["^DOING:"], "finished" => ["DONE"]})
      copy_card_files("board", 5252, 7027)
      run_app(["boards.json", "leankit_dump/board"])
      files_are_the_same("leankit_dump/board.csv", "5252.csv")
    end

    it "writes the committed, started, and finished to the csv file" do
      add_board_column_mapping_to_config_file("board", \
        {"backlog" => ["Backlog"], "committed" => ["TODO"], "started" => ["^DOING:"], "finished" => ["DONE"]})
      copy_card_files("board", 5252, 7027)
      run_app(["--csv", "boards.json", "leankit_dump/board"])
      files_are_the_same("leankit_dump/board.csv", "5252.csv")
    end
  end
end
