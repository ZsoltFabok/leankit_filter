# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'leankit_filter/version'

Gem::Specification.new do |s|
  s.name        = 'leankit_filter'
  s.version     = LeankitFilter::VERSION
  s.date        = '2014-07-15'
  s.summary     = "leankit_filter-#{s.version}"
  s.description = "Filters out information from downloaded Leankit card histories"
  s.authors     = ["Zsolt Fabok"]
  s.email       = 'me@zsoltfabok.com'
  s.homepage    = 'https://github.com/ZsoltFabok/leankit_filter'
  s.license     = 'BSD'

  s.files         = `git ls-files`.split("\n").reject {|path| path =~ /\.gitignore$/ || path =~ /file$/ }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency('rspec'  , '~> 3.0')
  s.add_development_dependency('rake'   , '~> 10.3')
end
