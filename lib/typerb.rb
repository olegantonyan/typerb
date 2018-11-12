# frozen_string_literal: true

require 'typerb/version'

module Typerb
  refine Object do
    def type!(*klasses)
      raise ArgumentError, 'provide at least one class' if klasses.empty?
      return self if klasses.any? { |kls| is_a?(kls) }

      exception_text = if (var_name = VariableNameUtil.get(caller_locations(1, 1)))
                         "`#{var_name}` should be #{VariableNameUtil.klasses_text(klasses)}, not #{self.class} (#{self})"
                       else
                         "expected #{VariableNameUtil.klasses_text(klasses)}, got #{self.class} (#{self})"
                       end

      exception = TypeError.new(exception_text)
      exception.set_backtrace(caller)
      raise exception
    end

    def not_nil!
      return self unless self.nil? # rubocop: disable Style/RedundantSelf

      exception_text = if (var_name = VariableNameUtil.get(caller_locations(1, 1)))
                         "`#{var_name}` should not be nil"
                       else
                         'expected not nil, but got nil'
                       end

      exception = TypeError.new(exception_text)
      exception.set_backtrace(caller)
      raise exception
    end
  end

  module VariableNameUtil
    module_function

    def get(c_loc) # rubocop: disable Metrics/AbcSize screw this
      where = c_loc[0]
      file = where.path
      line = where.lineno
      return unless File.exist?(file)

      code = File.read(file).lines[line - 1].strip
      node = RubyVM::AST.parse(code)
      if node.children.last.children.size == 3 && %i[type! not_nil!].include?(node.children.last.children[1]) # rubocop: disable Style/IfUnlessModifier, Style/GuardClause
        node.children.last.children.first.children.first
      end
    end

    def klasses_text(klasses)
      klasses.size > 1 ? klasses.map(&:name).join(' or ') : klasses.first.name
    end
  end
end
