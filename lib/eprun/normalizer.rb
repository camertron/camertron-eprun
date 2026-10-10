# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

module Eprun
  class Normalizer
    ## Constant for max hash capacity to avoid DoS attack
    MAX_HASH_LENGTH = 18000 # enough for all test cases, otherwise tests get slow

    ## Constants For Hangul
    # for details such as the meaning of the identifiers below, please see
    # http://www.unicode.org/versions/Unicode7.0.0/ch03.pdf, pp. 144/145
    SBASE = 0xAC00
    LBASE = 0x1100
    VBASE = 0x1161
    TBASE = 0x11A7
    LCOUNT = 19
    VCOUNT = 21
    TCOUNT = 28
    NCOUNT = VCOUNT * TCOUNT
    SCOUNT = LCOUNT * NCOUNT

    # Unicode-based encodings (except UTF-8)
    UNICODE_ENCODINGS = [
      Encoding::UTF_16BE,
      Encoding::UTF_16LE,
      Encoding::UTF_32BE,
      Encoding::UTF_32LE,
      Encoding::GB18030,
      Encoding::UCS_2BE,
      Encoding::UCS_4BE
    ]

    class << self
      def get(version = Eprun.current_version)
        version = Eprun::UcdVersion.get(version)
        cache[version.string] ||= new(version)
      end

      private

      def cache
        @cache ||= {}
      end
    end

    attr_reader :version

    def initialize(version)
      @version = version

      tables = version.namespace::Tables

      @class_table = tables.class_table
      @composition_table = tables.composition_table
      @decomposition_table = tables.decomposition_table
      @kompatible_table = tables.kompatible_table

      ## Regular Expressions and Hash Constants
      @regexp_d = Regexp.compile(tables.regexp_d_string, Regexp::EXTENDED)
      @regexp_c = Regexp.compile(tables.regexp_c_string, Regexp::EXTENDED)
      @regexp_k = Regexp.compile(tables.regexp_k_string, Regexp::EXTENDED)
      @nf_hash_d = Hash.new do |hash, key|
        hash.shift if hash.length > MAX_HASH_LENGTH # prevent DoS attack
        hash[key] = nfd_one(key)
      end

      @nf_hash_c = Hash.new do |hash, key|
        hash.shift if hash.length > MAX_HASH_LENGTH # prevent DoS attack
        hash[key] = nfc_one(key)
      end
    end

    ## Hangul Algorithm
    def hangul_decomp_one(target)
      syllable_index = target.ord - SBASE
      return target if syllable_index < 0 || syllable_index >= SCOUNT

      l = LBASE + syllable_index / NCOUNT
      v = VBASE + (syllable_index % NCOUNT) / TCOUNT
      t = TBASE + syllable_index % TCOUNT
      (t == TBASE ? [l, v] : [l, v, t]).pack("U*") + target[1..-1]
    end

    def hangul_comp_one(string)
      length = string.length

      if length > 1 && 0 <= (lead = string[0].ord - LBASE) && lead < LCOUNT && 0 <= (vowel = string[1].ord - VBASE) && vowel < VCOUNT
        lead_vowel = SBASE + (lead * VCOUNT + vowel) * TCOUNT
        if length > 2 && 0 < (trail = string[2].ord - TBASE) && trail < TCOUNT
          (lead_vowel + trail).chr(Encoding::UTF_8) + string[3..-1]
        else
          lead_vowel.chr(Encoding::UTF_8) + string[2..-1]
        end
      else
        string
      end
    end

    ## Canonical Ordering
    def canonical_ordering_one(string)
      result = +""
      unordered = []
      chars = string.chars
      n = chars.size

      chars.each_with_index do |char, i|
        ccc = @class_table[char]

        if ccc == 0
          unordered.sort!.each { |elem| result << chars[elem % n] }
          unordered.clear
          result << char
        else
          unordered << ccc * n + i
        end
      end

      unordered.sort!.each { |elem| result << chars[elem % n] }
      result
    end

    ## Normalization Forms for Patterns (not whole Strings)
    def nfd_one(string)
      string = string.chars.map! { |c| @decomposition_table[c] || c }.join("")
      canonical_ordering_one(hangul_decomp_one(string))
    end

    def nfc_one(string)
      nfd_string = nfd_one(string)
      start = nfd_string[0]
      last_class = @class_table[start]-1
      accents = +""
      result = +""

      nfd_string[1..-1].each_char do |accent|
        accent_class = @class_table[accent]

        if last_class < accent_class && composite = @composition_table[start + accent]
          start = composite
        elsif accent_class == 0
          result << start << accents
          start = accent
          accents = ""
          last_class = -1
        else
          accents << accent
          last_class = accent_class
        end
      end

      hangul_comp_one(result + start + accents)
    end

    def normalize(string, form = :nfc)
      encoding = string.encoding

      case encoding
        when Encoding::UTF_8
          case form
          when :nfc
            string.gsub(@regexp_c, @nf_hash_c)
          when :nfd
            string.gsub(@regexp_d, @nf_hash_d)
          when :nfkc
            string.gsub(@regexp_k, @kompatible_table).gsub(@regexp_c, @nf_hash_c)
          when :nfkd
            string.gsub(@regexp_k, @kompatible_table).gsub(@regexp_d, @nf_hash_d)
          else
            raise ArgumentError, "Invalid normalization form #{form}."
          end
        when Encoding::US_ASCII
          string
        when *UNICODE_ENCODINGS
          normalize(string.encode(Encoding::UTF_8), form).encode(encoding)
        else
          raise Encoding::CompatibilityError, "Unicode Normalization not appropriate for #{encoding}"
      end
    end

    def normalized?(string, form = :nfc)
      encoding = string.encoding

      case encoding
        when Encoding::UTF_8
          case form
          when :nfc
            string.scan(@regexp_c) do |match|
              return false if @nf_hash_c[match] != match
            end
            true
          when :nfd
            string.scan(@regexp_d) do |match|
              return false if @nf_hash_d[match] != match
            end
            true
          when :nfkc
            normalized?(string, :nfc) && string !~ @regexp_k
          when :nfkd
            normalized?(string, :nfd) && string !~ @regexp_k
          else
            raise ArgumentError, "Invalid normalization form #{form}."
          end
        when Encoding::US_ASCII
          true
        when *UNICODE_ENCODINGS
          normalized?(string.encode(Encoding::UTF_8), form)
        else
          raise Encoding::CompatibilityError, "Unicode Normalization not appropriate for #{encoding}"
      end
    end
  end
end
