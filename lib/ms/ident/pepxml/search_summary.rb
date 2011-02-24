require 'nokogiri'

module Ms ; end
module Ms::Ident ; end
module Ms::Ident::Pepxml ; end

class Ms::Ident::Pepxml::SearchSummary
  DEFAULT_SEARCH_ID = '1'

  attr_accessor :search_params  # renamed from params
  attr_accessor :base_name
  attr_accessor :out_data_type
  attr_accessor :out_data
  # by default, "1"
  attr_accessor :search_id
  attr_accessor :modifications
  # A SearchDatabase object (responds to :local_path and :type)
  attr_accessor :search_database
  # if given a sequest params object, then will set the following attributes:
  # args is a hash of parameters
  # modifications_string -> See Modifications

  # should respond to :enzyme, :max_num_internal_cleavages,
  # :min_number_termini.  Can be nil for a no enzyme search
  attr_accessor :enzymatic_search_constraint

  # IMPORTANT:
  #####     @modifications = Ms::Ident::Pepxml::Modifications.new(search_params, modifications_string)

  def initialize(search_params=nil, modifications_object, other={})
    @search_id = DEFAULT_SEARCH_ID
    if search_params
      @search_params = search_params
    end
    other.each {|k,v| send("#{k}=", v) }
  end

  def method_missing(symbol, *args)
    if @search_params ; @search_params.send(symbol, *args) end
  end

  def to_xml(builder=nil)
    attrs = [:base_name, :search_engine, :precursor_mass_type, :fragment_mass_type, :out_data_type, :out_data, :search_id]
    hash = Hash[ attrs.map {|at| [at, self.send(at)] } ]
    xmlb = builder || Nokogiri::XML::Builder.new
    builder.search_summary(hash) do |xmlb|
      search_database.to_xml(xmlb)
      if enzymatic_search_constraint
        esc = enzymatic_search_constraint
        xmlb.enzymatic_search_constraint(:enzyme => esc.enzyme, :max_num_internal_cleavages => esc.max_num_internal_cleavages, :min_number_termini => esc.min_number_termini)
      modifications_object.to_xml(xmlb)
      Ms::Ident::Pepxml::Parameters.new(@search_params).to_xml(xmlb)
    end
    builder || xmlb.to_xml 
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    raise NotImplementedError, "right now we just have the xml node at your disposal"
  end

end

