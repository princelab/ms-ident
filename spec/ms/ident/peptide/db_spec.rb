require 'spec_helper'

require 'yaml'
path = 'ms/ident/peptide/db'
require path 

module Kernel
 
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.rewind
    return out.read
  ensure
    $stdout = STDOUT
  end
 
end

FASTA_FILE = [TESTFILES, path, 'uni_11_sp_tr.fasta'].join('/')

describe 'amino acid expansion' do

  it 'can expand out wildcard amino acid combinations' do
    array = Ms::Ident::Peptide::Db.expand_peptides('ALXX', 'X' =>  %w(* % &), 'L' => %w(P Q) )
    array.sort.is %w(AP** AP*% AP*& AP%* AP%% AP%& AP&* AP&% AP&& AQ** AQ*% AQ*& AQ%* AQ%% AQ%& AQ&* AQ&% AQ&&).sort
  end

  it 'will not expand explosive combinations (>MAX_NUM_AA_EXPANSION)' do
    # this is from real data
    worst_case = 'LTLLRPEKHEAATGVDTICTHRVDPIGPGLXXEXLYWELSXLTXXIXELGPYTLDR'
    Ms::Ident::Peptide::Db.expand_peptides(worst_case, 'X' =>  %w(* % &)).nil?.is true
  end

  it 'returns the peptide in the array if no expansion' do
    array = Ms::Ident::Peptide::Db.expand_peptides('ZZZZZ', 'X' =>  %w(* % &), 'L' => %w(P Q) )
    array.is ['ZZZZZ']
  end

end

describe 'creating a peptide centric database' do

  before do
    
    #@output_file = [TESTFILES, path, 'uni_11_sp_tr.'].join('/')
    @output_file = [TESTFILES, path, "uni_11_sp_tr.msd_clvg2.min_aaseq4.yml"].join('/')
  end

  it 'converts a fasta file into peptide centric db' do
    output_files = Ms::Ident::Peptide::Db.cmdline([FASTA_FILE])
    output_files.first.is File.expand_path(@output_file)
    ok File.exist?(@output_file)
    hash = {}
    YAML.load_file(@output_file).each do |k,v|
      hash[k] = v.split("\t")
    end
    sorted = hash.sort
    # these are merely frozen, not perfectly defined
    sorted.first.is ["AAFDDAIAELDTLSEESYK", ["sp|P62258|1433E_HUMAN"]]
    sorted.last.is ["YWCRLGPPRWICQTIVSTNQYTHHR", ["tr|D2KTA8|D2KTA8_HUMAN"]]
    sorted.size.is 728
    File.unlink(@output_file)
  end

  it 'lists approved enzymes and exits' do
    output = capture_stdout do
      begin
        Ms::Ident::Peptide::Db.cmdline(['--list-enzymes'])
      rescue SystemExit
        1.is 1 # we exited
      end
    end
    lines = output.split("\n")
    ok lines.include?("trypsin")
    ok lines.include?("chymotrypsin")
  end
end

describe 'reading a peptide centric database' do
  outfiles = Ms::Ident::Peptide::Db.cmdline([FASTA_FILE])
  @outfile = outfiles.first

  it 'reads the file on disk with random access or is enumerable' do
    Ms::Ident::Peptide::Db::IO.open(@outfile) do |io|
      io["AVTEQGHELSNEER"].enums %w(sp|P31946|1433B_HUMAN	sp|P31946-2|1433B_HUMAN)
      io["VRAAR"].enums ["tr|D3DX18|D3DX18_HUMAN"]
      io.each_with_index do |key_prots, i|
        key_prots.first.isa String
        key_prots.last.isa Array
      end
    end
  end
end
