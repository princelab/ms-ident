require 'rubygems'
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "ms-ident"
  gem.homepage = "http://github.com/jtprince/ms-ident"
  gem.license = "MIT"
  gem.summary = %Q{mspire library for working with mzIdentML and pepxml}
  gem.description = %Q{mspire library for working with mzIdentML, pepxml, and related.}
  gem.email = "jtprince@gmail.com"
  gem.authors = ["John T. Prince"]
  gem.rubyforge_project = 'mspire'
  gem.add_runtime_dependency 'nokogiri'
  gem.add_runtime_dependency 'ms-core', ">=0.0.12"
  gem.add_runtime_dependency 'ms-in_silico'
  gem.add_runtime_dependency 'andand'
  gem.add_development_dependency 'spec-more'
  gem.add_development_dependency 'jeweler'
  #gem.add_development_dependency 'ms-testdata'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |spec|
  spec.libs << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ms-ident #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
