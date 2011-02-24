
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

  # takes a hash of name, value pairs
  # if block given, spectrum_queries (should be array of spectrum queries) is
  # set to the return value of the block
  def initialize(hash={}, &block)
    hash.each do |k,v|
      self.send("#{k}=", v)
    end
    @spectrum_queries = []
    @spectrum_queries = block.call if block
  end

  # takes an xml builder object
  def to_xml(xml)
    xml.msms_run_summary(:base_name => base_name, :msManufacturer => ms_manufacturer, :msModel => ms_model, :msIonization => ms_ionization, :msMassAnalyzer => ms_mass_analyzer, :msDetector => ms_detector, :raw_data_type => raw_data_type, :raw_data => raw_data) do
      xml.sample_enzyme.to_xml(xml) if sample_enzyme
      search_summary.to_xml(xml) if search_summary
      spectrum_queries.each {|sq| sq.to_xml(xml)} if spectrum_queries
    end
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
