# frozen_string_literal: true

RSpec.describe Typerb do # rubocop: disable Metrics/BlockLength
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

      attr_reader :arg1, :arg2, :arg3

      def initialize(arg1, arg2, arg3)
        @arg1 = arg1.not_nil!
        @arg2 = arg2.type!(String)
        @arg3 = arg3.respond_to!(:strip)
      end
    end
    expect(kls.new(1, '1', '2').arg1).to eq 1
    expect(kls.new(1, '1', '2').arg2).to eq '1'
    expect(kls.new(1, '1', '2').arg3).to eq '2'
  end

  context 'type!' do # rubocop: disable Metrics/BlockLength
    it 'raises TypeError for wrong type' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.type!(Integer)
          @arg = arg
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new('hello') }.to raise_error(TypeError, '`arg` should be Integer, not String (hello)')
      else
        expect { kls.new('hello') }.to raise_error(TypeError, 'expected Integer, got String (hello)')
      end
      expect { kls.new(123) }.not_to raise_error
    end

    it 'works with multiple arguments' do
      kls = Class.new do
        using Typerb

        def initialize(arg1, arg2, arg3)
          arg1.type!(Numeric)
          arg2.type!(String)
          arg3.type!(Hash)
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new('hello', 1, {}) }.to raise_error(TypeError, '`arg1` should be Numeric, not String (hello)')
        expect { kls.new(1, 123, {}) }.to raise_error(TypeError, '`arg2` should be String, not Integer (123)')
        expect { kls.new(1, '123', nil) }.to raise_error(TypeError, '`arg3` should be Hash, not NilClass ()')
      else
        expect { kls.new('hello', 1, {}) }.to raise_error(TypeError, 'expected Numeric, got String (hello)')
        expect { kls.new(1, 123, {}) }.to raise_error(TypeError, 'expected String, got Integer (123)')
        expect { kls.new(1, '123', nil) }.to raise_error(TypeError, 'expected Hash, got NilClass ()')
      end
      expect { kls.new(123, 'hello', o: 1) }.not_to raise_error
    end

    it 'raises TypeError for wrong type and ugly syntax' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.                type!(Integer) # rubocop: disable Layout/ExtraSpacing
          # NOTE cannot split into multiline, i.e. this will not work
          # arg.
          #    type!(Integer)
          @arg = arg
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new('hello') }.to raise_error(TypeError, '`arg` should be Integer, not String (hello)')
      else
        expect { kls.new('hello') }.to raise_error(TypeError, 'expected Integer, got String (hello)')
      end
      expect { kls.new(123) }.not_to raise_error
    end

    it 'works with multiple classes' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.type!(Integer, String)
          @arg = arg
        end
      end
      expect { kls.new(123) }.not_to raise_error
      expect { kls.new('123') }.not_to raise_error
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new(hello: 123) }.to raise_error(TypeError, '`arg` should be Integer or String, not Hash ({:hello=>123})')
      else
        expect { kls.new(hello: 123) }.to raise_error(TypeError, 'expected Integer or String, got Hash ({:hello=>123})')
      end
    end

    it '(kind of) works with multiple args on the same line 1' do
      kls = Class.new do
        using Typerb

        def initialize(arg1, arg2)
          arg1.type!(Integer); arg2.type!(String)
        end
      end
      expect { kls.new(1, 2) }.to raise_error(TypeError, 'expected String, got Integer (2)')
      expect { kls.new({}, '') }.to raise_error(TypeError, 'expected Integer, got Hash ({})')
    end

    it '(kind of) works with multiple args on the same line 2', multiline: true do
      kls = Class.new do
        using Typerb

        def initialize(arg1, arg2, arg3, arg4)
          arg1.type!(Integer); arg2.type!(String); arg3.type!(String)
          arg4.type!(Hash)
        end
      end
      expect { kls.new(1, 2, '1', {}) }.to raise_error(TypeError, 'expected String, got Integer (2)')
      expect { kls.new({}, '', '', {}) }.to raise_error(TypeError, 'expected Integer, got Hash ({})')
      expect { kls.new(1, '', 2, {}) }.to raise_error(TypeError, 'expected String, got Integer (2)')
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new(1, '', '', 1) }.to raise_error(TypeError, '`arg4` should be Hash, not Integer (1)')
      else
        expect { kls.new(1, '', '', 1) }.to raise_error(TypeError, 'expected Hash, got Integer (1)')
      end
    end

    it 'raises ArgumentError if no classes given' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.type!
          @arg = arg
        end
      end
      expect { kls.new('hello') }.to raise_error(ArgumentError, 'provide at least one class')
    end

    it 'works with BasicObject' do
      require 'tempfile'
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.type!(Tempfile)
          @arg = arg
        end
      end
      expect { kls.new(Tempfile.new) }.not_to raise_error
    end
  end

  context 'not_nil!' do
    it 'not_nil! works' do
      kls = Class.new do
        using Typerb

        def initialize(arg1)
          arg1.not_nil!
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new(nil) }.to raise_error(TypeError, '`arg1` should not be nil')
      else
        expect { kls.new(nil) }.to raise_error(TypeError, 'expected not nil, got nil')
      end
      expect { kls.new(1) }.not_to raise_error
    end
  end

  context 'respond_to!' do # rubocop: disable Metrics/BlockLength
    it 'raises TypeError if object does not respond to specified method' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.respond_to!(:strip)
          @arg = arg
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new(123) }.to raise_error(TypeError, 'Integer (`arg`) should respond to all methods: strip')
      else
        expect { kls.new(123) }.to raise_error(TypeError, 'Integer should respond to all methods: strip')
      end
      expect { kls.new('foo') }.not_to raise_error
    end

    it 'raises TypeError if object does not respond to specified methods' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.respond_to!(:strip, :downcase, :chars)
          @arg = arg
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new(123) }.to raise_error(TypeError, 'Integer (`arg`) should respond to all methods: strip, downcase, chars')
      else
        expect { kls.new(123) }.to raise_error(TypeError, 'Integer should respond to all methods: strip, downcase, chars')
      end
      expect { kls.new('foo') }.not_to raise_error
    end
  end

  context 'enum!' do
    it 'enum! works' do
      kls = Class.new do
        using Typerb

        def initialize(arg1)
          arg1.enum!(:one, :two)
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new(:three) }.to raise_error(TypeError, 'Symbol (`arg1`) should be one of: [one, two], not three')
      else
        expect { kls.new(:three) }.to raise_error(TypeError, 'Symbol expected one of: [one, two], got three')
      end
      expect { kls.new(:one) }.not_to raise_error
    end
  end

  context 'subset_of!' do
    it 'subset_of! works' do
      kls = Class.new do
        using Typerb

        def initialize(arg1)
          arg1.subset_of!(%i[one two])
        end
      end
      if RUBY_VERSION >= '2.6.0'
        expect { kls.new(%i[three one]) }.to raise_error(TypeError, 'Array (`arg1`) should be subset of: [:one, :two], not [:three, :one]')
      else
        expect { kls.new(%i[three one]) }.to raise_error(TypeError, 'Array expected subset of: [:one, :two], got [:three, :one]')
      end
      expect { kls.new([:one]) }.not_to raise_error
    end
  end
end
