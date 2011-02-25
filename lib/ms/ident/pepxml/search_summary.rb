require 'nokogiri'
require 'merge'

module Ms ; end
module Ms::Ident ; end
class Ms::Ident::Pepxml ; end

class Ms::Ident::Pepxml::SearchSummary
  DEFAULT_SEARCH_ID = '1'

  attr_accessor :base_name
  # required in v18-19, optional in later versions
  attr_accessor :out_data_type
  # required in v18-19, optional in later versions
  attr_accessor :out_data
  # by default, "1"
  attr_accessor :search_id
  # a Modifications object
  attr_accessor :modifications
  # A SearchDatabase object (responds to :local_path and :type)
  attr_accessor :search_database
  # the other search paramaters as a hash
  attr_accessor :parameters

  # An EnzymaticSearchConstraint object (at the moment this is merely a hash
  # with a few required keys
  attr_accessor :enzymatic_search_constraint

  def block_arg
    [@search_database = Ms::Ident::Pepxml::SearchDatabase.new,
      @enzymatic_search_constraint = Ms::Ident::Pepxml::EnzymaticSearchConstraint.new
      @modifications = Ms::Ident::Pepxml::Modifications.new,
      @parameters = Ms::Ident::Pepxml::Parameters.new,
    ]
  end

  def initialize(hash={}, &block)
    @search_id = DEFAULT_SEARCH_ID
    merge!(hash, &block)
  end

  def to_xml(builder=nil)
    # TODO: out_data and out_data_type are optional in later pepxml versions...
    # should work that in...
    attrs = [:base_name, :search_engine, :precursor_mass_type, :fragment_mass_type, :out_data_type, :out_data, :search_id]
    hash = Hash[ attrs.map {|at| [at, self.send(at)] } ]
    xmlb = builder || Nokogiri::XML::Builder.new
    builder.search_summary(hash) do |xmlb|
      search_database.to_xml(xmlb)
      if enzymatic_search_constraint
        xmlb.enzymatic_search_constraint(enzymatic_search_constraint)
      modifications_object.to_xml(xmlb)
      parameters.to_xml(xmlb)
    end
    builder || xmlb.doc.root.to_xml 
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    raise NotImplementedError, "not implemented just yet (just use the raw xml node)"
  end

  # requires these keys:  
  #
  #    :enzyme => a valid enzyme name
  #    :max_num_internal_cleavages => max number of internal cleavages allowed
  #    :min_number_termini => minimum number of termini??
  class EnzymaticSearchConstraint < Hash
  end
end



