# oba-client

* [GitHub](github.com/rtirrell/oba_client_ruby)

## DESCRIPTION:

A client for accessing the NCBO's Open Biomedical Annotator web service.
See [the Annotator documentation](http://www.bioontology.org/wiki/index.php/Annotator_User_Guide "Documentation") for much more information.

## FEATURES:

* Many

## REQUIREMENTS:

* None

## INSTALL:

    sudo gem install oba-client
    gem install --user-install oba-client

## USAGE:
    
    require "rubygems"
    require "oba-client"
    
    client = OBAClient.new
    # As XML.
    result = client.execute("some text string") 

    client2 = OBAClient.new({:parse_xml => true})
    # Returns {:statistics  => {information about the annotation},
    #          :annotations => [Array of annotations of text],
    #          :ontologies  => [Array of ontologies used]}
    # Like:
    :statistics => {"MAPPING" => 1951, "MGREP" => 2319, "ISA_CLOSURE" => 30}
    :annotations => [{
      :score           => 199,
      :id              => 203820,
      :localConceptId  => "42877/CARO:0000013",
      :localOntologyId => 42877,
      :isTopLevel      => true,
      :fullId          => "http://purl.obolibrary.org/obo/FBbt_00007002",
      :preferredName   => "cell",
      :synonyms        => ["body cell"],
      :definitions     => ["a cell", "some other definition"],
    	
      :semanticTypes => [
        {:id => 230820, :semanticType => "T043", :description => "desc"},
        "etc..."
      ]
    	
      :context => {
        :contextName   => "MAPPING",
        :isDirect      => false,
        :from          => 10,
        :to            => 20,
        :mappedConcept => {
          "has" => "the same information as other annotations, minus score"
        }
      }
    	
      :mappingType => "Automatic"
    }, "more annotations..."]
    	
    :ontologies => [{
      :localOntologyId   => 40404,
      :name              => "Ontology Name",
      :virtualOntologyId => 1042,
      :version           => 1.1,
      :nbAnnotation      => 40

    }, "more ontologies..."]
    	
    client2.execute("another text string, maybe longer this time.")
    client2.execute("this is the second query for this client!")
    
    # Or, parse some file you've already got lying about (pass as a string).
    parsed = OBAClient::parse("<?xml version='1.0'>...</xml>")

## LICENSE:
 
Copyright (c) 2010 Rob Tirrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

