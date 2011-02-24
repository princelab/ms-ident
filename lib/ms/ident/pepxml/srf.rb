require 'ms/ident/pepxml'
require 'ms/ident/parameters'

module Ms ; end
module Ms::Ident ; end
module Ms::Ident::Pepxml ; end


class Ms::Ident::Pepxml::Srf 
  include Ms::Ident::Pepxml

  DEFAULT_OPTIONS = {
    ## MSMSRunSummary options:
    # string must be recognized in sample_enzyme.rb 
    # or create your own SampleEnzyme object
    :ms_manufacturer => 'Thermo',
    :ms_model => 'LTQ Orbitrap',
    :ms_ionization => 'ESI',
    :ms_mass_analyzer => 'Orbitrap',
    :ms_detector => 'UNKNOWN',
    :raw_data_type => "raw",
    :raw_data => ".mzXML", ## even if you don't have it?
    ## SearchSummary options:
    :out_data_type => "out", ## may be srf??
    :out_data => ".tgz", ## may be srf??
  }

  # will dynamically set :ms_model and :ms_mass_analyzer from srf info
  # See SRF::Sequest::Pepxml::DEFAULT_OPTIONS hash for defaults
  # unless given, the out_path will be given as the path of the srf_file
  # srf may be an object or a filename
  def self.new(srf, opts={})
    opts = DEFAULT_OPTIONS.merge(opts)

    ## read the srf file
    srf = Ms::Sequest::Srf.new(srf) if srf.is_a? String

    ## set the outpath
    out_path = opts.delete(:out_path)

    params = srf.params

    ## check to see if we need backup_db
    backup_db_path = opts.delete(:backup_db_path)
    if !File.exist?(params.database) && backup_db_path
      params.database_path = backup_db_path
    end

    #######################################################################
    # PREPARE THE OPTIONS:
    #######################################################################
    ## remove items from the options hash that don't belong to 
    ppxml_version = opts.delete(:pepxml_version)
    out_data_type = opts.delete(:out_data_type)
    out_data = opts.delete(:out_data)

    ## Extract meta info from srf
    bn_noext = base_name_noext(srf.header.raw_filename)
    opts[:ms_model] = srf.header.model
    case opts[:ms_model]
    when /Orbitrap/
      opts[:ms_mass_analyzer] = 'Orbitrap'
    when /LCQ Deca XP/
      opts[:ms_mass_analyzer] = 'Ion Trap'
    end

    ## Create the base name
    full_base_name_no_ext = make_base_name( File.expand_path(out_path), bn_noext)
    opts[:base_name] = full_base_name_no_ext

    ## Create the search summary:
    search_summary_options = {
      :search_database => Ms::Ident::Pepxml::SearchDatabase.new(params),
      :base_name => full_base_name_no_ext,
      :out_data_type => out_data_type,
      :out_data => out_data
    }
    modifications_string = srf.header.modifications
    search_summary = Ms::Ident::Pepxml::SearchSummary.new( params, modifications_string, search_summary_options)

    # create the sample enzyme from the params object:
    sample_enzyme_obj = 
      if opts[:sample_enzyme]
        opts[:sample_enzyme]
      else
        params.sample_enzyme
      end
    opts[:sample_enzyme] = sample_enzyme_obj

    ## Create the pepxml obj and top level objects
    pepxml_obj = Ms::Ident::Pepxml.new(ppxml_version, params) 
    pipeline = Ms::Ident::Pepxml::MSMSPipelineAnalysis.new({:date=>nil,:summary_xml=> bn_noext +'.xml'})
    pepxml_obj.msms_pipeline_analysis = pipeline
    pipeline.msms_run_summary = Ms::Ident::Pepxml::MSMSRunSummary.new(opts)
    pipeline.msms_run_summary.search_summary = search_summary
    modifications_obj = search_summary.modifications

    ## name some common variables we'll need
    h_plus = pepxml_obj.h_plus
    avg_parent = pepxml_obj.avg_parent

    #######################################################################
    # CREATE the spectrum_queries_ar
    #######################################################################
    srf_index = srf.index
    out_files = srf.out_files
    spectrum_queries_arr = Array.new(srf.dta_files.size)
    files_with_hits_index = 0  ## will end up being 1 indexed

    deltacn_orig = opts[:deltacn_orig]
    deltacn_index = 
      if deltacn_orig ; 20
      else 19
      end

    srf.dta_files.each_with_index do |dta_file,dta_i|
      next if out_files[dta_i].num_hits == 0
      files_with_hits_index += 1

      precursor_neutral_mass = dta_file.mh - h_plus

      (start_scan, end_scan, charge) = srf_index[dta_i]
      sq_hash = {
        :spectrum => [bn_noext, start_scan, end_scan, charge].join('.'),
        :start_scan => start_scan,
        :end_scan => end_scan,
        :precursor_neutral_mass => precursor_neutral_mass,
        :assumed_charge => charge.to_i,
        :pepxml_version => ppxml_version,
        :index => files_with_hits_index,
      }

      spectrum_query = Ms::Ident::Pepxml::SpectrumQuery.new(sq_hash)


      hits = out_files[dta_i].hits

      search_hits = 
        if opts[:all_hits]
          Array.new(out_files[dta_i].num_hits)  # all hits
        else
          Array.new(1)  # top hit only
        end

      (0...(search_hits.size)).each do |hit_i|
        hit = hits[hit_i]
        # under the modified deltacn schema (like bioworks)
        # Get proper deltacn and deltacnstar
        # under new srf, deltacn is already corrected for what prophet wants,
        # deltacn_orig_updated is how to access the old one
        # Prophet deltacn is not the same as the native Sequest deltacn
        # It is the deltacn of the second best hit!

        ## mass calculations:
        calc_neutral_pep_mass = hit[0] - h_plus


        sequence = hit.sequence

        #  NEED TO MODIFY SPLIT SEQUENCE TO DO MODS!
        ## THIS IS ALL INNER LOOP, so we make every effort at speed here:
        (prevaa, pepseq, nextaa) = SpecID::Pep.prepare_sequence(sequence)
        # 0=mh 1=deltacn_orig 2=sp 3=xcorr 4=id 5=num_other_loci 6=rsp 7=ions_matched 8=ions_total 9=sequence 10=prots 11=deltamass 12=ppm 13=aaseq 14=base_name 15=first_scan 16=last_scan 17=charge 18=srf 19=deltacn 20=deltacn_orig_updated

        sh_hash = {
          :hit_rank => hit_i+1,
          :peptide => pepseq,
          :peptide_prev_aa => prevaa,
          :peptide_next_aa => nextaa,
          :protein => hit[10].first.reference.split(" ").first, 
          :num_tot_proteins => hit[10].size,
          :num_matched_ions => hit[7],
          :tot_num_ions => hit[8],
          :calc_neutral_pep_mass => calc_neutral_pep_mass,
          :massdiff => precursor_neutral_mass - calc_neutral_pep_mass, 
          :num_tol_term => sample_enzyme_obj.num_tol_term(sequence),
          :num_missed_cleavages => sample_enzyme_obj.num_missed_cleavages(pepseq),
          :is_rejected => 0,
          # These are search score attributes:
          :xcorr => hit[3],
          :deltacn => hit[deltacn_index],
          :spscore => hit[2],
          :sprank => hit[6],
          :modification_info => modifications_obj.modification_info(SpecID::Pep.split_sequence(sequence)[1]),
        }
        unless deltacn_orig
          sh_hash[:deltacnstar] = 
            if hits[hit_i+1].nil?  # no next hit? then its deltacnstar == 1
              '1'
            else
              '0'
            end
        end
        search_hits[hit_i] = Ms::Ident::Pepxml::SearchHit.new(sh_hash) # there can be multiple hits
      end

      search_result = Ms::Ident::Pepxml::SearchResult.new
      search_result.search_hits = search_hits
      spectrum_query.search_results = [search_result]
      spectrum_queries_arr[files_with_hits_index] = spectrum_query
    end
    spectrum_queries_arr.compact!

    pipeline.msms_run_summary.spectrum_queries = spectrum_queries_arr 
    pepxml_obj.base_name = pipeline.msms_run_summary.base_name
    pipeline.msms_run_summary.spectrum_queries =  spectrum_queries_arr 

    pepxml_obj
  end

  def summary_xml
    base_name + ".xml"
  end

  def precursor_mass_type
    @params.precursor_mass_type
  end

  def fragment_mass_type
    @params.fragment_mass_type
  end

  # combines filename in a manner consistent with the path
  def self.make_base_name(path, filename)
    sep = '/'
    if path.split('/').size < path.split("\\").size
      sep = "\\"
    end
    if path.split('').last == sep
      path + File.basename(filename)
    else
      path + sep + File.basename(filename)
    end
  end

  # outputs pepxml, (to file if given)
  def to_pepxml(file=nil)
    string = header
    string << @msms_pipeline_analysis.to_pepxml

    if file
      File.open(file, "w") do |fh| fh.print string end
    end
    string
  end

  # given any kind of filename (from windows or whatever)
  # returns the base of the filename with no file extension
  def self.base_name_noext(file)
    file.gsub!("\\", '/')
    File.basename(file).sub(/\.[\w^\.]+$/, '')
  end
