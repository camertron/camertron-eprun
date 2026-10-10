# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

require "erb"

class ErbTemplate
  class Context
    attr_reader :attrs

    def initialize(attrs)
      @attrs = attrs
    end

    def render(template)
      ERB.new(template).result(binding)
    end

    private

    def to_utf8(obj)
      case obj
        when Array
          obj.map { |c| to_utf8(c) }.join('')
        else
          num = obj

          if num > 0xFFFF
            "\\u{#{num.to_s(16).upcase}}"
          elsif num > 0x7f
            "\\u#{num.to_s(16).upcase.rjust(4, '0')}"
          else
            num.chr.sub(/[\\\"]/, "\\\\\\\&")
          end
      end
    end

    # converts an array of Integers to character ranges
    def each_regexp_chars(arr, n = 1)
      arr.sort.inject([]) do |ranges, value|
        if ranges.last and ranges.last[1] + 1 >= value
          ranges.last[1] = value
          ranges
        else
          ranges << [value, value]
        end
      end.collect do |first, last|
        case last - first
        when 0
          to_utf8(first)
        when 1
          to_utf8(first) + to_utf8(last)
        else
          to_utf8(first) + '-' + to_utf8(last)
        end
      end.each_slice(n).map do |slice|
        yield slice.join('')
      end
    end
  end

  def initialize(template, attrs = {})
    @template = template
    @context = Context.new(attrs)
  end

  def render
    @context.render(@template)
  end
end
