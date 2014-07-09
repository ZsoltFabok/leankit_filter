require 'spec_helper'
require 'json'

TEST_AT_FOLDER = "test_folder/at"
TEST_DATA_FOLDER = "test_folder/data"
MODIFICATION_DATE = {}


def clean_test_data
  FileUtils.rm_rf(TEST_AT_FOLDER)
  FileUtils.mkdir_p(File.join(TEST_AT_FOLDER, "leankit_dump"))
end

def go_to_test_dir
  Dir.chdir(TEST_AT_FOLDER)
end

def go_back
  Dir.chdir("../..")
end

def add_boards_to_config_file(*boards)
  boards_ = []
  boards.each do |board|
    boards_ << [board, {}]
  end
  File.open("boards.json", "w") {|f| f.write(JSON.pretty_generate({:boards => boards_}))}
end

def copy_card_files(board_name, board_id, card_id)
  history_file = "leankit_dump/#{board_name}/#{card_id}_history.json"
  FileUtils.mkdir_p("leankit_dump/#{board_name}") unless Dir.exists?("leankit_dump/#{board_name}")
  FileUtils.cp("../data/leankit_response_card_history_#{card_id}.json", history_file)
  FileUtils.cp("../data/leankit_response_card_find_#{board_id}_#{card_id}.json", "leankit_dump/#{board_name}/#{card_id}.json")
end

def add_board_column_mapping_to_config_file(board_name, mapping)
  File.open("boards.json", "w") {|f| f.write(JSON.pretty_generate({:boards => {board_name => mapping}}))}
end

def run_app(argv)
  LeankitConvert::Runner.run argv
end

def read_file(file_name)
  File.open(file_name).read
end

def write_file(file_name, content)
  File.open(file_name, "w") {|f| f.write(content)}
end

private
def files_are_the_same(filename1, filename2)
  expect(FileUtils.compare_file(filename1, File.join("../data", filename2))).to be true
end

def load_json(filename)
  JSON.load(File.open(File.join("../data", filename), "r"))
end
