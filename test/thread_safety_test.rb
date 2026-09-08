# frozen_string_literal: true

require 'test_helper'

using Typerb

class ThreadSafetyTest < Minitest::Test
  def test_resolves_names_correctly_from_many_threads
    messages = Array.new(8) do
      Thread.new do
        threaded = 'x'
        begin
          threaded.type!(Integer)
        rescue TypeError => e
          e.message
        end
      end
    end.map(&:value)

    assert_equal ['`threaded` should be Integer, not String (x)'] * 8, messages
  end
end
