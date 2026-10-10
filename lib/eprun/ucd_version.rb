# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

module Eprun
  class UcdVersion
    class << self
      def get(str_or_version)
        return str_or_version if str_or_version.is_a?(self)

        m = str_or_version.match(/v?(\d+)\.(\d+)\.(\d+)/)
        raise(ArgumentError, "#{str_or_version.inspect} is not a valid UCD version") unless m

        parsed_version = m.captures.join(".")

        if !Eprun::UCD_VERSIONS.include?(parsed_version)
          raise ArgumentError, "Version #{parsed_version.inspect} is unsupported; please provide a version from `Eprun::UCD_VERSIONS`"
        end

        numbers = m.captures.map(&:to_i)
        cache[numbers] ||= new(*numbers)
      end

      def latest
        @latest ||= get(::Eprun::UCD_VERSIONS.first)
      end

      private

      def cache
        @cache ||= {}
      end
    end

    attr_reader :major, :minor, :patch

    def initialize(major, minor, patch)
      @major = major
      @minor = minor
      @patch = patch
    end

    def data_path
      @data_path ||= File.expand_path(File.join("..", "..", "data", path_string), __dir__)
    end

    def composition_exclusions_path
      @composition_exclusions_path ||= File.join(data_path, "CompositionExclusions.txt")
    end

    def normalization_test_path
      @normalization_test_path ||= File.join(data_path, "NormalizationTest.txt")
    end

    def unicode_data_path
      @unicode_data_path ||= File.join(data_path, "UnicodeData.txt")
    end

    def string
      @string ||= "v#{bare_string}"
    end

    def bare_string
      @bare_string ||= "#{major}.#{minor}.#{patch}"
    end

    def path_string
      @path_string ||= "v#{major}_#{minor}_#{patch}"
    end

    alias underscored_string path_string

    def module_string
      @module_string ||= "V#{major}_#{minor}_#{patch}"
    end

    def namespace
      @namespace ||= ::Eprun.const_get(module_string)
    end
  end
end
