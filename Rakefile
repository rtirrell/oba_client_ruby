require "rubygems"
require File.dirname(__FILE__) + "/lib/oba_client.rb"
#require "hoe"

#Hoe.plugin :yard

#Hoe.spec "oba-client" do
#  self.developer "Rob Tirrell", "rpt@stanford.edu"
#  self.url             = "http://rubyforge.org/projects/oba-client"
#    
#  self.yard_title      = "OBAClient Documentation"
#  self.yard_options    = ["--default-return", "void"]
#  self.yard_markup     = "markdown"
#  self.remote_yard_dir = ""
#
#  self.rubyforge_name = "oba-client"
#end

require "rubygems"
require "rake"

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name = "oba_client"
    gem.summary = "A client for the Open Biomedical Annotator."
    gem.description = "See above."
    gem.email = "rpt@stanford.edu"
    gem.homepage = "http://github.com/rtirrell/oba_client"
    gem.authors = ["Rob Tirrell"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.add_development_dependency "yard", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require "rake/testtask"
Rake::TestTask.new(:test) do |test|
  test.libs << "lib" << "test"
  test.pattern = "test/**/test_*.rb"
  test.verbose = true
end

begin
  require "rcov/rcovtask"
  Rcov::RcovTask.new do |test|
    test.libs << "test"
    test.pattern = "test/**/test_*.rb"
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

begin
  require "yard"
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
