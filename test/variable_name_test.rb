# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

using Typerb

TYPERB_CONSTANT = 'x'

module TyperbNamespace
  VALUE = 'x'
end

class ClassVariableHost
  def call(arg)
    @@arg = arg
    @@arg.type!(Integer)
  end
end

module VariableNameTests
  WRONG_TYPE = '`%s` should be Integer, not String (x)'

  def test_finds_a_local_variable
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type!(Integer) }
  end

  def test_finds_the_receiver_of_a_leading_dot_multiline_call
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) do
      arg
        .type!(Integer)
    end
  end

  def test_finds_the_receiver_of_a_call_with_a_multiline_argument_list
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) do
      arg.type!(
        Integer
      )
    end
  end

  def test_finds_the_receiver_with_extra_spacing_before_the_method
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.          type!(Integer) }
  end

  def test_finds_the_receiver_in_an_assignment
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { _checked = arg.type!(Integer) }
  end

  def test_finds_the_receiver_inside_string_interpolation
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { "value: #{arg.type!(Integer)}" }
  end

  def test_finds_a_block_local_variable
    assert_message(format(WRONG_TYPE, 'el')) { ['x'].each { |el| el.type!(Integer) } }
  end

  def test_finds_an_instance_variable
    @arg = 'x'

    assert_message(format(WRONG_TYPE, '@arg')) { @arg.type!(Integer) }
  end

  def test_finds_a_class_variable
    assert_message(format(WRONG_TYPE, '@@arg')) { ClassVariableHost.new.call('x') }
  end

  def test_finds_a_global_variable
    $typerb_test_global = 'x'

    assert_message(format(WRONG_TYPE, '$typerb_test_global')) { $typerb_test_global.type!(Integer) }
  end

  def test_finds_a_constant
    assert_message(format(WRONG_TYPE, 'TYPERB_CONSTANT')) { TYPERB_CONSTANT.type!(Integer) }
  end

  def test_finds_a_namespaced_constant
    assert_message(format(WRONG_TYPE, 'TyperbNamespace::VALUE')) { TyperbNamespace::VALUE.type!(Integer) }
  end

  def test_finds_a_chained_receiver
    arg = { key: 'x' }

    assert_message(format(WRONG_TYPE, 'arg.fetch(:key)')) { arg.fetch(:key).type!(Integer) }
  end

  def test_omits_the_name_for_a_literal_receiver
    assert_message('expected Integer, got String (x)') { 'x'.type!(Integer) }
  end

  def test_omits_the_name_when_several_checks_share_a_line
    first = 'x'
    second = 'x'

    assert_message('expected Integer, got String (x)') { first.type!(Integer); second.type!(Integer) }
  end

  def test_omits_the_name_for_code_evaluated_from_a_string
    code = 'evaluated = +"x"; evaluated.type!(Integer)'

    assert_message('expected Integer, got String (x)') { eval(code, binding, __FILE__, __LINE__) }
  end

  def test_omits_the_name_when_the_source_file_is_gone
    file = Tempfile.new(['typerb_gone', '.rb'])
    file.write(<<~RUBY)
      using Typerb

      TyperbGone = Class.new do
        def call(arg)
          arg.type!(Integer)
        end
      end
    RUBY
    file.close
    load(file.path)
    File.unlink(file.path)

    assert_message('expected Integer, got String (x)') { TyperbGone.new.call('x') }
  ensure
    Object.send(:remove_const, :TyperbGone) if Object.const_defined?(:TyperbGone)
  end

  def test_finds_the_receiver_of_a_safe_navigation_call
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg&.type!(Integer) }
  end

  def test_finds_an_index_receiver
    arg = ['x']

    assert_message("`arg[0]` should be Integer, not String (x)") { arg[0].type!(Integer) }
  end

  def test_finds_a_receiver_that_takes_a_block
    arg = ['x']

    assert_message('`arg.map { |i| i }` should be Integer, not Array (["x"])') { arg.map { |i| i }.type!(Integer) }
  end

  def test_finds_the_receiver_of_a_call_without_parentheses
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type! Integer }
  end

  def test_finds_the_receiver_with_splatted_classes
    arg = 'x'
    klasses = [Integer]

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type!(*klasses) }
  end

  def test_finds_the_receiver_behind_a_modifier_if
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type!(Integer) if arg }
  end

  def test_finds_the_receiver_inside_a_ternary
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg ? arg.type!(Integer) : nil }
  end

  def test_finds_the_receiver_behind_a_rescue_modifier
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type!(Integer) rescue raise }
  end

  def test_finds_the_receiver_in_nested_blocks
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { [1].each { [2].each { arg.type!(Integer) } } }
  end

  def test_finds_the_receiver_inside_a_lambda
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { -> { arg.type!(Integer) }.call }
  end

  def test_finds_the_receiver_in_a_method_built_by_define_method
    klass = Class.new { define_method(:call) { |arg| arg.type!(Integer) } }

    assert_message(format(WRONG_TYPE, 'arg')) { klass.new.call('x') }
  end

  def test_finds_the_receiver_in_a_singleton_method
    object = Object.new
    def object.call(arg) = arg.type!(Integer)

    assert_message(format(WRONG_TYPE, 'arg')) { object.call('x') }
  end

  def test_finds_the_receiver_in_a_module_method
    mod = Module.new { def self.call(arg) = arg.type!(Integer) }

    assert_message(format(WRONG_TYPE, 'arg')) { mod.call('x') }
  end

  def test_ignores_a_comment_mentioning_the_method_on_the_same_line
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type!(Integer) } # other.type!(String)
  end

  def test_ignores_a_string_mentioning_the_method_on_the_same_line
    arg = 'x'
    noise = 'other.type!(String)'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type!(Integer) if noise }
  end

  def test_tells_apart_two_different_checks_on_the_same_line
    present = 'x'
    missing = nil

    assert_message(format(WRONG_TYPE, 'present')) { present.type!(Integer); missing.not_nil! }
    assert_message('`missing` should not be nil') { missing.not_nil!; present.type!(String) }
  end

  def test_resolves_the_same_variable_on_different_lines
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { arg.type!(Integer) }
    assert_message('`arg` should be Symbol, not String (x)') { arg.type!(Symbol) }
  end

  def test_finds_a_receiver_after_multibyte_text_on_the_same_line
    arg = 'x'

    assert_message(format(WRONG_TYPE, 'arg')) { ['日本語のテキスト'].each { arg.type!(Integer) } }
  end

  def test_finds_a_multibyte_variable_name
    переменная = 'x'

    assert_message(format(WRONG_TYPE, 'переменная')) { переменная.type!(Integer) }
  end

  def test_omits_the_name_for_a_parenthesized_expression
    left = 'x'
    right = 'y'

    assert_message('expected Integer, got String (xy)') { (left + right).type!(Integer) }
  end

  def test_omits_the_name_for_a_self_receiver
    assert_message('expected Integer, got String (x)') { 'x'.instance_eval { self.type!(Integer) } }
  end

  def test_keeps_the_caller_at_the_top_of_the_backtrace
    arg = 'x'

    error = assert_raises(TypeError) { arg.type!(Integer) }
    assert_includes error.backtrace.first, __FILE__
    refute_includes error.backtrace.first, 'lib/typerb'
  end

  private

  def assert_message(expected, &block)
    error = assert_raises(TypeError, &block)
    assert_equal expected, error.message
  end
end

class PrismBackendTest < Minitest::Test
  include VariableNameTests

  def setup
    skip 'prism is not available' unless Typerb::PrismParser.available?
  end
end

class RubyVmBackendTest < Minitest::Test
  include VariableNameTests
  include BackendStub

  def setup
    skip 'RubyVM::AbstractSyntaxTree is not available' unless Typerb::RubyVmParser.available?
  end

  def run
    without_backends(Typerb::PrismParser) { super }
  end
end

class NoBackendTest < Minitest::Test
  include BackendStub

  def test_falls_back_to_a_message_without_the_variable_name
    arg = 'x'

    error = assert_raises(TypeError) { arg.type!(Integer) }
    assert_equal 'expected Integer, got String (x)', error.message
  end

  def run
    without_backends(*Typerb::VariableName::BACKENDS) { super }
  end
end
