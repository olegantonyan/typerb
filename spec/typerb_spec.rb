# frozen_string_literal: true

RSpec.describe Typerb do # rubocop: disable Metrics/BlockLength
  it 'has a version number' do
    expect(Typerb::VERSION).not_to be nil
  end

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

  it 'does not work without refinement' do
    kls = Class.new do
      def initialize(arg)
        arg.type!(Integer)
        @arg = arg
      end
    end
    expect { kls.new(1) }.to raise_error(NameError)
  end

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

  it 'returns self' do
    kls = Class.new do
      using Typerb

      attr_reader :arg1, :arg2

      def initialize(arg1, arg2)
        @arg1 = arg1.not_nil!
        @arg2 = arg2.type!(String)
      end
    end
    expect(kls.new(1, '1').arg1).to eq 1
    expect(kls.new(1, '1').arg2).to eq '1'
  end

  context "respond_to!" do
    it 'raises TypeError if object does not respond to specified method' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.respond_to!(:strip)
          @arg = arg
        end
      end
      expect { kls.new(123) }.to raise_error(TypeError, 'Integer should respond to all methods: strip')
      expect { kls.new("foo") }.not_to raise_error
    end

    it 'raises TypeError if object does not respond to specified methods' do
      kls = Class.new do
        using Typerb

        def initialize(arg)
          arg.respond_to!(:strip, :downcase, :chars)
          @arg = arg
        end
      end
      expect { kls.new(123) }.to raise_error(TypeError, 'Integer should respond to all methods: strip, downcase, chars')
      expect { kls.new("foo") }.not_to raise_error
    end



  end

end