end # Pepxml
class Ms::Ident::Pepxml::Modifications
  include SpecIDXML

  # sequest params object
  attr_accessor :params
  # array holding AAModifications 
  attr_accessor :aa_mods
  # array holding TerminalModifications
  attr_accessor :term_mods
  # a hash of all differential modifications present by aa_one_letter_symbol
  # and special_symbol. This is NOT the mass difference but the total mass {
  # 'M*' => 155.5, 'S@' => 190.3 }.  NOTE: Since the termini are dependent on
  # the amino acid sequence, they are give the *differential* mass.  The
  # termini are given the special symbol as in sequest e.g. '[' => 12.22, #
  # cterminus    ']' => 14.55 # nterminus
  attr_accessor :masses_by_diff_mod_hash
  # a hash, key is [AA_one_letter_symbol.to_sym, difference.to_f]
  # values are the special_symbols
  attr_accessor :mod_symbols_hash

  # The modification symbols string looks like this:
  # (M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000)
  # ct is cterminal peptide (differential)
  # nt is nterminal peptide (differential)
  # the C is just cysteine
  # will set_modifications and masses_by_diff_mod hash
  def initialize(params=nil, modification_symbols_string='')
    @params = params
    if @params
      set_modifications(params, modification_symbols_string)
    end
  end

  # set the masses_by_diff_mod and mod_symbols_hash from 
  def set_hashes(modification_symbols_string)

    @mod_symbols_hash = {}
    @masses_by_diff_mod = {}
    if (modification_symbols_string == nil || modification_symbols_string == '')
      return nil
    end
    table = @params.mass_table
    modification_symbols_string.split(/\)\s+\(/).each do |mod|
      if mod =~ /\(?(\w+)(.) (.[\d\.]+)\)?/
        if $1 == 'ct' || $1 == 'nt' 
          mass_diff = $3.to_f
          @masses_by_diff_mod[$2] = mass_diff
          @mod_symbols_hash[[$1.to_sym, mass_diff]] = $2.dup
          # changed from below to match tests, is this right?
          # @mod_symbols_hash[[$1, mass_diff]] = $2.dup
        else
          symbol_string = $2.dup 
          mass_diff = $3.to_f
          $1.split('').each do |aa|
            aa_as_sym = aa.to_sym
            @masses_by_diff_mod[aa+symbol_string] = mass_diff + table[aa_as_sym]
            @mod_symbols_hash[[aa_as_sym, mass_diff]] = symbol_string
          end
        end
      end
    end
  end

  # given a bare peptide (no end pieces) returns a ModificationInfo object
  # e.g. given "]PEPT*IDE", NOT 'K.PEPTIDE.R'
  # if there are no modifications, returns nil
  def modification_info(peptide)
    if @masses_by_diff_mod.size == 0
      return nil
    end
    hash = {}
    hash[:modified_peptide] = peptide.dup
    hsh = @masses_by_diff_mod  
    table = @params.mass_table
    h = table[:h]  # this? or h_plus ??
    oh = table[:o] + h
    ## only the termini can match a single char
    if hsh.key? peptide[0,1]
      # AA + H + differential_mod
      hash[:mod_nterm_mass] = table[peptide[1,1].to_sym] + h + hsh[peptide[0,1]]
      peptide = peptide[1...(peptide.size)]
    end
    if hsh.key? peptide[(peptide.size-1),1]
      # AA + OH + differential_mod
      hash[:mod_cterm_mass] = table[peptide[(peptide.size-2),1].to_sym] + oh + hsh[peptide[-1,1]]
      peptide.slice!( 0..-2 )
      peptide = peptide[0...(peptide.size-1)]
    end
    mod_array = []
    (0...peptide.size).each do |i|
      if hsh.key? peptide[i,2]
        mod_array << Ms::Ident::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new([ i+1 , hsh[peptide[i,2]] ])
      end
    end
    if mod_array.size > 0
      hash[:mod_aminoacid_masses] = mod_array
    end
    if hash.size > 1  # if there is more than just the modified peptide there
      Ms::Ident::Pepxml::SearchHit::ModificationInfo.new(hash)
      #Ms::Ident::Pepxml::SearchHit::ModificationInfo.new(hash.values_at(:modified_peptide, :mod_aminoacid_masses, :mod_nterm_mass, :mod_cterm_mass)
    else
      nil
    end
  end

  # returns an array of static mod objects and static terminal mod objects
  def create_static_mods(params)

    ####################################
    ## static mods
    ####################################

    static_mods = [] # [[one_letter_amino_acid.to_sym, add_amount.to_f], ...]
    static_terminal_mods = [] # e.g. [add_Cterm_peptide, amount.to_f]

    params.mods.each do |k,v|
      v_to_f = v.to_f
      if v_to_f != 0.0
        if k =~ /add_(\w)_/
          static_mods << [$1.to_sym, v_to_f]
        else
          static_terminal_mods << [k, v_to_f]
        end
      end
    end
    aa_hash = params.mass_table

    ## Create the static_mods objects
    static_mods.map! do |mod|
      hash = {
        :aminoacid => mod[0].to_s,
        :massdiff => mod[1],
        :mass => aa_hash[mod[0]] + mod[1],
        :variable => 'N',
        :binary => 'Y',
      } 
      Ms::Ident::Pepxml::AAModification.new(hash)
    end

    ## Create the static_terminal_mods objects
    static_terminal_mods.map! do |mod|
      terminus = if mod[0] =~ /Cterm/ ; 'c'
                 else                 ; 'n' # only two possible termini
                 end
      protein_terminus = case mod[0] 
                         when /Nterm_protein/ ; 'n'
                         when /Cterm_protein/ ; 'c'
                         else nil
                         end

      # create the hash                            
      hash = {
        :terminus => terminus,
        :massdiff => mod[1],
        :variable => 'N',
        :description => mod[0],
      }
      hash[:protein_terminus] = protein_terminus if protein_terminus
      Ms::Ident::Pepxml::TerminalModification.new(hash)
    end
    [static_mods, static_terminal_mods]
  end

  # 1. sets aa_mods and term_mods from a sequest params object
  # 2. sets @params
  # 3. sets @masses_by_diff_mod
  def set_modifications(params, modification_symbols_string)
    @params = params

    set_hashes(modification_symbols_string)
    (static_mods, static_terminal_mods) = create_static_mods(params)

    aa_hash = params.mass_table
    #################################
    # Variable Mods:
    #################################
    arr = params.diff_search_options.rstrip.split(/\s+/)
    # [aa.to_sym, diff.to_f]
    variable_mods = []
    (0...arr.size).step(2) do |i|
      if arr[i].to_f != 0.0
        variable_mods << [arr[i+1], arr[i].to_f]
      end
    end
    mod_objects = []
    variable_mods.each do |mod|
      mod[0].split('').each do |aa|
        hash = {

          :aminoacid => aa,
          :massdiff => mod[1],
          :mass => aa_hash[aa.to_sym] + mod[1],
          :variable => 'Y',
          :binary => 'N',
          :symbol => @mod_symbols_hash[[aa.to_sym, mod[1]]],
        }
        mod_objects << Ms::Ident::Pepxml::AAModification.new(hash)
      end
    end
    variable_mods = mod_objects
    #################################
    # TERMINAL Variable Mods:
    #################################
    # These are always peptide, not protein termini (for sequest)
    (nterm_diff, cterm_diff) = params.term_diff_search_options.rstrip.split(/\s+/).map{|v| v.to_f }

    to_add = []
    if nterm_diff != 0.0
      to_add << ['n',nterm_diff.to_plus_minus_string, @mod_symbols_hash[:nt, nterm_diff]]
    end
    if cterm_diff != 0.0
      to_add << ['c', cterm_diff.to_plus_minus_string, @mod_symbols_hash[:ct, cterm_diff]]
    end

    variable_terminal_mods = to_add.map do |term, mssdiff, symb|
      hash = {
        :terminus => term,
        :massdiff => mssdiff,
        :variable => 'Y',
        :symbol => symb,
      }
      Ms::Ident::Pepxml::TerminalModification.new(hash)
    end

    #########################
    # COLLECT THEM
    #########################
    @aa_mods = static_mods + variable_mods
    @term_mods = static_terminal_mods + variable_terminal_mods
  end

  ## Generates the pepxml for static and differential amino acid mods based on
  ## sequest object
  def to_pepxml
    st = ''
    if @aa_mods
      st << @aa_mods.map {|v| v.to_pepxml }.join
    end
    if @term_mods
      st << @term_mods.map {|v| v.to_pepxml }.join
    end
    st
  end

