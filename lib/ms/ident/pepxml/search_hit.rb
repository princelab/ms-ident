require 'nokogiri'

module Ms ; end
module Ms::Ident ; end


module Ms::Ident::Pepxml 

  Ms::Ident::Pepxml::SearchHit = Struct.new(:hit_rank, :peptide, :peptide_prev_aa, :peptide_next_aa, :protein, :num_tot_proteins, :num_matched_ions, :tot_num_ions, :calc_neutral_pep_mass, :massdiff, :num_tol_term, :num_missed_cleavages, :is_rejected, :modification_info, :search_scores, :spectrum_query) do

    # 0=hit_rank 1=peptide 2=peptide_prev_aa 3=peptide_next_aa 4=protein 5=num_tot_proteins 6=num_matched_ions 7=tot_num_ions 8=calc_neutral_pep_mass 9=massdiff 10=num_tol_term 11=num_missed_cleavages 12=is_rejected 13=deltacnstar 14=xcorr 15=deltacn 16=spscore 17=sprank 18=modification_info 19=spectrum_query

    Non_standard_amino_acid_char_re = %r{[^A-Z\.\-]}

    alias_method :aaseq, :peptide
    alias_method :aaseq=, :peptide=

      # deltacnstar: 1 if there is no second ranked hit, 0 otherwise
      def initialize(hash={})
        super(*hash.values_at(:hit_rank, :peptide, :peptide_prev_aa, :peptide_next_aa, :protein, :num_tot_proteins, :num_matched_ions, :tot_num_ions, :calc_neutral_pep_mass, :massdiff, :num_tol_term, :num_missed_cleavages, :is_rejected, :modification_info, :search_scores, :spectrum_query))
      end

    def to_xml(builder=nil)
      xmlb = builder || Nokogiri::XML::Builder.new
      attrs = Hash[self.members[0...-3].zip(self.to_a)]
      attrs[:massdiff] = attrs[:massdiff].to_plus_minus_string
      xmlb.search_hit(attrs) do |xmlb|
        self.modification_info.to_xml(xmlb)
        self.search_scores.to_xml(xmlb)
      end
      builder || xmlb.doc.root.to_xml
    end

    def from_pepxml_node(node)
      self[0] = node['hit_rank'].to_i
      self[1] = node['peptide']
      self[2] = node['peptide_prev_aa']
      self[3] = node['peptide_next_aa']
      self[4] = node['protein']  ## will this be the string?? (yes, for now)
      self[5] = node['num_tot_proteins'].to_i
      self[6] = node['num_matched_ions'].to_i
      self[7] = node['tot_num_ions'].to_i
      self[8] = node['calc_neutral_pep_mass'].to_f
      self[9] = node['massdiff'].to_f
      self[10] = node['num_tol_term'].to_i
      self[11] = node['num_missed_cleavages'].to_i
      self[12] = node['is_rejected'].to_i
      self
    end
  end

end


