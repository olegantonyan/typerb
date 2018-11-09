# frozen_string_literal: true

require 'typerb/version'

module Typerb
  refine Object do
    def type!(*klasses)
      raise ArgumentError, 'provide at least one class' if klasses.empty?
      return if klasses.any? { |kls| is_a?(kls) }

      kls_text = klasses.size > 1 ? klasses.map(&:name).join(' or ') : klasses.first.name

      where = caller_locations(1, 1)[0]
      file = where.path
      line = where.lineno
      if File.exist?(file)
        code = File.read(file).lines[line - 1].strip
        node = RubyVM::AST.parse(code)
        var_name = node.children.last.children.first.children.first
        exception_text = "`#{var_name}` should be #{kls_text}, not #{self.class}"
      else # probably in console
        exception_text = "expected #{kls_text}, got #{self.class}"
      end
      exception = TypeError.new(exception_text)
      exception.set_backtrace(caller)
      raise exception
    end

    def should_respond_to!(*methods)
      raise ArgumentError, 'provide at least one method' if methods.empty?
      return if methods.all? { |meth| respond_to?(meth) }

      exception_text = "#{self.class} should respond to all methods: " + methods.join(', ')
      exception = TypeError.new(exception_text)
      exception.set_backtrace(caller)
      raise exception
    end

  end
end
