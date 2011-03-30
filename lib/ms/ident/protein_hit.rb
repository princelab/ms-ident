
module Ms ; end
module Ms::Ident ; end

class Ms::Ident::ProteinHit
  attr_accessor :id
  attr_accessor :seq
  alias_method :sequence, :seq
  alias_method :sequence=, :seq=
  attr_accessor :peptide_hits

  def initialize(id=nil)
    @peptide_hits = []
    @id = id
  end
end

