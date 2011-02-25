require 'nokogiri'

module Ms ; end
module Ms::Ident ; end
class Ms::Ident::Pepxml ; end

module Ms::Ident::Pepxml::Modifications

  # array holding AminoacidModification  objects
  attr_accessor :aminoacid_modifications
  # array holding TerminalModifications
  attr_accessor :terminal_modifications

  def modifications
    aminoacid_modifications + terminal_modifications
  end

  ## Generates the pepxml for static and differential amino acid mods based on
  ## sequest object
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    aminoacid_modifications.each {|aa_mod| aa_mod.to_xml(xmlb)}
    terminal_modifications.each {|term_mod| term_mod.to_xml(xmlb) }
    builder || xmlb.to_xml
  end
end

# Modified aminoacid, static or variable
# unless otherwise stated, all attributes can be anything
class Ms::Ident::Pepxml::AminoacidModification
  # The amino acid (one letter code)
  attr_accessor :aminoacid
  # Mass difference with respect to unmodified aminoacid, as a Float
  attr_accessor :massdiff
  # Mass of modified aminoacid, Float
  attr_accessor :mass
  # Y if both modified and unmodified aminoacid could be present in the
  # dataset, N if only modified aminoacid can be present
  attr_accessor :variable
  # whether modification can reside only at protein terminus (specified 'n',
  # 'c', or 'nc')
  attr_accessor :peptide_terminus
  # Symbol used by search engine to designate this modification
  attr_accessor :symbol
  # 'Y' if each peptide must have only modified or unmodified aminoacid, 'N' if a
  # peptide may contain both modified and unmodified aminoacid
  attr_accessor :binary

  def initialize(hash={})
    hash.each {|k,v| send("#{k}=",v) }
  end

  # returns the builder or an xml string if no builder supplied
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    # note massdiff: must begin with either + (nonnegative) or - [e.g.
    # +1.05446 or -2.3342] consider Numeric#to_plus_minus_string in
    # Ms::Ident::Pepxml
    attrs = Hash[ [:aminoacid, :massdiff, :mass, :variable, :peptide_terminus, :symbol, :binary].map {|at| [at, send(at)] } ]
    attrs[:massdiff] = attrs[:massdiff].to_plus_minus_string
    xmlb.aminoacid_modification(attrs)
    builder || xmlb.to_xml
  end
end

# Modified aminoacid, static or variable
class Ms::Ident::Pepxml::TerminalModification
  # n for N-terminus, c for C-terminus
  attr_accessor :terminus
  # Mass difference with respect to unmodified terminus
  attr_accessor :massdiff
  # Mass of modified terminus
  attr_accessor :mass
  # Y if both modified and unmodified terminus could be present in the
  # dataset, N if only modified terminus can be present
  attr_accessor :variable
  # MSial symbol used by search engine to designate this modification
  attr_accessor :symbol
  # whether modification can reside only at protein terminus (specified n or
  # c)
  attr_accessor :protein_terminus
  attr_accessor :description

  def initialize(hash=nil)
    instance_var_set_from_hash(hash) if hash # can use unless there are weird methods
  end

  # returns the builder or an xml string if no builder supplied
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    #short_element_xml_from_instance_vars("terminal_modification")
    attrs = Hash[ [:terminus, :massdiff, :mass, :variable, :protein_terminus, :description].map {|at| [at, send(at)] } ]
    attrs[:massdiff] = attrs[:massdiff].to_plus_minus_string
    xmlb.terminal_modification(attrs)
    builder || xmlb.to_xml
  end
end


