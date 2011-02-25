module Ms ; end
module Ms::Ident ; end
class Ms::Ident::Pepxml ; end


Ms::Ident::Pepxml::SpectrumQuery = Arrayclass.new(%w(spectrum start_scan end_scan precursor_neutral_mass index assumed_charge search_results pepxml_version))

class Ms::Ident::Pepxml::SpectrumQuery

  ############################################################
  # FOR PEPXML:
  ############################################################
  def to_pepxml
    # consider retention_time_sec(??) in v19 and above....!!!!
    case Ms::Ident::Pepxml.pepxml_version
    when 18
      
      element_xml("spectrum_query", [:spectrum, :start_scan, :end_scan, :precursor_neutral_mass, :assumed_charge, :index]) do
        search_results.collect { |sr| sr.to_pepxml }.join
      end
    end
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  def from_pepxml_node(node)
    self[0] = node['spectrum']
    self[1] = node['start_scan'].to_i
    self[2] = node['end_scan'].to_i
    self[3] = node['precursor_neutral_mass'].to_f
    self[4] = node['index'].to_i
    self[5] = node['assumed_charge'].to_i
    self
  end

  # Returns the precursor_neutral based on the scans and an array indexed by
  # scan numbers.  first and last scan and charge should be integers.
  # This is the precursor_mz - h_plus!
  # by=:prec_mz_arr|:deltamass
  # if prec_mz_arr then the following arguments must be supplied:
  # :first_scan = int, :last_scan = int, :prec_mz_arr = array with the precursor
  # m/z for each product scan, :charge = int
  # if deltamass then the following arguments must be supplied:
  # m_plus_h = float, deltamass = float
  # For both flavors, a final additional argument 'average_weights'
  # can be used.  If true (default), average weights will be used, if false, 
  # monoisotopic weights (currently this is simply the mass of the proton)
  def self.calc_precursor_neutral_mass(by, *args)
    average_weights = true
    case by
    when :prec_mz_arr
      (first_scan, last_scan, prec_mz_arr, charge, average_weights) = args
    when :deltamass
      (m_plus_h, deltamass, average_weights) = args
    end

    if average_weights 
      mass_h_plus = SpecID::AVG[:h_plus] 
    else
      mass_h_plus = SpecID::MONO[:h_plus] 
    end

    case by
    when :prec_mz_arr
      mz = nil
      if first_scan != last_scan
        sum = 0.0
        tot_num = 0
        (first_scan..last_scan).each do |scan|
          val = prec_mz_arr[scan]
          if val  # if the scan is not an mslevel 2
            sum += val
            tot_num += 1
          end
        end
        mz = sum/tot_num
      else
        mz = prec_mz_arr[first_scan]
      end
      charge * (mz - mass_h_plus)
    when :deltamass
      m_plus_h - mass_h_plus + deltamass
    else
      abort "don't recognize 'by' in calc_precursor_neutral_mass: #{by}"
    end
  end

end


