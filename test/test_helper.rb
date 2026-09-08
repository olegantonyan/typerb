# frozen_string_literal: true

require 'minitest/autorun'
require 'typerb'

module BackendStub
  def without_backends(*parsers)
    originals = parsers.to_h { |parser| [parser, parser.method(:available?)] }
    originals.each_key { |parser| silently { parser.define_singleton_method(:available?) { false } } }
    yield
  ensure
    originals.each { |parser, original| silently { parser.define_singleton_method(:available?, original) } }
  end

  private

  def silently
    verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = verbose
  end
end
