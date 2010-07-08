require "rubygems"
require "nokogiri"
require "cgi"
require "net/http"
require "uri"

class OBAClient
  VERSION = "1.0.3"

  # A high HTTP read timeout, as the service sometimes takes awhile to respond.
  DEFAULT_TIMEOUT = 30

  # The endpoint URI for the production version of the Annotator service.
  DEFAULT_URI = "http://rest.bioontology.org/obs/annotator"

  # The header for every request. There's no need to specify this per-instance.
  HEADER = {"Content-Type" => "application/x-www-form-urlencoded"}
    
  # Parameters the annotator accepts. Any one not in this list (excluding
  # textToAnnotate) is not valid.
  ANNOTATOR_PARAMETERS = [
    :wholeWordOnly, 
    :scored,
    :ontologiesToExpand,
    :ontologiesToKeepInResult,
    :semanticTypes,
    :withDefaultStopWords,
    :format,
    :levelMax,
    :mappingTypes,
    :email
  ]

  # Instantiate the class with a set of reused options. Options used by the
  # method are:
  #
  #   * [String] uri: the URI of the annotator service (default: {DEFAULT_URI}).
  #   * [Fixnum] timeout: the length of the read timeout (default: {DEFAULT_TIMEOUT}).
  #   * [Boolean] parse_xml: whether to parse the received text (default: false).
  # @param [Hash<String, String>] options Parameters for the annotation.
  def initialize(options = {})
    @uri         = URI.parse(options.delete(:uri) || DEFAULT_URI)
    @timeout     = options.delete(:timeout)       || DEFAULT_TIMEOUT
    @parse_xml   = options.delete(:parse_xml)
    
    @options     = {}
    options.each do |k, v|
      if !ANNOTATOR_PARAMETERS.include?(k)
        puts "WARNING: #{k} is not a valid annotator parameter."
      end
      if v.is_a? Array
        @options[k] = v.join(",")
      else
        @options[k] = v
      end
    end
    
    if !@options.include?(:email)
      puts "TIP: as a courtesy, consider including your email in the request." if !$DEBUG
    end
  end

  # Perform the annotation.
  # @param [String] text The text to annotate.
  # @return [Hash<Symbol, Array>, String, nil] A Hash representing the parsed
  #   document, the raw XML if parsing is not requested, or nil if the
  #   request times out.
  def execute(text)
    request = Net::HTTP::Post.new(@uri.path, initheader=HEADER)
    request.body = {:textToAnnotate => text}.merge(@options).map do |k, v|
      "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
    end.join("&")

    begin
      response = Net::HTTP.new(@uri.host, @uri.port).start do |http|
        http.read_timeout = @timeout
        http.request(request)
      end
      @parse_xml ? self.class.parse(response.body) : response.body
    rescue Timeout::Error
      puts "Request for #{text[0..10]} timed-out at #{@timeout} seconds."
    end
  end

  # Parse the raw XML, returning a Hash with three elements: statistics,
  # annotations, and ontologies. Respectively, these represent the annotation
  # statistics (annotations by mapping type, etc., as a Hash), an Array of
  # each annotation (as a Hash), and an Array of ontologies used (also as
  # a Hash).
  # @param [String] xml The XMl we'll be parsing.
  # @return [Hash<Symbol, Object>] A Hash representation of the XML, as
  #   described above.
  def self.parse(xml)
    statistics  = []
    annotations = []
    ontologies  = []
    doc = Nokogiri::XML.parse(xml)

    doc.xpath("//annotationBean").each do |ann|
      parsed = {}
      parsed[:score]           = ann.xpath("score").text.to_i
      parsed[:id]              = ann.xpath("concept/id").text.to_i
      parsed[:localConceptId]  = ann.xpath("concept/localConceptId")
      parsed[:localOntologyId] = ann.xpath("concept/localOntologyId").text.to_i
      parsed[:isTopLevel]      = ann.xpath("concept/isTopLevel").text.to_i
      parsed[:fullId]          = ann.xpath("concept/fullId").text
      parsed[:preferredName]   = ann.xpath("concept/preferredName").text

      synonyms = ann.xpath("concept/synonyms/synonym")
      parsed[:synonyms] = synonyms.map do |synonym|
        synonym.xpath("string").text
      end

      semanticTypeBeans = ann.xpath("concept/semanticTypes/semanticTypeBean")
      parsed[:semanticTypes] = semanticTypeBeans.map do |semanticType|
        {
          :id           => semanticType.xpath("id").text.to_i,
          :semanticType => semanticType.xpath("semanticType").text,
          :description  => semanticType.xpath("description").text
        }
      end
      annotations << parsed
    end

    doc.xpath("//ontologyUsedBean").each do |ontology|
      parsed = {}
      parsed[:localOntologyId]   = ontology.xpath("localOntologyId").text.to_i
      parsed[:virtualOntologyId] = ontology.xpath("virtualOntologyId").text.to_i
      parsed[:name]              = ontology.xpath("name").text
      ontologies << parsed
    end

    {
      :statistics  => statistics,
      :annotations => annotations,
      :ontologies  => ontologies
    }
  end
end
