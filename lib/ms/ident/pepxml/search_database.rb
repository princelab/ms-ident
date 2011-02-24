require 'ms-fasta'

module Ms ; end
module Ms::Ident ; end

module Ms::Ident::Pepxml
  class SearchDatabase
    # required! the local, full path to the protein sequence database
    attr_accessor :local_path
    # required! 'AA' or 'NA'
    attr_accessor :seq_type

    # optional
    attr_accessor :database_name
    # optional
    attr_accessor :orig_database_url
    # optional
    attr_accessor :database_release_date
    # optional
    attr_accessor :database_release_identifier
    # optional
    attr_accessor :size_of_residues

    # takes a hash to fill in values
    def initialize(hash={}, get_size_of_residues=false)
      hash.each {|k,v| send("#{k}=", v) }
      if get_size_of_residues && File.exist?(@local_path)
        @size_of_residues = 0
        Ms::Fasta.foreach(@local_path) do |entry|
          @size_of_residues += entry.sequence.size
        end
      end
    end

    def to_xml(builder)
      attrs = [:local_path, :seq_type, :database_name, :orig_database_url, :database_release_date, :database_release_identifier, :size_of_residues].map {|k| [k, send(k)] if k }.compact
      builder.search_database(Hash[attrs])
    end
  end

end
