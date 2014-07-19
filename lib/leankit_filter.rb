require 'find'

def load_module(module_name)
  Find.find(File.expand_path("../../lib/#{module_name}", __FILE__)) do |file|
    if file.end_with?(".rb")
      require file
    end
  end
end

load_module("leankit_filter")
load_module("common")
