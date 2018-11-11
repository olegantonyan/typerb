# frozen_string_literal: true

require 'typerb/version'

module Typerb
  refine Object do
    def type!(*klasses) # rubocop: disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength NOTE: temporary
      raise ArgumentError, 'provide at least one class' if klasses.empty?
      return if klasses.any? { |kls| is_a?(kls) }

      kls_text = klasses.size > 1 ? klasses.map(&:name).join(' or ') : klasses.first.name

      # error message when multiple calls on the same line, or in a console - can't extract variable name
      exception_text = "expected #{kls_text}, got #{self.class} (#{self})"

      where = caller_locations(1, 1)[0]
      file = where.path
      line = where.lineno
      if File.exist?(file)
        code = File.read(file).lines[line - 1].strip
        node = RubyVM::AST.parse(code)
        if node.children.last.children.size == 3 && node.children.last.children[1] == :type!
          var_name = node.children.last.children.first.children.first
          exception_text = "`#{var_name}` should be #{kls_text}, not #{self.class} (#{self})"
        end
      end
      exception = TypeError.new(exception_text)
      exception.set_backtrace(caller)
      raise exception
    end
  end
end
