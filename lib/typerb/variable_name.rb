# frozen_string_literal: true

module Typerb
  class VariableName
    attr_reader :file, :line

    def initialize(caller_loc)
      @file = caller_loc[0].path
      @line = caller_loc[0].lineno
    end

    def get
      return if RUBY_VERSION < '2.6.0'
      return unless File.exist?(file)

      caller_method = caller_locations(1, 1)[0].label.to_sym
      from_ast(caller_method)
    end

    private

    def from_ast(caller_method) # rubocop: disable Metrics/AbcSize not worth fixing
      code = File.read(file).lines[line - 1].strip
      node = RubyVM::AbstractSyntaxTree.parse(code)
      if node.children.last.children.size == 3 && node.children.last.children[1] == caller_method # rubocop: disable Style/IfUnlessModifier, Style/GuardClause
        node.children.last.children.first.children.first
      end
    end
  end
end
