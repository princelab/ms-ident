require 'nokogiri'

module Ms ; end
module Ms::Ident ; end
class Ms::Ident::Pepxml ; end

class Ms::Ident::Pepxml::SearchResult
  # an array of search_hits
  attr_accessor :search_hits

  # if block given, then yields an empty search_hits array
  def initialize(search_hits = [], &block)
    @search_hits = search_hits
    block.call(@search_hits) if block
  end

  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    builder.search_result do |xmlb|
      search_hits.each do |sh|
        sh.to_xml(xmlb)
      end
    end
    builder || xmlb.doc.root.to_xml 
  end

end

