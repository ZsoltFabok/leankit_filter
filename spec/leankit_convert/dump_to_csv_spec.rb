require 'spec_helper'

describe LeankitConvert::DumpToCsv do
  context "unit" do
  	before(:each) do
      @files_and_json = double
      @csv_file = double

      @location = "."
      @board_name = "board"
      @card_id = "1034204"
      @mapping = {"committed" => ["TODO"], "started" => ["^DOING:"], "finished" => ["DONE"]}
    end

  	it "writes the committed, started, and finished to the csv" do
  		@card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:10:48 PM"}]]
      expect(Dir).to receive(:foreach).with("#{@location}/#{@board_name}").and_yield("#{@card_id}.json").and_yield("#{@card_id}_history.json")
      expect(File).to receive(:exists?).with("#{@location}/#{@board_name}/#{@card_id}_history.json").and_return(true)
      expect(@files_and_json).to receive(:from_file).with("#{@location}/#{@board_name}/#{@card_id}_history.json").and_return(@card_history)
      expect(@csv_file).to receive(:open).with("#{@location}/#{@board_name}.csv", [:id, :committed, :started, :finished])
      expect(@csv_file).to receive(:put).with({id: "#{@card_id}", committed: "2013-09-16", started: "2013-09-17", finished: "2013-09-18"})
      expect(@csv_file).to receive(:close)
  		LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
  	end

    it "recognises creation event" do
      @card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardCreationEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:10:48 PM"}]]
      mock_card_info_and_history
      should_write_the_following_dates_to_csv("2013-09-16", "2013-09-17", "2013-09-18")
      LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
    end

  	it "considers the first ongoing history entry" do
  		@card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Review", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
      mock_card_info_and_history
      should_write_the_following_dates_to_csv("2013-09-16", "2013-09-17", "2013-09-19")
  		LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
  	end

  	it "considers the last done history entry if there are more than one" do
  		@card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING: Do", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
      mock_card_info_and_history
      should_write_the_following_dates_to_csv("2013-09-16", "2013-09-17", "2013-09-19")
  		LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
  	end

    it "should consider the last committed entry if it moved between TODO and Backlog before" do
      @card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "Backlog: ", "DateTime"=>"2013/09/17 at 03:10:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
      mock_card_info_and_history
      should_write_the_following_dates_to_csv("2013-09-18", "2013-09-18", "2013-09-19")
      LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
    end

    it "ignores the move in the same column" do
      @card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
      mock_card_info_and_history
      should_write_the_following_dates_to_csv("2013-09-16", "2013-09-18", "2013-09-19")
      LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
    end

    it "is able to handle items moving back actions" do
      @card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
      mock_card_info_and_history
      should_write_the_following_dates_to_csv("2013-09-16", "2013-09-18")
      LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
    end

    it "does not recognise done if it was moved back from the done column" do
      @card_history = [[{"CardId" => @card_id, "Type" => "CardCreationEventDTO"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "TODO", "DateTime"=>"2013/09/16 at 03:10:44 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/18 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DONE", "DateTime"=>"2013/09/19 at 03:16:48 PM"},
        {"Type" => "CardMoveEventDTO", "ToLaneTitle" => "DOING:", "DateTime"=>"2013/09/19 at 03:10:48 PM"}]]
      mock_card_info_and_history
      should_write_the_following_dates_to_csv("2013-09-16", "2013-09-18")
      LeankitConvert::DumpToCsv.new(@files_and_json, @csv_file).convert(@location, @board_name, @mapping)
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

    def mock_card_info_and_history
      allow(Dir).to receive(:foreach).with("#{@location}/#{@board_name}").and_yield("#{@card_id}.json")
      allow(Dir).to receive(:foreach).with("#{@location}/#{@board_name}").and_yield("#{@card_id}_history.json")
      allow(File).to receive(:exists?).with("#{@location}/#{@board_name}/#{@card_id}_history.json").and_return(true)
      allow(@files_and_json).to receive(:from_file).with("#{@location}/#{@board_name}/#{@card_id}_history.json").and_return(@card_history)
    end

    def should_write_the_following_dates_to_csv(*dates)
      allow(@csv_file).to receive(:open).with("#{@location}/#{@board_name}.csv", [:id, :committed, :started, :finished])
      if dates[2]
        allow(@csv_file).to receive(:put).with({id: "#{@card_id}", committed: dates[0], started: dates[1], finished: dates[2]})
      else
        allow(@csv_file).to receive(:put).with({id: "#{@card_id}", committed: dates[0], started: dates[1]})
      end
      allow(@csv_file).to receive(:close)
    end
  end
end
