# frozen_string_literal: true

require 'typerb/variable_name'

module Typerb
  module Exceptional # NOTE: don't want to collide with 'Exception' class name
    def self.raise_type_error(backtrace, location, method_name)
      exception = TypeError.new(yield(VariableName.new(location, method_name).get))
      exception.set_backtrace(backtrace)
      raise exception
    end
  end
end
