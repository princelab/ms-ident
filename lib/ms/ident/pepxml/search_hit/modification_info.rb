require 'andand'
require 'nokogiri'

module Ms ; end
module Ms::Ident ; end
class Ms::Ident::Pepxml ; end
class Ms::Ident::Pepxml::SearchHit ; end


# Positions and masses of modifications
Ms::Ident::Pepxml::SearchHit::ModificationInfo = Struct.new(:modified_peptide, :mod_aminoacid_masses, :mod_nterm_mass, :mod_cterm_mass) do
  ## Should be something like this:
  # <modification_info mod_nterm_mass=" " mod_nterm_mass=" " modified_peptide=" ">
  #   <mod_aminoacid_mass position=" " mass=" "/>
  # </modification_info>
  # e.g.:
  # <modification_info modified_peptide="GC[546]M[147]PSKEVLSAGAHR">
  #   <mod_aminoacid_mass position="2" mass="545.7160"/>
  #   <mod_aminoacid_mass position="3" mass="147.1926"/>
  # </modification_info>

  # Mass of modified N terminus<
  #attr_accessor :mod_nterm_mass
  # Mass of modified C terminus<
  #attr_accessor :mod_cterm_mass
  # Peptide sequence (with indicated modifications)  I'm assuming that the
  # native sequest indicators are OK here
  #attr_accessor :modified_peptide

  # These are objects of type: ...ModAminoacidMass
  # position ranges from 1 to peptide length
  #attr_accessor :mod_aminoacid_masses

  class << self
    alias_method :old_new, :new
    # takes either a hash or the normal list of values to set.
    def new(*args)
      if args.first.is_a?(Hash)
        args = args.first.values_at(*members)
      end
      obj = old_new(*args)
      obj
    end
  end

  # Will escape any xml special chars in modified_peptide
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    ## Collect the modifications:
    ## Create the attribute string:
    atts = [:mod_nterm_mass, :mod_cterm_mass, :modified_peptide]
    atts.map! {|at| (v=send(at)) && [at, v] }.compact
    xmlb.modification_info(Hash[atts]) do
      mod_aminoacid_masses.andand.each do |mod_aa_mass|
        mod_aa_mass.to_xml(xmlb)
      end
    end
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  # returns self
  def from_pepxml_node(node)
    self[0] = node['modified_peptide'] 
    self[2] = node['mod_nterm_mass']
    self[3] = node['mod_cterm_mass']
    _masses = []
    node.children do |mass_n|
      _masses << Ms::Ident::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new([mass_n['position'].to_i, mass_n['mass'].to_f])
    end
    self.mod_aminoacid_masses = _masses
    self 
  end
end

Ms::Ident::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass = Struct.new(:position, :mass) do
  def to_xml(builder)
    builder.mod_aminoacid_mass(:position => position, :mass => mass)
  end
end