end

# Modified aminoacid, static or variable
# unless otherwise stated, all attributes can be anything
class Ms::Ident::Pepxml::AAModification
  include SpecIDXML

  # The amino acid (one letter code)
  attr_accessor :aminoacid
  # Must be a string!!!!
  # Mass difference with respect to unmodified aminoacid, must begin with
  # either + (nonnegative) or - [e.g. +1.05446 or -2.3342]
  # consider Numeric#to_plus_minus_string at top
  attr_accessor :massdiff
  # Mass of modified aminoacid
  attr_accessor :mass
  # Y if both modified and unmodified aminoacid could be present in the
  # dataset, N if only modified aminoacid can be present
  attr_accessor :variable
  # whether modification can reside only at protein terminus (specified 'n',
  # 'c', or 'nc')
  attr_accessor :peptide_terminus
  # MSial symbol used by search engine to designate this modification
  attr_accessor :symbol
  # Y if each peptide must have only modified or unmodified aminoacid, N if a
  # peptide may contain both modified and unmodified aminoacid
  attr_accessor :binary

  def initialize(hash=nil)
    instance_var_set_from_hash(hash) if hash # can use unless there are weird methods
  end

  def to_pepxml
    # note massdiff
    short_element_xml_and_att_string("aminoacid_modification", "aminoacid=\"#{aminoacid}\" massdiff=\"#{massdiff.to_plus_minus_string}\" mass=\"#{mass}\" variable=\"#{variable}\" peptide_terminus=\"#{peptide_terminus}\" symbol=\"#{symbol}\" binary=\"#{binary}\"")
  end

