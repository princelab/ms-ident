
require 'spec_helper'
require 'ms/ident/pepxml/sample_enzyme'
require 'nokogiri'

describe 'creating an Ms::Ident::Pepxml::SampleEnzyme' do
  before do
    @hash = {
      :name => 'trypsin',
      :cut => 'KR',
      :no_cut => 'P',
      :sense => 'C',
    }
  end
  it 'can be set by a known enzyme name' do
    se = Ms::Ident::Pepxml::SampleEnzyme.new('trypsin')
    @hash.each do |k,v|
      se.send(k).is v
    end
  end

  it 'can be set manually with a hash' do
    se = Ms::Ident::Pepxml::SampleEnzyme.new(@hash)
    @hash.each do |k,v|
      se.send(k).is v
    end
  end
end

describe 'an Ms::Ident::Pepxml::SampleEnzyme' do
  before do
    @sample_enzyme = Ms::Ident::Pepxml::SampleEnzyme.new(:name=>'trypsin',:cut=>'KR',:no_cut=>'P',:sense=>'C')
  end
  it 'generates a valid xml fragment' do
    string = @sample_enzyme.to_xml
    ok string.is_a?(String)
    string.matches(/<sample_enzyme name="trypsin"/)
    string.matches(/<specificity/) 
    %w(cut="KR" no_cut="P" sense="C").each {|re| string.matches(/#{re}/) }
    ok !string.include?('version')
  end
  it 'adds to an xml builder object' do
    builder = Nokogiri::XML::Builder.new
    after = @sample_enzyme.to_xml(builder)
    ok after.is_a?(Nokogiri::XML::Builder)
    after.is builder
    ok after.to_xml.is_a?(String)
  end
end

xdescribe 'read in from an xml node' do
  # placeholder until written
end

### DOES this kind of functionality belong in this kind of container????
### SHOULD it be with ms-enzyme or ms-in_silico  ???????

=begin
require 'set'

describe 'Ms::Ident::Pepxml::SampleEnzyme digesting sequences' do
  it 'can digest with no missed cleavages' do
    st = "CRGATKKTAGRPMEK"
    SampleEnzyme.tryptic(st).should == %w(CR GATK K TAGRPMEK)
    st = "CATRP"
    SampleEnzyme.tryptic(st).should == %w(CATRP)
    st = "RCATRP"
    SampleEnzyme.tryptic(st).should == %w(R CATRP)
    st = ""
    SampleEnzyme.tryptic(st).should == []
    st = "R"
    SampleEnzyme.tryptic(st).should == %w(R)
  end

  it 'can digest with missed cleavages' do
    st = "CRGATKKTAGRPMEKLLLERTKY"
    zero = %w(CR GATK K TAGRPMEK LLLER TK Y)
    SampleEnzyme.tryptic(st,0).to_set.should == zero.to_set
    one = %w(CRGATK GATKK KTAGRPMEK TAGRPMEKLLLER LLLERTK TKY)
    SampleEnzyme.tryptic(st,1).to_set.should == (zero+one).to_set
    two = %w(CRGATKK GATKKTAGRPMEK KTAGRPMEKLLLER TAGRPMEKLLLERTK LLLERTKY)
    all = zero + one + two
    SampleEnzyme.tryptic(st,2).to_set.should == all.to_set
  end

  it 'contains duplicates IF there are duplicate tryptic sequences' do
    st = "AAAAKCCCCKDDDDKCCCCK"
    peps = SampleEnzyme.new('trypsin').digest(st, 2)
    peps.select {|aaseq| aaseq == 'CCCCK'}.size.should == 2
  end
  
end

describe SampleEnzyme, 'making enzyme calculations on sequences and aaseqs' do

  before(:each) do
    @full_KRP = SampleEnzyme.new do |se|
      se.name = 'trypsin'
      se.cut = 'KR'
      se.no_cut = 'P'
      se.sense = 'C'
    end
    @just_KR = SampleEnzyme.new do |se|
      se.name = 'trypsin'
      se.cut = 'KR'
      se.no_cut = ''
      se.sense = 'C'
    end
  end

  it 'calculates the number of tolerant termini' do
    exp = [{
      # full KR/P
      'K.EPTIDR.E' => 2,
      'K.PEPTIDR.E' => 1,
      'F.EEPTIDR.E' => 1,
      'F.PEPTIDW.R' => 0,
    },
    {
      # just KR
      'K.EPTIDR.E' => 2,
      'K.PEPTIDR.E' => 2,
      'F.EEPTIDR.E' => 1,
      'F.PEPTIDW.R' => 0,
    }
    ]
    scall = Sequest::PepXML::SearchHit
    sample_enzyme_ar = [@full_KRP, @just_KR]
    sample_enzyme_ar.zip(exp) do |sample_enzyme,hash|
      hash.each do |seq, val|
        sample_enzyme.num_tol_term(seq).should == val
      end
    end
  end

  it 'calculates number of missed cleavages' do
    exp = [{
    "EPTIDR" => 0,
    "PEPTIDR" => 0,
    "EEPTIDR" => 0,
    "PEPTIDW" => 0,
    "PERPTIDW" => 0,
    "PEPKPTIDW" => 0,
    "PEPKTIDW" => 1,
    "RTTIDR" => 1,
    "RTTIKK" => 2,
    "PKEPRTIDW" => 2,
    "PKEPRTIDKP" => 2,
    "PKEPRAALKPEERPTIDKW" => 3,
    },
    {
    "EPTIDR" => 0,
    "PEPTIDR" => 0,
    "EEPTIDR" => 0,
    "PEPTIDW" => 0,
    "PERPTIDW" => 1,
    "PEPKPTIDW" => 1,
    "PEPKTIDW" => 1,
    "RTTIDR" => 1,
    "RTTIKK" => 2,
    "PKEPRTIDW" => 2,
    "PKEPRTIDKP" => 3,
    "PKEPRAALKPEERPTIDKW" => 5,
    }
    ]

    sample_enzyme_ar = [@full_KRP, @just_KR]
    sample_enzyme_ar.zip(exp) do |sample_enzyme, hash|
      hash.each do |aaseq, val|
        #first, middle, last = SpecID::Pep.split_sequence(seq)
        # note that we are only using the middle section!
        sample_enzyme.num_missed_cleavages(aaseq).should == val
      end
    end
  end

end
=end



