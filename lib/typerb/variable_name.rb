# frozen_string_literal: true

require 'typerb/prism_parser'
require 'typerb/ruby_vm_parser'

module Typerb
  class VariableName
    BACKENDS = [PrismParser, RubyVmParser].freeze

    attr_reader :file, :line, :method_name

    def initialize(location, method_name)
      @file = location&.path
      @line = location&.lineno
      @method_name = method_name
    end

    def get
      return unless backend
      return unless file && line && File.exist?(file)

      receivers = backend.receiver_sources(file, line, method_name)
      receivers.first if receivers.size == 1
    rescue StandardError, ScriptError
      nil
    end

    private

    def backend
      BACKENDS.find(&:available?)
    end
  end
end
