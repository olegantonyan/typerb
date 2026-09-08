# frozen_string_literal: true

require 'test_helper'

class ExceptionalTest < Minitest::Test
  Location = Struct.new(:path, :lineno)

  FIXTURE = File.expand_path('fixtures/receivers.rb', __dir__)
  LOCAL_LINE = 5

  def test_raises_a_type_error_with_the_message_from_the_block
    error = assert_raises(TypeError) do
      Typerb::Exceptional.raise_type_error([], resolvable_location, :type!) { 'built message' }
    end

    assert_equal 'built message', error.message
  end

  def test_yields_the_resolved_variable_name
    error = assert_raises(TypeError) do
      Typerb::Exceptional.raise_type_error([], resolvable_location, :type!) { |name| "name=#{name.inspect}" }
    end

    assert_equal 'name="arg"', error.message
  end

  def test_yields_nil_when_the_name_cannot_be_resolved
    error = assert_raises(TypeError) do
      Typerb::Exceptional.raise_type_error([], Location.new('/nonexistent/typerb.rb', 1), :type!) do |name|
        "name=#{name.inspect}"
      end
    end

    assert_equal 'name=nil', error.message
  end

  def test_sets_the_given_backtrace
    backtrace = ['somewhere.rb:42:in `call\'']

    error = assert_raises(TypeError) do
      Typerb::Exceptional.raise_type_error(backtrace, resolvable_location, :type!) { 'boom' }
    end

    assert_equal backtrace, error.backtrace
  end

  private

  def resolvable_location = Location.new(FIXTURE, LOCAL_LINE)
end
