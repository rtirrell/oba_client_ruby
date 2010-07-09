require "rubygems"
require "nokogiri"
require "cgi"
require "net/http"
require "uri"

##
# A class for interacting with the Open Biomedical Annotator. There are two
# things we do: get text, and parse it. We can do both independently or 
# serially.
class OBAClient
  VERSION = "2.0.2"

  ##
  # A high HTTP read timeout, as the service sometimes takes awhile to respond.
  DEFAULT_TIMEOUT = 30

  ##
  # The endpoint URI for the production version of the Annotator service.
  DEFAULT_URI = "http://rest.bioontology.org/obs/annotator"

  ##
  # The header for every request. There's no need to specify this per-instance.
  HEADER = {"Content-Type" => "application/x-www-form-urlencoded"}

  ##
  # Parameters the annotator accepts. Any one not in this list (excluding
  # textToAnnotate) is not valid.
  ANNOTATOR_PARAMETERS = [
    :email,
    :filterNumber,
    :format,
    :isStopWordsCaseSensitive,
    :isVirtualOntologyID,
    :levelMax,
    :longestOnly,
    :ontologiesToExpand,
    :ontologiesToKeepInResult,
    :mappingTypes,
    :minTermSize,
    :scored,
    :semanticTypes,
    :stopWords,
    :wholeWordOnly,
    :withDefaultStopWords,
    :withSynonyms,
  ]

  ##
  # Instantiate the class with a set of reused options. Options used by the
  # method are:
  #
  #   * [String] uri: the URI of the annotator service (default: {DEFAULT_URI}).
  #   * [Fixnum] timeout: the length of the read timeout (default: {DEFAULT_TIMEOUT}).
  #   * [Boolean] parse_xml: whether to parse the received text (default: false).
  #   * [Array<String>] ontologies: a pseudo-parameter which will set both
  #      ontologiesToExpand and ontologiesToKeepInResult.
  # @param [Hash<String, String>] options Parameters for the annotation.
  def initialize(options = {})
    @uri         = URI.parse(options.delete(:uri) || DEFAULT_URI)
    @timeout     = options.delete(:timeout)       || DEFAULT_TIMEOUT
    @parse_xml   = options.delete(:parse_xml)

    if ontologies = options.delete(:ontologies)
      [:ontologiesToExpand, :ontologiesToKeepInResult].each do |k|
        if options.include?(k)
          puts "WARNING: specified both :ontologies and #{k}, ignoring #{k}."
        end
        options[k] = ontologies
      end
    end

    @options = {}
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
      puts "TIP: as a courtesy, consider including your email in the request (:email => 'a@b.com')"
    end
  end

  ##
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
    puts request.body if $DEBUG

    begin
      response = Net::HTTP.new(@uri.host, @uri.port).start do |http|
        http.read_timeout = @timeout
        http.request(request)
      end
      @parse_xml ? self.class.parse(response.body) : response.body
    rescue Timeout::Error
      puts "Request for #{text[0..10]}... timed-out at #{@timeout} seconds."
    end
  end

  
  STATISTICS_BEANS_XPATH = "/success/data/annotatorResultBean/statistics/statisticsBean"
  ANNOTATION_BEANS_XPATH = "/success/data/annotatorResultBean/annotations/annotationBean"
  ONTOLOGY_BEANS_XPATH   = "/success/data/annotatorResultBean/ontologies/ontologyUsedBean"

  ##
  # Attributes for mapping concepts (annotation concepts add one additional
  # attribute. See also {ANNOTATION_CONCEPT_ATTRIBUTES}.
  CONCEPT_ATTRIBUTES = {
    :id              => lambda {|c| c.xpath("id").text.to_i},
    :localConceptId  => lambda {|c| c.xpath("localConceptId").text},
    :localOntologyId => lambda {|c| c.xpath("localOntologyId").text.to_i},
    :isTopLevel      => lambda {|c| to_b(c.xpath("isTopLevel").text)},
    :fullId          => lambda {|c| c.xpath("fullId").text},
    :preferredName   => lambda {|c| c.xpath("preferredName").text},

    :synonyms        => lambda do |c| 
      c.xpath("synonyms/synonym").map do |s|
        s.xpath("string").text
      end
    end,

    :semanticTypes   => lambda do |c| 
      c.xpath("semanticTypes/semanticTypeBean").map do |s|
        {
          :id           => s.xpath("id").text.to_i,
          :semanticType => s.xpath("semanticType").text,
          :description  => s.xpath("description").text
        }
      end
    end
  }
  

  ##
  # Toplevel attributes for mapping and mgrep contexts (both will add 
  # additional attributes).
  CONTEXT_ATTRIBUTES = {
    :contextName     => lambda {|c| c.xpath("contextName").text},
    :isDirect        => lambda {|c| to_b(c.xpath("isDirect").text)},
    :from            => lambda {|c| c.xpath("from").text.to_i},
    :to              => lambda {|c| c.xpath("to").text.to_i},
  }
  
  ##
  #  Toplevel attributes for annotation contexts.
  ANNOTATION_CONTEXT_ATTRIBUTES = {
    :score   => lambda {|c| c.xpath("score").text.to_i},
    :concept => lambda {|c| parse_concept(c.xpath("concept").first)},
    :context => lambda {|c| parse_context(c.xpath("context").first)}
  }

  ##
  # Toplevel attributes for mapping contexts.
  MAPPED_CONTEXT_ATTRIBUTES = CONTEXT_ATTRIBUTES.merge(
    :mappingType => lambda {|c| c.xpath("mappingType").text},
    :mappedConcept => lambda {|c| parse_concept(c.xpath("mappedConcept").first)}
  )

  ##
  # Toplevel attributes for mgrep contexts.
  MGREP_CONTEXT_ATTRIBUTES = CONTEXT_ATTRIBUTES.merge(
    :name           => lambda {|c| c.xpath("term/name").text},
    :localConceptId => lambda {|c| c.xpath("term/localConceptId").text},
    :isPreferred    => lambda {|c| to_b(c.xpath("term/isPreferred").text)},
    :dictionaryId   => lambda {|c| c.xpath("term/dictionaryId").text}
  )

  CONTEXT_CLASSES = {
    "annotationContextBean"  => ANNOTATION_CONTEXT_ATTRIBUTES,
    "mgrepContextBean"       => MGREP_CONTEXT_ATTRIBUTES,
    "mappingContextBean"     => MAPPED_CONTEXT_ATTRIBUTES,
  }

  ##
  # Parse a context - an annotation, or a mapping/mgrep context bean.
  # @param [Nokgiri::XML::Node] context The root node of the context.
  # @return Hash<Symbol, Object> The parsed context.
  def self.parse_context(context)
    # Annotations (annotationBeans) do not have a class, so we'll refer to them
    # as annotationContextBeans. context_class will be one of the types in
    # {CONTEXT_CLASSES}.
    context_class = if context.attribute("class").nil?
      "annotationContextBean"
    else
      context.attribute("class").value
    end

    Hash[CONTEXT_CLASSES[context_class].map do |k, v|
      [k, v.call(context)]
    end]
  end

  ##
  # Parse a concept - a toplevel annotation concept, or an annotation's
  # mapping concept.
  # @param [Nokogiri::XML::Node] concept The root node of the concept.
  # @return [Hash<Symbol, Object>] The parsed concept.
  def self.parse_concept(concept)
    Hash[CONCEPT_ATTRIBUTES.map do |k, v| 
      [k, v.call(concept)]
    end]
  end

  ##
  # Parse raw XML, returning a Hash with three elements: statistics,
  # annotations, and ontologies. Respectively, these represent the annotation
  # statistics (annotations by mapping type, etc., as a Hash), an Array of
  # each annotation (as a Hash), and an Array of ontologies used (also as
  # a Hash).
  # @param [String] xml The XMl we'll be parsing.
  # @return [Hash<Symbol, Object>] A Hash representation of the XML, as
  #   described above.
  def self.parse(xml)
    puts "WARNING: text is empty!" if (xml.gsub(/\n/, "") == "")
    doc = Nokogiri::XML.parse(xml)

    statistics = Hash[doc.xpath(STATISTICS_BEANS_XPATH).map do |sb|
      [sb.xpath("mapping").text, sb.xpath("nbAnnotation").text.to_i]
    end]

    annotations = doc.xpath(ANNOTATION_BEANS_XPATH).map do |annotation|
      parse_context(annotation)
    end

    ontologies = doc.xpath(ONTOLOGY_BEANS_XPATH).map do |ontology|
      {
        :localOntologyId   => ontology.xpath("localOntologyId").text.to_i,
        :virtualOntologyId => ontology.xpath("virtualOntologyId").text.to_i,
        :name              => ontology.xpath("name").text,
        :version           => ontology.xpath("version").text.to_f,
        :nbAnnotation      => ontology.xpath("nbAnnotation").text.to_i
      }
    end

    {
      :statistics  => statistics,
      :annotations => annotations,
      :ontologies  => ontologies
    }
  end
  
  ##
  # A little helper: convert a string true/false or 1/0 value to boolean.
  # AFAIK, there's no better way to do this.
  # @param [String] value The value to convert.
  # @return [true, false]
  def self.to_b(value)
    case value
    when "0"     then false
    when "1"     then true
    when "false" then false
    when "true"  then true
    end
  end
end
