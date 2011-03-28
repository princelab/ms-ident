module Ms ; end
module Ms::Ident ; end

require 'set'

module Ms::Ident::Protein
  
  class << self
  end

  # gives the information up until the first space or carriage return.
  # Assumes the protein can respond_to? :reference
  def first_entry
    reference.split(/[\s\r]/)[0]
  end

  # greedy algorithm to map a set of peptide_hits to protein groups.
  # each peptide hit should respond to :aaseq, :charge, :proteins if a block
  # is given, yields a set of peptide hits that then should return a metric(s)
  # to sort by for creating greedy protein groups.  if no block is given, the
  # groups are sorted by [# uniq aaseqs, # uniq aaseq+charge, # peptide_hits]
  def peptide_hits_to_protein_groups(peptide_hits, &sort_peptide_sets_by)
    sort_peptide_sets_by ||= lambda {|peptide_hits|
      num_uniq_aaseqs = peptide_hits.map {|hit| hit.aaseq }.uniq.size
      num_uniq_aaseqs_at_z = peptide_hits.map {|hit| [hit.aaseq, hit.charge] }.uniq.size
      [num_uniq_aaseqs, num_uniq_aaseqs_at_z, peptide_hits.size]
    }
    # note to self: I wrote this in 2011, so I think I know what I'm doing now
    protein_to_peptides = Hash.new {|h,k| h[k] = Set.new }
    peptide_hits.each do |peptide_hit|
      peptide_hit.proteins.each do |protein|
        protein_to_peptides[protein] << peptide
      end
    end
    peptides_to_protein_group = Hash.new {|h,k| h[k] = [] }
    protein_to_peptides.each do |protein, peptide_set|
      peptides_to_protein_group[peptide_set] << protein
    end
    sorted_peptide_sets = peptides_to_protein_group.keys.sort_by(&sort_peptide_sets_by)
    accounted_for = Set.new
    surviving_protein_groups = []
    peptide_sets_with_unaccounted_peptides = sorted_peptide_sets.select do |peptide_set|
      peptide_set.any? do |peptide_hit| 
        # has an unaccounted for peptide?
        accounted_for.include?(peptide_hit) ? false : accounted_for.add(peptide_hit)
      end
    end
    peptide_sets_with_unaccounted_peptides.map do |peptide_set|
      [peptides_to_protein_group[peptide_set], peptide_set]
    end
  end

end

