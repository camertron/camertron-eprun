# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

ROOT_DIR = Pathname.new(__dir__)
$:.push(ROOT_DIR.to_s)

require "eprun"
require "rubygems/package_task"

task :default => :test
Bundler::GemHelper.install_tasks

task :test do
  require "test/unit"

  files = Dir.glob("./test/test_*.rb")
  runner = Test::Unit::AutoRunner.new(true)
  runner.process_args(files)
  succeeded = runner.run
  exit(succeeded ? 0 : 1)
end

task :update_data do
  require "open-uri"
  require "fileutils"

  files = ["UnicodeData.txt", "NormalizationTest.txt", "CompositionExclusions.txt"]

  Eprun::UCD_VERSIONS.each do |ucd_version_string|
    base_url = "https://www.unicode.org/Public/#{ucd_version_string}/ucd"
    ucd_version = Eprun::UcdVersion.get(ucd_version_string)

    files.each do |file|
      url = "#{base_url}/#{file}"
      FileUtils.mkdir_p(ucd_version.data_path)
      File.write(File.join(ucd_version.data_path, file), URI.open(url).read)
    end
  end
end

task :generate_tables do
  require "tasks/tables_generator"

  Eprun::UCD_VERSIONS.each do |ucd_version_string|
    ucd_version = Eprun::UcdVersion.get(ucd_version_string)
    generator = EprunTasks::TablesGenerator.new(
      ROOT_DIR.join("data").to_s,
      ROOT_DIR.join("lib", "eprun").to_s,
      ucd_version,
    )

    generator.generate
  end
end

task :benchmark do
  require "benchmark/ips"

  deutsch = File.read(File.join(ROOT_DIR, "benchmark", "Deutsch.txt"))
  japanese = File.read(File.join(ROOT_DIR, "benchmark", "Japanese.txt"))

  Benchmark.ips do |x|
    x.report("eprun Deutsch") { Eprun.normalize(deutsch, :nfc) }
    x.report("ruby Deutsch")  { deutsch.unicode_normalize(:nfc) }
    x.compare!
  end

  puts

  Benchmark.ips do |x|
    x.report("eprun Japanese") { Eprun.normalize(japanese, :nfc) }
    x.report("ruby Japanese")  { japanese.unicode_normalize(:nfc) }
    x.compare!
  end
end
