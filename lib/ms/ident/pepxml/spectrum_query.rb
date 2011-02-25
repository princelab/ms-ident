require 'nokogiri'
require 'ms/mass'

module Ms ; end
module Ms::Ident ; end
class Ms::Ident::Pepxml ; end

# search_specification is a search constraint applied specifically to this query (a String)
Ms::Ident::Pepxml::SpectrumQuery = Struct.new(:spectrum, :start_scan, :end_scan, :precursor_neutral_mass, :index, :assumed_charge, :retention_time_sec, :search_specification, :search_results, :pepxml_version) do

  Required = Set.new([:spectrum, :start_scan, :end_scan, :precursor_neutral_mass, :index, :assumed_charge])
  Optional = [:retention_time_sec, :search_specification]

  # yeilds the empty search_results array if given a block
  def initialize(*args, &block)
    search_results = []
    super(*args)
    block.call(search_results) if block
  end

  ############################################################
  # FOR PEPXML:
  ############################################################
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    # all through search_specification
    attrs = members[0, 8].map {|at| v=send(at) ; [at, v] if v }
    attrs_hash = Hash[attrs]
    case pepxml_version
    when 18
      attrs_hash.delete(:retention_time_sec)
    end
    xmlb.spectrum_query(attrs_hash) do |xmlb|
      search_results.to_xml(xmlb) 
    end
    builder || xmlb.doc.root.to_xml
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    self[0] = node['spectrum']
    self[1] = node['start_scan'].to_i
    self[2] = node['end_scan'].to_i
    self[3] = node['precursor_neutral_mass'].to_f
    self[4] = node['index'].to_i
    self[5] = node['assumed_charge'].to_i
    self
  end

  def self.calc_precursor_neutral_mass(m_plus_h, deltamass, h_plus=Ms::Mass::H_PLUS)
    m_plus_h - h_plus + deltamass
  end
end


