# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

require "test/unit"
require "eprun"

class TestUcdVersion < Test::Unit::TestCase
  def test_get_accepts_string_version_as_argument
    ucd_version = Eprun::UcdVersion.get(Eprun::UCD_VERSIONS[1])
    assert_equal ucd_version.bare_string, Eprun::UCD_VERSIONS[1]
  end

  def test_get_accepts_ucd_version_as_argument
    ucd_version = Eprun::UcdVersion.get(Eprun::UCD_VERSIONS[1])
    ucd_version = Eprun::UcdVersion.get(ucd_version)
    assert_equal ucd_version.bare_string, Eprun::UCD_VERSIONS[1]
  end

  def test_latest
    assert_equal Eprun::UcdVersion.latest.bare_string, Eprun::UCD_VERSIONS[0]
  end

  def test_version_numbers
    ucd_version = Eprun::UcdVersion.get("18.0.0")
    assert_equal ucd_version.major, 18
    assert_equal ucd_version.minor, 0
    assert_equal ucd_version.patch, 0
  end

  def test_string
    ucd_version = Eprun::UcdVersion.get("18.0.0")
    assert_equal ucd_version.string, "v18.0.0"
  end

  def test_bare_string
    ucd_version = Eprun::UcdVersion.get("18.0.0")
    assert_equal ucd_version.bare_string, "18.0.0"
  end

  def test_path_string
    ucd_version = Eprun::UcdVersion.get("18.0.0")
    assert_equal ucd_version.path_string, "v18_0_0"
  end

  def test_module_string
    ucd_version = Eprun::UcdVersion.get("18.0.0")
    assert_equal ucd_version.module_string, "V18_0_0"
  end

  def test_namespace
    ucd_version = Eprun::UcdVersion.get("18.0.0")
    assert_equal ucd_version.namespace, Eprun::V18_0_0
  end
end
