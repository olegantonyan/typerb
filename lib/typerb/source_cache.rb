# frozen_string_literal: true

module Typerb
  module SourceCache
    LIMIT = 32

    class << self
      def read(file, kind)
        stat = File.stat(file)
        key = [file, kind, stat.mtime, stat.size]
        mutex.synchronize do
          return store[key] if store.key?(key)

          store.shift while store.size >= LIMIT
          store[key] = yield
        end
      end

      private

      def store
        @store ||= {}
      end

      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
