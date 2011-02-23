
module Ms
  module Ident

    # returns the filetype (if possible)
    def self.filetype(file)
      if file =~ /\.srf$/i
        :srf
      end
    end
  end
end
