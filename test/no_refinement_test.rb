# frozen_string_literal: true

require 'test_helper'

class NoRefinementTest < Minitest::Test
  def test_methods_are_not_available_without_using
    assert_raises(NameError) { 'hello'.type!(Integer) }
    assert_raises(NameError) { 'hello'.not_nil! }
  end
end