end

# Modified aminoacid, static or variable
class Ms::Ident::Pepxml::TerminalModification
  include SpecIDXML

  # n for N-terminus, c for C-terminus
  attr_accessor :terminus
  # Mass difference with respect to unmodified terminus
  attr_accessor :massdiff
  # Mass of modified terminus
  attr_accessor :mass
  # Y if both modified and unmodified terminus could be present in the
  # dataset, N if only modified terminus can be present
  attr_accessor :variable
  # MSial symbol used by search engine to designate this modification
  attr_accessor :symbol
  # whether modification can reside only at protein terminus (specified n or
  # c)
  attr_accessor :protein_terminus
  attr_accessor :description

  def initialize(hash=nil)
    instance_var_set_from_hash(hash) if hash # can use unless there are weird methods
  end

  def to_pepxml
    #short_element_xml_from_instance_vars("terminal_modification")
    short_element_xml_and_att_string("terminal_modification", "terminus=\"#{terminus}\" massdiff=\"#{massdiff.to_plus_minus_string}\" mass=\"#{mass}\" variable=\"#{variable}\" symbol=\"#{symbol}\" protein_terminus=\"#{protein_terminus}\" description=\"#{description}\"")
  end
end


class Ms::Ident::Pepxml::SearchDatabase
  include SpecIDXML 
  attr_accessor :local_path
  attr_writer :seq_type
  # Takes a SequestParams object
  # Sets :local_path from the params object attr :database
  def initialize(params=nil, args=nil)
    @seq_type = nil
    if params
      @local_path = params.database
    end
    if args ; set_from_hash(args) end
  end

  def seq_type
    if @seq_type ; @seq_type
    else
      if @local_path =~ /\.fasta/
        'AA'
      else
        abort "Don't recognize type from your database local path: #{@local_path}"
      end
    end
  end

  def to_pepxml
    short_element_xml_and_att_string(:search_database, "local_path=\"#{local_path}\" type=\"#{seq_type}\"")
  end

