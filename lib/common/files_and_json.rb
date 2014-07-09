require 'json'

module Common
  class FilesAndJson
    def from_file(filename)
      JSON.load(File.open(filename, "r"))
    end
  end
end
