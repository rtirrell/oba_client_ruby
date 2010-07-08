require "test/unit"
require "oba_client"

TEST_TEXTS = [
   "hello I am a monkeyfish with a benign neoplastic....\t\n\\n",
  "zebrafish echo delta tango TURN <?xml MY VOLUME UP cancer of the thorax.",
  "zebrafish DROP TABLE !!! TURN MY VOLUME UP cancer of the thorax.",
  %Q{LOROE aonuhaso unseu anoeuhs aeuhsaonuh asoneuhason uaosenuh aosenuhaose
  aoneuhasonuhaoenuh anoeuhasn euhasoneu haosneuhaosenuhaoesunahoeusnaoeuteeano
  aot tt t t t t t t tae \n!!@)$@(#)%@#!)@# asoeuaohsenutahoeusaheou
  }
]

class TestOBAClient < Test::Unit::TestCase
  def test_reuse_annotator_instance
    ann = OBAClient.new
    TEST_TEXTS.each do |text|
      xml = ann.execute(text)
      assert xml[0..4] == "<?xml"
    end
  end
  
  def test_annotation_no_parameters
    TEST_TEXTS.each do |text|
      ann = OBAClient.new 
      xml = ann.execute(text)
      assert xml[0..4] == "<?xml"
    end
  end
  
  def test_annotation_parse
    TEST_TEXTS.each do |text|
      ann = OBAClient.new :parse_xml => true
      parsed = ann.execute(text)
      assert parsed[:statistics].is_a?(Array)
      assert parsed[:annotations].is_a?(Array)
      assert parsed[:ontologies].is_a?(Array)
    end
  end
  
  def test_annotation_keep_one_ontology
    TEST_TEXTS.each do |text|
      ann = OBAClient.new(
        :ontologiesToKeepInResult => [42812],
        :parse_xml => true
      )
      parsed = ann.execute(text)
      assert parsed[:statistics].is_a?(Array)
      assert parsed[:annotations].is_a?(Array)
      assert parsed[:ontologies].is_a?(Array)
    end
  end
  
  def test_annotation_invalid_parameters
    TEST_TEXTS.each do |text|
      ann = OBAClient.new(
        :ontologiesToKeepInResult => [42812],
        :parse_xml                => true,
        :blah_blah                => true,
        :hoho                     => ["merry", "christmas"]
      )
      parsed = ann.execute(text)
      assert parsed[:statistics].is_a?(Array)
      assert parsed[:annotations].is_a?(Array)
      assert parsed[:ontologies].is_a?(Array)
    end
  end
end
