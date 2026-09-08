# frozen_string_literal: true

begin
  require 'prism'
rescue LoadError # rubocop: disable Lint/SuppressedException
end

require 'typerb/source_cache'

module Typerb
  module PrismParser
    RECEIVER_NODE_NAMES = %w[
      LocalVariableReadNode
      InstanceVariableReadNode
      ClassVariableReadNode
      GlobalVariableReadNode
      ConstantReadNode
      ConstantPathNode
      CallNode
    ].freeze

    class << self
      def available?
        defined?(::Prism) && ::Prism.respond_to?(:parse_file)
      end

      def receiver_sources(file, line, method_name)
        calls(root(file), line, method_name).map { |node| receiver_source(node) }
      end

      private

      def root(file)
        SourceCache.read(file, :prism) { ::Prism.parse_file(file).value }
      end

      def calls(root, line, method_name)
        found = []
        stack = [root]
        until stack.empty?
          node = stack.pop
          found << node if call?(node, line, method_name)
          stack.concat(node.compact_child_nodes)
        end
        found
      end

      def call?(node, line, method_name)
        node.is_a?(::Prism::CallNode) &&
          node.name.to_sym == method_name &&
          node.message_loc&.start_line == line
      end

      def receiver_source(node)
        receiver = node.receiver
        return nil unless receiver_nodes.any? { |kls| receiver.is_a?(kls) }

        receiver.slice
      end

      def receiver_nodes
        @receiver_nodes ||= RECEIVER_NODE_NAMES.select { |name| ::Prism.const_defined?(name) }
                                               .map { |name| ::Prism.const_get(name) }
      end
    end
  end
end
