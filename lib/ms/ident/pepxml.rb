require 'nokogiri'
require 'ms/ident'
require 'ms/ident/pepxml/msms_pipeline_analysis'

module Ms ; module Ident ; end ; end

class Numeric
  # returns a string with a + or - on the front
  def to_plus_minus_string
    if self >= 0
      '+' << self.to_s
    else
      self.to_s
    end
  end
end

class Ms::Ident::Pepxml
  XML_STYLESHEET_LOCATION = '/tools/bin/TPP/tpp/schema/pepXML_std.xsl'
  DEFAULT_PEPXML_VERSION = Msms_Pipeline_Analysis::PEPXML_VERSION

  attr_accessor :msms_pipeline_analysis

  def pepxml_version
    msms_pipeline_analysis.pepxml_version
  end

  # returns an array of spectrum queries
  def spectrum_queries
    msms_pipeline_analysis.msms_run_summary.spectrum_queries
  end

  # yields a new Msms_Pipeline_Analysis object if given a block 
  def initialize(&block)
    block.call(Msms_Pipeline_Analysis.new) if block
  end

  # takes an xml document object and sets it with the xml stylesheet
  def add_stylesheet(doc, location)
    xml_stylesheet = Nokogiri::XML::ProcessingInstruction.new(doc, "xml-stylesheet", %Q{type="text/xsl" href="#{location}"})
    doc.root.add_previous_sibling  xml_stylesheet
    doc
  end
  
  # writes xml file named msms_pipeline_analysis.summary_xml into the msms_run_summary.base_name directory
  def to_xml_file
    to_xml(File.dirname(msms_pipeline_analysis.msms_run_summary.base_name) + '/' + msms_pipeline_analysis.summary_xml)
  end

  # if no outfile is given, an xml string is returned.  summary_xml should
  # have already been set and is not influenced by the outfile given here.
  def to_xml(outfile=nil)
    builder = Nokogiri::XML::Builder.new
    add_stylesheet(builder.doc, Ms::Ident::Pepxml::XML_STYLESHEET_LOCATION)
    msms_pipeline_analysis.to_xml(builder)
    string = builder.to_xml
    outfile ? File.open(outfile,'w') {|out| out.print(string) } : string
  end
end


