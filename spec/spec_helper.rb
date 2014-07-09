require 'rspec'
require 'simplecov'

begin
  require "debugger"
rescue LoadError
  # most probably using 1.8
  require "ruby-debug"
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  # Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '/spec/'
end

require File.expand_path('../../lib/leankit_convert', __FILE__)
