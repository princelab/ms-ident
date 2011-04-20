module Ms ; end
module Ms::Ident ; end

class Ms::Ident::PeptideHit
  attr_accessor :id
  attr_accessor :missed_cleavages
  attr_accessor :aaseq
  attr_accessor :charge
  attr_accessor :proteins
  attr_accessor :qvalue
end
