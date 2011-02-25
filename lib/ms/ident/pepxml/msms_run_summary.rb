require 'merge'
require 'nokogiri'

module Ms ; end
module Ms::Ident ; end
module Ms::Ident::Pepxml; end

class Ms::Ident::Pepxml::MsmsRunSummary
  # The name of the pep xml file without any extension
  attr_accessor :base_name
  # The name of the mass spec manufacturer 
  attr_accessor :ms_manufacturer
  attr_accessor :ms_model
  attr_accessor :ms_mass_analyzer
  attr_accessor :ms_detector
  attr_accessor :raw_data_type
  attr_accessor :raw_data
  attr_accessor :ms_ionization
  attr_accessor :pepxml_version

  # A SampleEnzyme object (responds to: name, cut, no_cut, sense)
  attr_accessor :sample_enzyme
  # A SearchSummary object
  attr_accessor :search_summary
  # An array of spectrum_queries
  attr_accessor :spectrum_queries

  def block_arg
    [@sample_enzyme = Ms::Ident::Pepxml::SampleEnzyme.new,    
      @search_summary = Ms::Ident::Pepxml::SearchSummary.new,
      @spectrum_queries ]
  end

  # takes a hash of name, value pairs
  # if block given, yields a SampleEnzyme object, a SearchSummary and an array
  # for SpectrumQueries
  def initialize(hash={}, &block)
    @spectrum_queries = []
    merge!(hash, &block)
    block.call() if block
  end

  # optionally takes an xml builder object and returns the builder, or the xml
  # string if no builder was given
  def to_xml(builder)
    xmlb = builder || Nokogiri::XML::Builder.new
    xml.msms_run_summary(:base_name => base_name, :msManufacturer => ms_manufacturer, :msModel => ms_model, :msIonization => ms_ionization, :msMassAnalyzer => ms_mass_analyzer, :msDetector => ms_detector, :raw_data_type => raw_data_type, :raw_data => raw_data) do
      xml.sample_enzyme.to_xml(xml) if sample_enzyme
      search_summary.to_xml(xml) if search_summary
      spectrum_queries.each {|sq| sq.to_xml(xml)} if spectrum_queries
    end
    builder || xmlb.doc.root.to_xml
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  # peps correspond to search_results
  def from_pepxml_node(node)
    @base_name = node['base_name']
    @ms_manufacturer = node['msManufacturer']
    @ms_model = node['msModel']
    @ms_manufacturer = node['msIonization']
    @ms_mass_analyzer = node['msMassAnalyzer']
    @ms_detector = node['msDetector']
    @raw_data_type = node['raw_data_type']
    @raw_data = node['raw_data']
    self
  end
end
