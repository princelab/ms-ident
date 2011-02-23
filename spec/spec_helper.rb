require 'rubygems'
require 'bundler'

$spec_large = ENV['SPEC_LARGE']

def spec_large(&block)
  if $spec_large
    block.call
  else
    # Requires SPEC_LARGE=true and tfiles_large dir for testing large test files
    it 'SKIPPING (not testing large files)' do
    end
  end
end

development = $spec_large ? :development_large : :development

begin
  Bundler.setup(:default, development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'spec/more'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Bacon.summary_on_exit

SEQUEST_DIR = TESTDATA + '/sequest'
