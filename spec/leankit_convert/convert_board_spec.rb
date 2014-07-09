require 'spec_helper_with_integration'

describe "convert board" do
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
        {"committed" => ["TODO"], "started" => ["^DOING:"], "finished" => ["DONE"]})
      copy_card_files("board", 5252, 7027)
      run_app(["leankit_dump"])
      files_are_the_same("leankit_dump/board.csv", "5252.csv")
    end
  end
end
