require 'spec_helper_with_integration'

describe LeankitFilter::CsvFile do
  context "integration" do
    before(:each) do
      clean_test_data
      go_to_test_dir
      @file = LeankitFilter::CsvFile.new
      @file_name = "a.csv"
    end

    after(:each) do
      go_back
    end

    it "creates a new csv file" do
      @file.open(@file_name, [:id, :committed, :started, :finished])
      @file.put({id: 1, committed: 2, started: 3, finished: 4})
      @file.close

      expect(read_file(@file_name)).to eql("id,committed,started,finished\n1,2,3,4\n")
    end

    it "updates a field in the csv file" do
      write_file(@file_name, "id,committed,started,finished\n1,2,3,4\n2,3,,\n3,4,5,6\n")
      @file.open(@file_name, [:id, :committed, :started, :finished])
      @file.put({id: 2, started: 4, finished: 5})
      @file.close

      expect(read_file(@file_name)).to eql("id,committed,started,finished\n1,2,3,4\n2,3,4,5\n3,4,5,6\n")
    end
  end
end
