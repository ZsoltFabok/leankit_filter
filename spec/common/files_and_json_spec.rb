require 'spec_helper'

describe Common::FilesAndJson do
  it "reads data from a json file" do
    file = double
    filename = "filename"
    json_input = "input"
    expect(File).to receive(:open).with(filename, "r").and_return(file)
    expect(JSON).to receive(:load).with(file).and_return(json_input)
    expect(Common::FilesAndJson.new.from_file(filename)).to eq(json_input)
  end
end
