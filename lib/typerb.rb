# frozen_string_literal: true

require 'typerb/version'
require 'typerb/exceptional'

module Typerb
  refine BasicObject do
    def type!(*klasses)
      raise ArgumentError, 'provide at least one class' if klasses.empty?
      return self if klasses.any? { |kls| is_a?(kls) }

      klasses_text = klasses.join(' or ')
      Typerb::Exceptional.raise_type_error(caller, caller_locations(1, 1)[0], :type!) do |var_name|
        var_name ? "`#{var_name}` should be #{klasses_text}, not #{self.class} (#{self})" : "expected #{klasses_text}, got #{self.class} (#{self})"
      end
    end

    def not_nil!
      return self unless self.nil? # rubocop: disable Style/RedundantSelf

      Typerb::Exceptional.raise_type_error(caller, caller_locations(1, 1)[0], :not_nil!) do |var_name|
        var_name ? "`#{var_name}` should not be nil" : 'expected not nil, got nil'
      end
    end

    def respond_to!(*methods)
      raise ArgumentError, 'provide at least one method' if methods.empty?
      return self if methods.all? { |meth| respond_to?(meth) }

      methods_text = methods.join(', ')
      Typerb::Exceptional.raise_type_error(caller, caller_locations(1, 1)[0], :respond_to!) do |var_name|
        var_name ? "#{self.class} (`#{var_name}`) should respond to all methods: #{methods_text}" : "#{self.class} should respond to all methods: #{methods_text}"
      end
    end

    def enum!(*elements)
      raise ArgumentError, 'provide at least one enum element' if elements.empty?
      return self if elements.include?(self)

      elements_text = "[#{elements.join(', ')}]"
      Typerb::Exceptional.raise_type_error(caller, caller_locations(1, 1)[0], :enum!) do |var_name|
        var_name ? "#{self.class} (`#{var_name}`) should be one of: #{elements_text}, not #{self}" : "#{self.class} expected one of: #{elements_text}, got #{self}"
      end
    end

    def subset_of!(superset)
      raise ArgumentError, 'receiver must be Enumerable' unless is_a?(Enumerable)
      raise ArgumentError, 'superset must be Enumerable' unless superset.is_a?(Enumerable)

      elements = superset.to_a
      raise ArgumentError, 'provide at least one superset element' if elements.empty?
      return self if (to_a - elements).empty?

      Typerb::Exceptional.raise_type_error(caller, caller_locations(1, 1)[0], :subset_of!) do |var_name|
        var_name ? "#{self.class} (`#{var_name}`) should be subset of: #{superset}, not #{self}" : "#{self.class} expected subset of: #{superset}, got #{self}"
      end
    end
  end
end
