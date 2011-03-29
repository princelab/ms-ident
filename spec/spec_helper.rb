require 'rubygems'

$spec_large = ENV['SPEC_LARGE']

require 'spec/more'

load_testdata = lambda do 
  require 'ms/testdata'
  SEQUEST_DIR = Ms::TESTDATA + '/sequest' 
end

load_testdata.call if $spec_large

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Bacon.summary_on_exit

def spec_large(&block)
  if $spec_large
    block.call
  else
    # Requires SPEC_LARGE=true and tfiles_large dir for testing large test files
    it 'SKIPPING (not testing large files)' do
    end
  end
end

TESTFILES = File.dirname(__FILE__) + '/tfiles'
