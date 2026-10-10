# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

require "test/unit"
require "eprun"

class TestVersions < Test::Unit::TestCase
  def test_current_version_type
    assert_equal Eprun.current_version.class, Eprun::UcdVersion
  end

  def test_current_version_is_latest_by_default
    assert_equal Eprun.current_version.bare_string, Eprun::UCD_VERSIONS.first
  end

  def test_validates_current_version
    error = assert_raise ArgumentError do
      Eprun.current_version = "foo"
    end

    assert_equal error.message, "\"foo\" is not a valid UCD version"
  end

  def test_validates_current_version_number
    error = assert_raise ArgumentError do
      Eprun.current_version = "1.2.3"
    end

    assert_equal error.message, "Version \"1.2.3\" is unsupported; please provide a version from `Eprun::UCD_VERSIONS`"
  end

  def test_normalize
    assert_equal Eprun.normalize("abc"), "abc"
  end

  def test_normalized
    assert Eprun.normalized?("abc")
  end

  def test_normalizer_type
    assert_equal Eprun.normalizer.class, Eprun::Normalizer
  end

  def test_normalizer_contains_current_version
    version_string = Eprun::UCD_VERSIONS[1]

    Eprun.with_version(version_string) do
      assert_equal Eprun.normalizer.version.bare_string, version_string
    end
  end

  def test_with_version
    assert_equal Eprun.current_version.bare_string, Eprun::UCD_VERSIONS.first
    version_string = Eprun::UCD_VERSIONS[1]

    Eprun.with_version(version_string) do
      assert_equal Eprun.current_version.bare_string, version_string
    end

    assert_equal Eprun.current_version.bare_string, Eprun::UCD_VERSIONS.first
  end
end
