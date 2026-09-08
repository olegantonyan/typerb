# frozen_string_literal: true

require 'typerb/source_cache'

module Typerb
  module RubyVmParser
    CALL_TYPES = %i[CALL QCALL].freeze
    RECEIVER_TYPES = %i[LVAR DVAR IVAR CVAR GVAR CONST COLON2 COLON3 CALL QCALL VCALL FCALL OPCALL ITER].freeze

    class << self
      def available?
        defined?(::RubyVM::AbstractSyntaxTree) && ::RubyVM::AbstractSyntaxTree.respond_to?(:parse_file)
      end

      def receiver_sources(file, line, method_name)
        calls(root(file), line, method_name).map { |node| receiver_source(file, node) }
      end

      private

      def root(file)
        SourceCache.read(file, :ruby_vm) { ::RubyVM::AbstractSyntaxTree.parse_file(file) }
      end

      def calls(root, line, method_name)
        found = []
        stack = [root]
        until stack.empty?
          node = stack.pop
          found << node if call?(node, line, method_name)
          stack.concat(node.children.grep(::RubyVM::AbstractSyntaxTree::Node))
        end
        found
      end

      def call?(node, line, method_name)
        CALL_TYPES.include?(node.type) &&
          node.children[1] == method_name &&
          (node.first_lineno..node.last_lineno).cover?(line)
      end

      def receiver_source(file, node)
        receiver = node.children.first
        return nil unless receiver.is_a?(::RubyVM::AbstractSyntaxTree::Node)
        return nil unless RECEIVER_TYPES.include?(receiver.type)
        return nil unless receiver.first_lineno == receiver.last_lineno

        line = lines(file)[receiver.first_lineno - 1]
        line&.byteslice(receiver.first_column...receiver.last_column) # AST columns are byte offsets
      end

      def lines(file)
        SourceCache.read(file, :lines) { File.readlines(file) }
      end
    end
  end
end
