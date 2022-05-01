# frozen_string_literal: true

require 'logging'

require 'logcraft/version'
require 'logcraft/railtie'

module Logcraft
  autoload :LogLayout, 'logcraft/log_layout'

  def self.logger(name)
    Logging::Logger[name]
  end
end
