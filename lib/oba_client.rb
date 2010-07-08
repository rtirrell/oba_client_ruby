class OBAClient
  VERSION = "1.0.0"
  # A high HTTP read timeout, as the service sometimes takes awhile to respond.
  DEFAULT_TIMEOUT = 30
  # The endpoint URI for the production version of the Annotator service.
  DEFAULT_URI = URI.parse("http://rest.bioontology.org/obs/annotator")

  # Annotate a blob of text. Method options are:
  # - [String]  uri: the URI of the annotator service.
  # - [Fixnum]  timeout: the length of the read timeout (default: DEFAULT_TIMEOUT).
  # - [Boolean] parse_xml: whether to parse the received text (default: false).
  # @param [Hash<String, String>] options Parameters for the annotation.
  def initialize(options = {})
    @uri         = URI.parse(options.delete(:uri) || DEFAULT_URI)
    @timeout     = options.delete(:timeout) || DEFAULT_TIMEOUT
    @parse_xml   = options.delete(:parse_xml) 
    @options     = options
  end

  # Perform the annotation.
  # @param [String] text The text to annotate.
  # @return [Hash<Symbol, Array>, String, nil] A Hash representing the parsed
  #   document, the raw XML if parsing is not requested, or nil if the
  #   request times out.
  def execute(text)
    request = Net::HTTP::Post.new(@uri.path)
    request.body = {:textToAnnotate => text}.merge(@options).map do |k, v|
      "#{CGI.escape(k)}=#{CGI.escape(v)}"
    end.join("&")

    begin
      response = Net::HTTP.new(@uri.host, @uri.port).start do |http|
        http.read_timeout = @timeout
        http.request(request)
      end
      @parse_xml ? parse(response.body) : response.body
    rescue Timeout::Error
      puts "Request for #{text[0..10]} timed-out at #{@timeout} seconds."
    end
  end
  
  # Parse the raw XML, returning a Hash with three elements: statistics,
  #   annotations, and ontologies. Respectively, these represent the annotation
  #   statistics (annotations by mapping type, etc., as a Hash), an Array of
  #   each annotation (as a Hash), and an Array of ontologies used (also as
  #   a Hash).
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

      synonyms = ann.xpath("concept/synonyms")
      parsed[:synonyms] = synonyms.children.map do |child|
        child.child.text
      end

      semanticTypes = ann.xpath("concept/semanticTypes")
      parsed[:semanticTypes] = semanticTypes.children.map do |child|
        {
         :id           => child.xpath("id").text.to_i,
         :semanticType => child.xpath("semanticType").text,
         :description  => child.xpath("description").text
        }
      end
      annotations << parsed
    end

    doc.xpath("//ontologyUsedBean").each do |ontology|
      parsed = {}
      parsed[:localOntologyId]   = node.xpath("localOntologyId").text,
      parsed[:virtualOntologyId] = node.xpath("virtualOntologyId").text
      parsed[:name]              = node.xpath("name").text
      ontologies << parsed
    end

    {
      :statistics  => statistics, 
      :annotations => annotations, 
      :ontologies  => ontologies
    }
  end
end
