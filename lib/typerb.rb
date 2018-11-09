require 'typerb/version'

module Typerb
  refine Object do
    def type!(*klasses)
      raise ArgumentError, 'provide at least one class' if klasses.size < 1

      unless klasses.any? { |kls| self.is_a?(kls) }
        where = caller_locations(1,1)[0]
        file = where.path
        line = where.lineno
        code = File.read(file).lines[line - 1].strip
        node = RubyVM::AST.parse(code)
        var_name = node.children.last.children.first.children.first

        kls_text = klasses.size > 1 ? "#{klasses.map(&:name).join(' or ')}" : klasses.first.name
        raise TypeError, "`#{var_name}` should be #{kls_text}, not #{self.class}"
      end
    end
  end
end
