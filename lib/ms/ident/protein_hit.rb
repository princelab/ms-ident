require 'andand'


module Ms ; end
module Ms::Ident ; end

class Ms::Ident::ProteinHit < Ms::Ident::Protein
  attr_accessor :peptide_hits

  def initialize(id=nil, peptide_hits=[])
    @peptide_hits = peptide_hits
    @id = id
  end

  # if the GN=([^\s]+) regexp is found in the description, returns the first
  # match, or nil if not found
  def gene_id
    description.andand.match(/ GN=(\w+) ?/)[1]
  end
end

