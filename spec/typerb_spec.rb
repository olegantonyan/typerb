# frozen_string_literal: true

require 'set'
require 'tempfile'

RSpec.describe Typerb do
  it 'has a version number' do
    expect(Typerb::VERSION).not_to be nil
  end

  it 'does not work without refinement' do
    kls = Class.new do
      def initialize(arg)
        arg.type!(Integer)
        @arg = arg
      end
    end
    expect { kls.new(1) }.to raise_error(NameError)
  end

  it 'returns self' do
    kls = Class.new do
      using Typerb

      def call(arg)
        [arg.not_nil!, arg.type!(String), arg.respond_to!(:strip), arg.enum!('a'), [arg].subset_of!(['a'])]
      end
    end
    expect(kls.new.call('a')).to eq ['a', 'a', 'a', 'a', ['a']]
  end

  describe 'type!' do
    it 'raises TypeError for wrong type' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.type!(Integer)
        end
      end
      expect { kls.new.call('hello') }.to raise_error(TypeError, '`arg` should be Integer, not String (hello)')
      expect { kls.new.call(123) }.not_to raise_error
    end

    it 'accepts subclasses' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.type!(Numeric)
        end
      end
      expect { kls.new.call(1.5) }.not_to raise_error
      expect { kls.new.call(Rational(1, 2)) }.not_to raise_error
    end

    it 'accepts modules' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.type!(Comparable)
        end
      end
      expect { kls.new.call(1) }.not_to raise_error
      expect { kls.new.call([]) }.to raise_error(TypeError, '`arg` should be Comparable, not Array ([])')
    end

    it 'lists every expected class' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.type!(Integer, String, Symbol)
        end
      end
      hash = { hello: 123 }
      expect { kls.new.call(hash) }.to raise_error(TypeError, "`arg` should be Integer or String or Symbol, not Hash (#{hash})")
    end

    it 'names an anonymous expected class' do
      anonymous = Class.new
      kls = Class.new do
        using Typerb

        def call(arg, klass)
          arg.type!(klass)
        end
      end
      expect { kls.new.call('hello', anonymous) }.to raise_error(TypeError, /\A`arg` should be #<Class:0x\h+>, not String \(hello\)\z/)
    end

    it 'raises ArgumentError without classes' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.type!
        end
      end
      expect { kls.new.call('hello') }.to raise_error(ArgumentError, 'provide at least one class')
    end

    it 'works with a delegating object' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.type!(Tempfile)
        end
      end
      expect { kls.new.call(Tempfile.new) }.not_to raise_error
    end
  end

  describe 'not_nil!' do
    it 'raises TypeError for nil' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.not_nil!
        end
      end
      expect { kls.new.call(nil) }.to raise_error(TypeError, '`arg` should not be nil')
    end

    it 'passes false through' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.not_nil!
        end
      end
      expect(kls.new.call(false)).to be false
    end
  end

  describe 'respond_to!' do
    it 'raises TypeError if the object does not respond to a method' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.respond_to!(:strip)
        end
      end
      expect { kls.new.call(123) }.to raise_error(TypeError, 'Integer (`arg`) should respond to all methods: strip')
      expect { kls.new.call('foo') }.not_to raise_error
    end

    it 'requires all the methods' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.respond_to!(:strip, :downcase, :chars)
        end
      end
      expect { kls.new.call(123) }.to raise_error(TypeError, 'Integer (`arg`) should respond to all methods: strip, downcase, chars')
      expect { kls.new.call('foo') }.not_to raise_error
    end

    it 'raises ArgumentError without methods' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.respond_to!
        end
      end
      expect { kls.new.call('hello') }.to raise_error(ArgumentError, 'provide at least one method')
    end
  end

  describe 'enum!' do
    it 'raises TypeError for an element outside the enum' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.enum!(:one, :two)
        end
      end
      expect { kls.new.call(:three) }.to raise_error(TypeError, 'Symbol (`arg`) should be one of: [one, two], not three')
      expect { kls.new.call(:one) }.not_to raise_error
    end

    it 'compares by value' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.enum!('one', 'two')
        end
      end
      expect { kls.new.call(+'one') }.not_to raise_error
    end

    it 'raises ArgumentError without elements' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.enum!
        end
      end
      expect { kls.new.call(:three) }.to raise_error(ArgumentError, 'provide at least one enum element')
    end
  end

  describe 'subset_of!' do
    it 'raises TypeError for an element outside the superset' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.subset_of!(%i[one two])
        end
      end
      expect { kls.new.call(%i[three one]) }.to raise_error(TypeError, 'Array (`arg`) should be subset of: [:one, :two], not [:three, :one]')
      expect { kls.new.call(%i[one]) }.not_to raise_error
    end

    it 'accepts any Enumerable superset' do
      kls = Class.new do
        using Typerb

        def call(arg, superset)
          arg.subset_of!(superset)
        end
      end
      expect { kls.new.call([1], Set[1, 2]) }.not_to raise_error
      expect { kls.new.call([1], 1..2) }.not_to raise_error
    end

    it 'raises ArgumentError for a non-Enumerable receiver' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.subset_of!([1])
        end
      end
      expect { kls.new.call(1) }.to raise_error(ArgumentError, 'receiver must be Enumerable')
    end

    it 'raises ArgumentError for a non-Enumerable superset' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.subset_of!(1)
        end
      end
      expect { kls.new.call([1]) }.to raise_error(ArgumentError, 'superset must be Enumerable')
    end

    it 'raises ArgumentError for an empty superset' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.subset_of!([])
        end
      end
      expect { kls.new.call([1]) }.to raise_error(ArgumentError, 'provide at least one superset element')
    end
  end
end
