# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

require "test/unit"
require "eprun"

class TestNormalizer < Test::Unit::TestCase
  def test_get_uses_current_version
    assert_equal Eprun::Normalizer.get.version.bare_string, Eprun.current_version.bare_string

    Eprun.with_version(Eprun::UCD_VERSIONS[1]) do
      assert_equal Eprun::Normalizer.get.version.bare_string, Eprun::UCD_VERSIONS[1]
    end
  end

  def test_get_accepts_string_version_as_argument
    normalizer = Eprun::Normalizer.get(Eprun::UCD_VERSIONS[1])
    assert_equal normalizer.version.bare_string, Eprun::UCD_VERSIONS[1]
  end

  def test_get_accepts_ucd_version_as_argument
    ucd_version = Eprun::UcdVersion.get(Eprun::UCD_VERSIONS[1])
    normalizer = Eprun::Normalizer.get(ucd_version)
    assert_equal normalizer.version.bare_string, Eprun::UCD_VERSIONS[1]
  end
end
