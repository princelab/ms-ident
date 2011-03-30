require 'ms/ident/peptide_hit'

module Ms ; end
module Ms::Ident ; end

class Ms::Ident::PeptideHit
  module Qvalue
    attr_accessor :qvalue
    FILE_EXTENSION = '.phq.tsv'
    FILE_DELIMITER = "\t"
    HEADER = %w(aaseq charge qvalue)

    class << self

      # writes to the file, adding an extension
      def to_phq(base, hits, qvalues=[])
        to_file(base + FILE_EXTENSION, hits, qvalues)
      end

      # writes the peptide hits to a phq.tsv file. qvalues is a parallel array
      # to hits that can provide qvalues if not inherent to the hits
      # returns the filename.
      def to_file(filename, hits, qvalues=[])
        File.open(filename,'w') do |out|
          out.puts HEADER.join(FILE_DELIMITER)
          hits.zip(qvalues) do |hit, qvalue|
            out.puts [hit.aaseq, hit.charge, qvalue || hit.qvalue].join(FILE_DELIMITER)
          end
        end
        filename
      end

      # returns an array of PeptideHit objects from a phq.tsv
      def from_file(filename)
        peptide_hits = []
        File.open(filename) do |io|
          header = io.readline.chomp.split(FILE_DELIMITER)
          raise "bad headers" unless header == HEADER 
          io.each do |line|
            line.chomp!
            (aaseq, charge, qvalue) = line.split(FILE_DELIMITER)
            ph = Ms::Ident::PeptideHit.new
            ph.aaseq = aaseq ; ph.charge = charge.to_i ; ph.qvalue = qvalue.to_f
            peptide_hits << ph
          end
        end
        peptide_hits
      end

      alias_method :from_phq, :from_file

    end
  end # Qvalue
  include Qvalue
end # Peptide Hit
