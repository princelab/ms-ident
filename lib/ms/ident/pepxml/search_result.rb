require 'nokogiri'

module Ms ; end
module Ms::Ident ; end
class Ms::Ident::Pepxml ; end

class Ms::Ident::Pepxml::SearchResult
  # an array of search_hits
  attr_accessor :search_hits

  # if block given, then search_hits set to return value
  def initialize(search_hits = [])
    @search_hits = search_hits
  end

  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    builder.search_result do |xmlb|
      search_hits.each do |sh|
        sh.to_xml(xmlb)
      end
    end
    builder || xmlb.to_xml 
  end

end

