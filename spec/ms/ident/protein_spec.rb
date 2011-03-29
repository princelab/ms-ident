require 'spec_helper'

require 'ms/ident/protein'

PeptideHit = Struct.new(:aaseq, :charge, :proteins) do
  def inspect
    "<PeptideHit aaseq=#{self.aaseq} charge=#{self.charge} proteins(ids)=#{self.proteins.map(&:id).join(',')}>"
  end
end
ProteinHit = Struct.new(:id) do
  def inspect
    "<Prt #{self.id}>"
  end
end

describe 'creating minimal protein groups from peptide hits' do
  before do
    @pep_hits = [ ['AABBCCDD', 2], 
      ['BBCC', 2],
      ['DDEEFFGG', 2],
      ['DDEEFFGG', 3],
      ['HIYA', 2],
    ].map {|ar| PeptideHit.new(ar[0], ar[1], []) }
    { 'big_guy' => @pep_hits,
      'little_guy' => [@pep_hits.last],
      'medium_guy' => @pep_hits[0,4],
      'subsumed_by_medium' => @pep_hits[2,2],
    }.each do |id, peptides|
      peptides.each {|pep| pep.proteins << ProteinHit.new(id) }
    end
  end
  
  it 'works' do
    reply = Ms::Ident::Protein.peptide_hits_to_protein_groups(@pep_hits)
    reply.each do |group, peptide_hits|
      puts "GROUP / PEPS: "
      p group
      p peptide_hits
    end
    1.is 1
  end


end