end

Ms::Ident::Pepxml::SpectrumQuery = Arrayclass.new(%w(spectrum start_scan end_scan precursor_neutral_mass index assumed_charge search_results pepxml_version))

class Ms::Ident::Pepxml::SpectrumQuery
  include SpecIDXML

  ############################################################
  # FOR PEPXML:
  ############################################################
  def to_pepxml
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


Ms::Ident::Pepxml::SearchHit = Arrayclass.new( %w( hit_rank peptide peptide_prev_aa peptide_next_aa protein num_tot_proteins num_matched_ions tot_num_ions calc_neutral_pep_mass massdiff num_tol_term num_missed_cleavages is_rejected deltacnstar xcorr deltacn spscore sprank modification_info spectrum_query) )

# 0=hit_rank 1=peptide 2=peptide_prev_aa 3=peptide_next_aa 4=protein 5=num_tot_proteins 6=num_matched_ions 7=tot_num_ions 8=calc_neutral_pep_mass 9=massdiff 10=num_tol_term 11=num_missed_cleavages 12=is_rejected 13=deltacnstar 14=xcorr 15=deltacn 16=spscore 17=sprank 18=modification_info 19=spectrum_query

class Ms::Ident::Pepxml::SearchHit
  include SpecID::Pep
  include SpecIDXML

  Non_standard_amino_acid_char_re = /[^A-Z\.\-]/

    def aaseq ; self[1] end
  def aaseq=(arg) ; self[1] = arg end

  # These are all search_score elements:

  # 1 if there is no second ranked hit, 0 otherwise

  tmp_verb = $VERBOSE
  $VERBOSE = nil
  def initialize(hash=nil)
    super(self.class.size)
    if hash
      self[0,20] = [hash[:hit_rank], hash[:peptide], hash[:peptide_prev_aa], hash[:peptide_next_aa], hash[:protein], hash[:num_tot_proteins], hash[:num_matched_ions], hash[:tot_num_ions], hash[:calc_neutral_pep_mass], hash[:massdiff], hash[:num_tol_term], hash[:num_missed_cleavages], hash[:is_rejected], hash[:deltacnstar], hash[:xcorr], hash[:deltacn], hash[:spscore], hash[:sprank], hash[:modification_info], hash[:spectrum_query]]
    end
    self
  end
  $VERBOSE = tmp_verb

  undef_method :inspect
  def inspect
    var = @@attributes.map do |m| "#{m}:#{self.send(m)}" end.join(" ")
    "#<SearchHit #{var}>"
  end

  # Takes ions in the form XX/YY and returns [XX.to_i, YY.to_i]
  def self.split_ions(ions)
    ions.split("/").map {|ion| ion.to_i }
  end

  def search_score_xml(symbol)
    "#{tabs}<search_score name=\"#{symbol}\" value=\"#{send(symbol)}\"/>"
  end

  def search_scores_xml(*symbol_list)
    symbol_list.collect do |sy|
      search_score_xml(sy)
    end.join("\n") + "\n"
  end

  def to_pepxml
    mod_pepxml = 
      if self[18]
        self[18].to_pepxml
      else
        ''
      end

    #string = element_xml_and_att_string("search_hit", [:hit_rank, :peptide, :peptide_prev_aa, :peptide_next_aa, :protein, :num_tot_proteins, :num_matched_ions, :tot_num_ions, :calc_neutral_pep_mass, :massdiff_as_string, :num_tol_term, :num_missed_cleavages, :is_rejected]) do
    # note the to_plus_minus_string
    #puts "MASSDIFF:"
    #p massdiff
    element_xml_and_att_string("search_hit", "hit_rank=\"#{hit_rank}\" peptide=\"#{peptide}\" peptide_prev_aa=\"#{peptide_prev_aa}\" peptide_next_aa=\"#{peptide_next_aa}\" protein=\"#{protein}\" num_tot_proteins=\"#{num_tot_proteins}\" num_matched_ions=\"#{num_matched_ions}\" tot_num_ions=\"#{tot_num_ions}\" calc_neutral_pep_mass=\"#{calc_neutral_pep_mass}\" massdiff=\"#{massdiff.to_plus_minus_string}\" num_tol_term=\"#{num_tol_term}\" num_missed_cleavages=\"#{num_missed_cleavages}\" is_rejected=\"#{is_rejected}\"") do
      mod_pepxml +
        search_scores_xml(:xcorr, :deltacn, :deltacnstar, :spscore, :sprank)
    end
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


