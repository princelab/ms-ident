require 'set'

module Ms
  module Ident
    # represents a group of proteins, typically indistinguishable in the
    # experiment.
    class ProteinGroup < Array
      attr_accessor :peptide_hits

      PRIORITIZE_PROTEINS = lambda do |protein_group_and_peptide_hits|
        peptide_hits = protein_group_and_peptide_hits.last
        num_uniq_aaseqs = peptide_hits.map {|hit| hit.aaseq }.uniq.size
        num_uniq_aaseqs_at_z = peptide_hits.map {|hit| [hit.aaseq, hit.charge] }.uniq.size
        [num_uniq_aaseqs, num_uniq_aaseqs_at_z, peptide_hits.size]
      end

      # greedy algorithm to map a set of peptide_hits to protein groups.  each
      # peptide hit should respond to :aaseq, :charge, :proteins if a block is
      # given, yields a single argument: a doublet of protein_group and peptide
      # set.  It expects a metric or array to sort by for creating greedy protein
      # groups (the greediest proteins should sort to the back of the array).  if
      # no block is given, the groups are sorted by [# uniq aaseqs, # uniq
      # aaseq+charge, # peptide_hits] (see PRIORITIZE_PROTEINS).  Sets of
      # peptide_hits and the objects returned by peptide_hit#proteins are used as
      # hash keys.  As long as each peptide hit has a unique signature (like an
      # id) then any object will work.  If they are Struct objects, you might
      # consider redefining the #hash method to be object_id for performance and
      # accuracy.
      #
      # returns an array of ProteinGroup objects, each with a Set of
      # peptide_hits.
      def self.peptide_hits_to_protein_groups(peptide_hits, &sort_by)
        sort_by ||= PRIORITIZE_PROTEINS
        # note to self: I wrote this in 2011, so I think I know what I'm doing now
        protein_to_peptides = Hash.new {|h,k| h[k] = Set.new }
        peptide_hits.each do |peptide_hit|
          peptide_hit.proteins.each do |protein|
            protein_to_peptides[protein] << peptide_hit
          end
        end
        peptides_to_protein_group = Hash.new {|h,k| h[k] = [] }
        protein_to_peptides.each do |protein, peptide_set|
          peptides_to_protein_group[peptide_set] << protein
        end
        protein_group_to_peptides = peptides_to_protein_group.invert
        greedy_first = ProteinGroup.new(protein_group_to_peptides.sort_by(&sort_by).reverse)
        accounted_for = Set.new
        # we are discarding the subsumed sets, but we could get them with
        # partition
        greedy_first.select! do |group, peptide_set|
          has_an_unaccounted_peptide = false
          peptide_set.each do |peptide_hit| 
            unless accounted_for.include?(peptide_hit) 
              has_an_unaccounted_peptide = true
              accounted_for.add(peptide_hit)
            end
          end
          group.peptide_hits = peptide_set if has_an_unaccounted_peptide
          has_an_unaccounted_peptide
        end
        greedy_first
      end

    end
  end
end
