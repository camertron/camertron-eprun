# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

require "fileutils"
require "tasks/erb_template"

module EprunTasks
  class TablesGenerator
    attr_reader :data_dir, :output_dir, :ucd_version

    def initialize(data_dir, output_dir, ucd_version)
      @output_dir = output_dir
      @ucd_version = ucd_version
    end

    UnicodeData = Struct.new(
      :decomposition_table,
      :kompatible_table,
      :combining_classes,
    )

    def get_composition_exclusions
      IO.readlines(ucd_version.composition_exclusions_path)
        .select { |line| line =~ /^[A-Z0-9]{4,5}/ }
        .map { |line| line.split(" ").first.hex }
    end

    def get_unicode_data
      decomposition_table = {}
      kompatible_table = {}
      combining_classes = {}

      IO.foreach(ucd_version.unicode_data_path) do |line|
        codepoint, name, _, char_class, _, decomposition, *_rest = line.split(";")

        case decomposition
          when /^[0-9A-F]/
            decomposition_table[codepoint.hex] = decomposition.split(" ").collect(&:hex)
          when /^</
            kompatible_table[codepoint.hex] = decomposition.split(" ").drop(1).collect(&:hex)
        end

        combining_classes[codepoint.hex] = char_class.to_i if char_class != "0"

        if name =~ /(First|Last)>$/ && (char_class != "0" || decomposition != "")
          warn "Unexpected: Character range with data relevant to normalization!"
        end
      end

      UnicodeData.new(decomposition_table, kompatible_table, combining_classes)
    end

    def get_composition_table(unicode_data, composition_exclusions)
      # calculate compositions from decompositions
      unicode_data.decomposition_table.reject do |character, decomposition|
        composition_exclusions.member?(character) ||           # predefined composition exclusion
          decomposition.length <= 1 ||                         # Singleton Decomposition
          unicode_data.combining_classes[character] ||         # character is not a Starter
          unicode_data.combining_classes[decomposition.first]  # decomposition begins with a character that is not a Starter
      end.invert
    end

    def hangul_no_trailing
      @hangul_no_trailing ||= 0xAC00.step(0xD7A3, 28).to_a
    end

    def generate
      unicode_data = get_unicode_data
      decomposition_table = unicode_data.decomposition_table
      combining_classes = unicode_data.combining_classes
      composition_exclusions = get_composition_exclusions
      kompatible_table = unicode_data.kompatible_table

      # calculate compositions from decompositions
      composition_table = get_composition_table(unicode_data, composition_exclusions)

      # recalculate composition_exclusions
      composition_exclusions = decomposition_table.keys - composition_table.values

      accent_array = combining_classes.keys + composition_table.keys.collect(&:last)

      composition_starters = composition_table.keys.collect(&:first)

      # Special treatment for Unicode 16.0.0
      # Add characters that can be decomposed (even indirectly) so that
      # the first character in the decomposition is a an accent to accents.
      # We do this here up to two levels deep.
      # In the future, there may be even deeper levels.
      starter_accents = composition_starters & accent_array
      decomposition_table.each do |k, v|
        accent_array << k if starter_accents.include? v.first
        accent_array << k if starter_accents.include? decomposition_table[v.first]&.first
      end

      # expand decomposition table values
      decomposition_table.each do |key, value|
        position = 0
        while position < value.length
          if decomposition = decomposition_table[value[position]]
            decomposition_table[key] = value = value.dup # avoid overwriting composition_table key
            value[position, 1] = decomposition
          else
            position += 1
          end
        end
      end

      # deal with relationship between canonical and kompatibility decompositions
      decomposition_table.each do |key, value|
        value = value.dup
        expanded = false
        position = 0

        while position < value.length
          if decomposition = kompatible_table[value[position]]
            value[position, 1] = decomposition
            expanded = true
          else
            position += 1
          end
        end

        kompatible_table[key] = value if expanded
      end

      loop do
        break unless kompatible_table.any? do |key, value|
          expanded = value.map { |v| kompatible_table[v] || v }.flatten
          kompatible_table[key] = expanded unless value == expanded
        end
      end

      attrs = {
        ucd_version: ucd_version,
        accent_array: accent_array,
        composition_table: composition_table,
        decomposition_table: decomposition_table,
        kompatible_table: kompatible_table,
        composition_exclusions: composition_exclusions,
        composition_starters: composition_starters,
        hangul_no_trailing: hangul_no_trailing,
        combining_classes: combining_classes,
      }

      write_template(attrs)
      write_manifest(attrs)
    end

    def write_template(attrs)
      template = ErbTemplate.new(File.read(template_file), attrs)
      FileUtils.mkdir_p(File.dirname(output_file))

      File.open(output_file, "w+") do |f|
        f.write(template.render)
      end
    end

    def write_manifest(attrs)
      output_file = File.join(output_dir, "#{ucd_version.path_string}.rb")
      File.write(output_file, <<~RUBY)
        # encoding: utf-8

        # Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
        # available under the same licence as Ruby itself
        # (see http://www.ruby-lang.org/en/LICENSE.txt)

        module Eprun
          module #{attrs[:ucd_version].module_string}
            autoload :Tables, "eprun/#{ucd_version.path_string}/tables"
          end
        end
      RUBY
    end

    def output_file
      @output_file ||= File.join(output_dir, ucd_version.path_string, "tables.rb")
    end

    def template_file
      @template_file ||= File.join(File.dirname(__FILE__), "tables.rb.erb")
    end
  end
end
