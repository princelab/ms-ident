module Ms ; end
module Ms::Ident ; end


class Ms::Ident::Protein

  attr_accessor :id
  attr_accessor :seq
  alias_method :sequence, :seq
  alias_method :sequence=, :seq=

  attr_accessor :description

  def initialize(id=nil, seq=nil)
    (@id, @seq) = id, seq
  end

  # DEPRECATING THIS GUY
  ## gives the information up until the first space or carriage return.
  ## Assumes the protein can respond_to? :reference
  #def first_entry
  #  reference.split(/[\s\r]/)[0]
  #end
end

