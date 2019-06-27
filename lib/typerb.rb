# frozen_string_literal: true

require 'typerb/version'
require 'typerb/variable_name'
require 'typerb/exceptional'

module Typerb
  refine Object do
    def type!(*klasses)
      raise ArgumentError, 'provide at least one class' if klasses.empty?
      return self if klasses.any? { |kls| is_a?(kls) }

      klasses_text = Typerb::Exceptional.klasses_text(klasses)
      exception_text = if (var_name = Typerb::VariableName.new(caller_locations(1, 1)).get)
                         "`#{var_name}` should be #{klasses_text}, not #{self.class} (#{self})"
                       else
                         "expected #{klasses_text}, got #{self.class} (#{self})"
                       end

      Typerb::Exceptional.new.raise_with(caller, exception_text)
    end

    def not_nil!
      return self unless self.nil? # rubocop: disable Style/RedundantSelf rubocop breaks without reundant self

      exception_text = if (var_name = Typerb::VariableName.new(caller_locations(1, 1)).get)
                         "`#{var_name}` should not be nil"
                       else
                         'expected not nil, got nil'
                       end

      Typerb::Exceptional.new.raise_with(caller, exception_text)
    end

    def respond_to!(*methods)
      raise ArgumentError, 'provide at least one method' if methods.empty?
      return self if methods.all? { |meth| respond_to?(meth) }

      methods_text = Typerb::Exceptional.methods_text(methods)
      exception_text = if (var_name = Typerb::VariableName.new(caller_locations(1, 1)).get)
                         "#{self.class} (`#{var_name}`) should respond to all methods: #{methods_text}"
                       else
                         "#{self.class} should respond to all methods: #{methods_text}"
                       end

      Typerb::Exceptional.new.raise_with(caller, exception_text)
    end

    def enum!(*elements)
      raise ArgumentError, 'provide at least one enum element' if elements.empty?
      return self if elements.include?(self)

      elements_text = Typerb::Exceptional.elements_text(elements)
      exception_text = if (var_name = Typerb::VariableName.new(caller_locations(1, 1)).get)
                         "#{self.class} (`#{var_name}`) should be one of: #{elements_text}, not #{self}"
                       else
                         "#{self.class} expected one of: #{elements_text}, got #{self}"
                       end

      Typerb::Exceptional.new.raise_with(caller, exception_text)
    end
  end
end
