# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'tempfile'

module ParserContract
  FIXTURE = File.expand_path('fixtures/receivers.rb', __dir__)
  LOCAL_LINE = 5
  MULTILINE_LINE = 10
  SHARED_LINE = 14
  LITERAL_LINE = 18
  NOT_NIL_LINE = 22
  COMMENT_LINE = 3

  def test_is_available_on_this_ruby
    assert parser.available?
  end

  def test_finds_a_local_variable_receiver
    assert_equal ['arg'], parser.receiver_sources(FIXTURE, LOCAL_LINE, :type!)
  end

  def test_finds_the_receiver_of_a_leading_dot_call_on_the_message_line
    assert_equal ['arg'], parser.receiver_sources(FIXTURE, MULTILINE_LINE, :type!)
  end

  def test_returns_every_call_sharing_a_line
    assert_equal %w[first second], parser.receiver_sources(FIXTURE, SHARED_LINE, :type!).sort
  end

  def test_returns_nil_for_a_literal_receiver
    assert_equal [nil], parser.receiver_sources(FIXTURE, LITERAL_LINE, :type!)
  end

  def test_matches_on_the_method_name
    assert_equal ['arg'], parser.receiver_sources(FIXTURE, NOT_NIL_LINE, :not_nil!)
    assert_empty parser.receiver_sources(FIXTURE, NOT_NIL_LINE, :type!)
    assert_empty parser.receiver_sources(FIXTURE, LOCAL_LINE, :not_nil!)
  end

  def test_returns_nothing_for_a_line_without_a_call
    assert_empty parser.receiver_sources(FIXTURE, COMMENT_LINE, :type!)
  end

  def test_returns_nothing_for_a_line_past_the_end_of_the_file
    assert_empty parser.receiver_sources(FIXTURE, 10_000, :type!)
  end
end

class PrismParserTest < Minitest::Test
  include ParserContract

  def setup
    skip 'prism is not available' unless Typerb::PrismParser.available?
  end

  def parser = Typerb::PrismParser
end

class RubyVmParserTest < Minitest::Test
  include ParserContract

  def setup
    skip 'RubyVM::AbstractSyntaxTree is not available' unless Typerb::RubyVmParser.available?
  end

  def parser = Typerb::RubyVmParser
end

class ParserParityTest < Minitest::Test
  CALLER_LINES = [
    ParserContract::LOCAL_LINE,
    ParserContract::MULTILINE_LINE,
    ParserContract::SHARED_LINE,
    ParserContract::LITERAL_LINE,
    ParserContract::COMMENT_LINE
  ].freeze

  def setup
    return if Typerb::PrismParser.available? && Typerb::RubyVmParser.available?

    skip 'both parsers are required'
  end

  def test_both_parsers_agree_on_every_caller_line
    CALLER_LINES.each do |line|
      prism = Typerb::PrismParser.receiver_sources(ParserContract::FIXTURE, line, :type!).sort_by(&:to_s)
      ruby_vm = Typerb::RubyVmParser.receiver_sources(ParserContract::FIXTURE, line, :type!).sort_by(&:to_s)

      assert_equal prism, ruby_vm, "parsers disagree on line #{line}"
    end
  end
end

class UnparsableSourceTest < Minitest::Test
  def test_variable_name_falls_back_instead_of_raising
    file = Tempfile.new(['broken', '.rb'])
    file.write("def broken(\n")
    file.close

    location = FakeLocation.new(file.path, 1)

    assert_nil Typerb::VariableName.new(location, :type!).get
  ensure
    FileUtils.rm_f(file.path)
  end

  def test_variable_name_returns_nil_for_a_missing_file
    location = FakeLocation.new('/nonexistent/typerb/file.rb', 1)

    assert_nil Typerb::VariableName.new(location, :type!).get
  end

  def test_variable_name_returns_nil_without_a_location
    assert_nil Typerb::VariableName.new(nil, :type!).get
  end

  FakeLocation = Struct.new(:path, :lineno)
end
