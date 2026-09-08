# frozen_string_literal: true

require 'test_helper'
require 'set'
require 'tempfile'

using Typerb

class VersionTest < Minitest::Test
  def test_has_a_version_number
    refute_nil Typerb::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, Typerb::VERSION)
  end
end

class ReturnValueTest < Minitest::Test
  def test_every_check_returns_the_receiver_itself
    arg = +'a'

    assert_same arg, arg.not_nil!
    assert_same arg, arg.type!(String)
    assert_same arg, arg.respond_to!(:strip)
    assert_same arg, arg.enum!('a')
  end

  def test_subset_of_returns_the_receiver_itself
    arg = [1]

    assert_same arg, arg.subset_of!([1, 2])
  end

  def test_returns_a_frozen_receiver_unchanged
    arg = 'a'.freeze

    assert_same arg, arg.type!(String)
  end
end

class TypeBangTest < Minitest::Test
  def test_accepts_an_exact_class
    assert_equal 1, 1.type!(Integer)
  end

  def test_accepts_a_subclass_instance
    assert_in_delta 1.5, 1.5.type!(Numeric)
  end

  def test_accepts_an_included_module
    assert_equal 1, 1.type!(Comparable)
  end

  def test_accepts_a_class_object_as_the_receiver
    assert_equal String, String.type!(Class)
  end

  def test_accepts_a_module_object_as_the_receiver
    assert_equal Comparable, Comparable.type!(Module)
  end

  def test_accepts_a_struct_instance
    struct = Struct.new(:field)

    assert_equal struct.new(1), struct.new(1).type!(struct)
  end

  def test_accepts_nil_as_nil_class
    assert_nil nil.type!(NilClass)
  end

  def test_accepts_false_as_false_class
    assert_equal false, false.type!(FalseClass)
  end

  def test_passes_when_any_of_the_classes_matches
    assert_equal 1, 1.type!(String, Integer, Symbol)
  end

  def test_raises_for_wrong_type
    arg = 'hello'

    error = assert_raises(TypeError) { arg.type!(Integer) }
    assert_equal '`arg` should be Integer, not String (hello)', error.message
  end

  def test_names_a_single_expected_class_without_a_separator
    arg = 'hello'

    error = assert_raises(TypeError) { arg.type!(Integer) }
    refute_includes error.message, ' or '
  end

  def test_joins_two_expected_classes
    arg = 'hello'

    error = assert_raises(TypeError) { arg.type!(Integer, Symbol) }
    assert_equal '`arg` should be Integer or Symbol, not String (hello)', error.message
  end

  def test_joins_every_expected_class
    arg = { hello: 123 }

    error = assert_raises(TypeError) { arg.type!(Integer, String, Symbol) }
    assert_equal "`arg` should be Integer or String or Symbol, not Hash (#{arg})", error.message
  end

  def test_keeps_duplicate_classes_in_the_message
    arg = 1

    error = assert_raises(TypeError) { arg.type!(String, String) }
    assert_equal '`arg` should be String or String, not Integer (1)', error.message
  end

  def test_reports_nil_as_nil_class_with_an_empty_value
    arg = nil

    error = assert_raises(TypeError) { arg.type!(String) }
    assert_equal '`arg` should be String, not NilClass ()', error.message
  end

  def test_names_an_anonymous_expected_class
    arg = 'hello'
    klass = Class.new

    error = assert_raises(TypeError) { arg.type!(klass) }
    assert_match(/\A`arg` should be #<Class:0x\h+>, not String \(hello\)\z/, error.message)
  end

  def test_names_an_anonymous_receiver_class
    arg = Class.new.new

    error = assert_raises(TypeError) { arg.type!(Integer) }
    assert_match(/\A`arg` should be Integer, not #<Class:0x\h+> /, error.message)
  end

  def test_raises_argument_error_without_classes
    arg = 'hello'

    error = assert_raises(ArgumentError) { arg.type! }
    assert_equal 'provide at least one class', error.message
  end

  def test_works_with_a_delegating_object
    arg = Tempfile.new

    assert_same arg, arg.type!(Tempfile)
  end

  def test_does_not_support_a_bare_basic_object
    arg = Class.new(BasicObject).new

    assert_raises(NoMethodError) { arg.type!(Integer) }
  end
end

class NotNilBangTest < Minitest::Test
  def test_raises_for_nil
    arg = nil

    error = assert_raises(TypeError) { arg.not_nil! }
    assert_equal '`arg` should not be nil', error.message
  end

  def test_passes_false_through
    arg = false

    assert_equal false, arg.not_nil!
  end

  def test_passes_empty_values_through
    assert_equal '', ''.not_nil!
    assert_equal [], [].not_nil!
    assert_equal({}, {}.not_nil!)
    assert_equal 0, 0.not_nil!
  end
end

class RespondToBangTest < Minitest::Test
  def test_accepts_a_method_that_exists
    assert_equal 'foo', 'foo'.respond_to!(:strip)
  end

  def test_accepts_method_names_given_as_strings
    assert_equal 'foo', 'foo'.respond_to!('strip')
  end

  def test_requires_every_method
    assert_equal 'foo', 'foo'.respond_to!(:strip, :downcase, :chars)
  end

  def test_raises_when_the_object_does_not_respond_to_a_method
    arg = 123

    error = assert_raises(TypeError) { arg.respond_to!(:strip) }
    assert_equal 'Integer (`arg`) should respond to all methods: strip', error.message
  end

  def test_lists_every_requested_method_even_when_only_one_is_missing
    arg = 123

    error = assert_raises(TypeError) { arg.respond_to!(:to_s, :strip, :abs) }
    assert_equal 'Integer (`arg`) should respond to all methods: to_s, strip, abs', error.message
  end

  def test_does_not_count_private_methods
    arg = Class.new { private def secret = 1 }.new

    assert_raises(TypeError) { arg.respond_to!(:secret) }
  end

  def test_counts_methods_answered_by_respond_to_missing
    arg = Class.new do
      def respond_to_missing?(name, include_private = false) = name == :magic || super
      def method_missing(name, *args) = name == :magic ? 1 : super
    end.new

    assert_same arg, arg.respond_to!(:magic)
  end

  def test_raises_argument_error_without_methods
    arg = 'hello'

    error = assert_raises(ArgumentError) { arg.respond_to! }
    assert_equal 'provide at least one method', error.message
  end
end

class EnumBangTest < Minitest::Test
  def test_accepts_a_member
    assert_equal :one, :one.enum!(:one, :two)
  end

  def test_accepts_a_single_element_enum
    assert_equal :one, :one.enum!(:one)
  end

  def test_compares_by_value_not_identity
    arg = +'one'

    assert_equal 'one', arg.enum!('one', 'two')
  end

  def test_distinguishes_strings_from_symbols
    arg = 'one'

    assert_raises(TypeError) { arg.enum!(:one) }
  end

  def test_accepts_nil_as_a_member
    arg = nil

    assert_nil arg.enum!(nil, 1)
  end

  def test_accepts_false_as_a_member
    arg = false

    assert_equal false, arg.enum!(false, 1)
  end

  def test_raises_for_an_element_outside_the_enum
    arg = :three

    error = assert_raises(TypeError) { arg.enum!(:one, :two) }
    assert_equal 'Symbol (`arg`) should be one of: [one, two], not three', error.message
  end

  def test_raises_argument_error_without_elements
    arg = :three

    error = assert_raises(ArgumentError) { arg.enum! }
    assert_equal 'provide at least one enum element', error.message
  end
end

class SubsetOfBangTest < Minitest::Test
  def test_accepts_a_proper_subset
    assert_equal [1], [1].subset_of!([1, 2])
  end

  def test_accepts_an_equal_set
    assert_equal [1, 2], [1, 2].subset_of!([1, 2])
  end

  def test_accepts_an_empty_receiver
    assert_equal [], [].subset_of!([1])
  end

  def test_accepts_duplicates_in_the_receiver
    assert_equal [1, 1], [1, 1].subset_of!([1])
  end

  def test_accepts_a_set_receiver
    assert_equal Set[1], Set[1].subset_of!([1, 2])
  end

  def test_accepts_a_hash_receiver_compared_as_pairs
    assert_equal({ a: 1 }, { a: 1 }.subset_of!([[:a, 1]]))
  end

  def test_accepts_any_enumerable_superset
    arg = [1]

    assert_equal [1], arg.subset_of!(Set[1, 2])
    assert_equal [1], arg.subset_of!(1..2)
  end

  def test_raises_for_an_element_outside_the_superset
    arg = %i[three one]

    error = assert_raises(TypeError) { arg.subset_of!(%i[one two]) }
    assert_equal 'Array (`arg`) should be subset of: [:one, :two], not [:three, :one]', error.message
  end

  def test_describes_a_non_array_superset_with_its_own_to_s
    arg = [3]
    superset = 1..2

    error = assert_raises(TypeError) { arg.subset_of!(superset) }
    assert_equal 'Array (`arg`) should be subset of: 1..2, not [3]', error.message
  end

  def test_raises_argument_error_for_a_non_enumerable_receiver
    arg = 1

    error = assert_raises(ArgumentError) { arg.subset_of!([1]) }
    assert_equal 'receiver must be Enumerable', error.message
  end

  def test_raises_argument_error_for_a_non_enumerable_superset
    arg = [1]

    error = assert_raises(ArgumentError) { arg.subset_of!(1) }
    assert_equal 'superset must be Enumerable', error.message
  end

  def test_raises_argument_error_for_an_empty_superset
    arg = [1]

    error = assert_raises(ArgumentError) { arg.subset_of!([]) }
    assert_equal 'provide at least one superset element', error.message
  end

  def test_raises_argument_error_for_an_empty_enumerable_superset
    arg = [1]

    error = assert_raises(ArgumentError) { arg.subset_of!(Set.new) }
    assert_equal 'provide at least one superset element', error.message
  end
end
