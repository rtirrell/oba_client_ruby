require "test/unit"
require "oba_client"

TEST_TEXTS = [
  "Mexico,, Disease Thing \o\r\m\n\t\v\l\rzebrafish !!! cancer of the thorax.",
  %Q{LOROE aonuhaso unseu anoeuhs aeuhsaonuh asoneuhason uaosenuh aosenuhaose
  aoneuhasonuhaoenuh anoeuhasn euhasoneu haosneuhaosenuhaoesunahoeusnaoeuteeano
  aot tt t t t t t t tae \n!!@)$@(#)%@#!)@# asoeuaohsenutahoeusaheou
  }
]

class TestOBAClient < Test::Unit::TestCase
  def test_reuse_instance
    ann = OBAClient.new
    TEST_TEXTS.each do |text|
      xml = ann.execute(text)
      assert xml[0..4] == "<?xml"
    end
  end
  
  def test_reuse_instance_with_email
    ann = OBAClient.new :email => "r.tirrell@gmail.com"
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
      assert parsed[:statistics].is_a?(Hash)
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
      assert parsed[:ontologies].all? {|o| o[:localOntologyId] == 42812}
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
      assert parsed[:statistics].is_a?(Hash)
      assert parsed[:annotations].is_a?(Array)
      assert parsed[:ontologies].is_a?(Array)
    end
  end
end
