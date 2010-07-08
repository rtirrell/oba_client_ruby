# oba-client

* http://rubyforge.org/projects/oba-client

## DESCRIPTION:

A client for accessing the NCBO's Open Biomedical Annotator service.
See [the Annotator documentation](http://www.bioontology.org/wiki/index.php/Annotator_User_Guide "Documentation") for much more information

## FEATURES:

* Many

## REQUIREMENTS:

* None

## INSTALL:

    sudo gem install oba-client
    gem install --user-install oba-client

## USAGE:
    
    client = OBAClient.new
    result = client.execute("some text string") # As XML.

    client2 = OBAClient.new({:parse_xml => true})
    # Returns {:statistics  => {information about the annotation},
    #          :annotations => [Array of annotations of text],
    #          :ontologies  => [Array of ontologies used]}
    client2.execute("another text string, maybe longer this time.")

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

