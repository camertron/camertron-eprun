# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

require "eprun/version"
require "eprun/ucd_version"
require "eprun/normalizer"

module Eprun
  autoload :V18_0_0, "eprun/v18_0_0"
  autoload :V17_0_0, "eprun/v17_0_0"
  autoload :V16_0_0, "eprun/v16_0_0"
  autoload :V15_1_0, "eprun/v15_1_0"
  autoload :V14_0_0, "eprun/v14_0_0"

  class << self
    def current_version
      Thread.current[:__eprun_current_version__]
    end

    def current_version=(new_version)
      Thread.current[:__eprun_current_version__] = Eprun::UcdVersion.get(new_version)
    end

    def normalize(*args)
      normalizer.normalize(*args)
    end

    def normalized?(*args)
      normalizer.normalized?(*args)
    end

    def normalizer
      ::Eprun::Normalizer.get(current_version)
    end

    def with_version(temp_version)
      old_version = current_version
      self.current_version = temp_version
      yield
    ensure
      self.current_version = old_version
    end
  end

  Eprun.current_version = Eprun::UcdVersion.latest
end
