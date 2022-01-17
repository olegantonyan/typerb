# frozen_string_literal: true

module Typerb
  class Exceptional # NOTE: don't want to collide with 'Exception' class name
    class << self
      def klasses_text(klasses)
        klasses.size > 1 ? klasses.map(&:name).join(' or ') : klasses.first.name
      end

      def methods_text(methods)
        methods.join(', ')
      end

      def elements_text(elements)
        '[' + elements.join(', ') + ']'
      end

      def superset_text(enumerable)
        enumerable.to_s
      end
    end

    def raise_with(backtrace, exception_text)
      exception = TypeError.new(exception_text)
      exception.set_backtrace(backtrace)
      raise exception
    end
  end
end