Ms::Ident::Pepxml::SearchHit::ModificationInfo = Arrayclass.new(%w(modified_peptide mod_aminoacid_masses mod_nterm_mass mod_cterm_mass))

# Positions and masses of modifications
class Ms::Ident::Pepxml::SearchHit::ModificationInfo
  include SpecIDXML

  ## Should be something like this:
  # <modification_info mod_nterm_mass=" " mod_nterm_mass=" " modified_peptide=" ">
  #   <mod_aminoacid_mass position=" " mass=" "/>
  # </modification_info>

  alias_method :masses, :mod_aminoacid_masses
  alias_method :masses=, :mod_aminoacid_masses=

    # Mass of modified N terminus<
    #attr_accessor :mod_nterm_mass
    # Mass of modified C terminus<
    #attr_accessor :mod_cterm_mass
    # Peptide sequence (with indicated modifications)  I'm assuming that the
    # native sequest indicators are OK here
    #attr_accessor :modified_peptide

    # These are objects of type: ...ModAminoacidMass
    # position ranges from 1 to peptide length
    #attr_accessor :mod_aminoacid_masses

    # Will escape any xml special chars in modified_peptide
    def to_pepxml
      ## Collect the modifications:
      mod_strings = []
      if masses and masses.size > 0
        mod_strings = masses.map do |ar|
          "position=\"#{ar[0]}\" mass=\"#{ar[1]}\""
        end
      end
      ## Create the attribute string:
      att_parts = []
      if mod_nterm_mass
        att_parts << "mod_nterm_mass=\"#{mod_nterm_mass}\""
      end
      if mod_cterm_mass
        att_parts << "mod_cterm_mass=\"#{mod_cterm_mass}\""
      end
      if modified_peptide
        att_parts << "modified_peptide=\"#{escape_special_chars(modified_peptide)}\""
      end
      element_xml_and_att_string('modification_info', att_parts.join(" ")) do
        mod_strings.map {|st| short_element_xml_and_att_string('mod_aminoacid_mass', st) }.join
      end
    end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  # returns self
  def from_pepxml_node(node)
    self[0] = node['modified_peptide'] 
    self[2] = node['mod_nterm_mass']
    self[3] = node['mod_cterm_mass']
    masses = []
    node.children do |mass_n|
      masses << Ms::Ident::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new([mass_n['position'].to_i, mass_n['mass'].to_f])
    end
    self[1] = masses
    self 
  end

  ## 

  # <modification_info modified_peptide="GC[546]M[147]PSKEVLSAGAHR">
  # <mod_aminoacid_mass position="2" mass="545.7160"/>
  # <mod_aminoacid_mass position="3" mass="147.1926"/>
  # </modification_info>
end

Ms::Ident::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass = Arrayclass.new(%w(position mass))
