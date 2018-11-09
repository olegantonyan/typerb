RSpec.describe Typerb do
  it 'has a version number' do
    expect(Typerb::VERSION).not_to be nil
  end

  it 'has RubyVM::AST' do
    expect(RubyVM::AST.parse('1 + 2').children.size).to eq(3)
  end

  it 'raises TypeError for wrong type' do
    kls = Class.new do
      using Typerb

      def initialize(arg)
        arg.type!(Integer)
        @arg = arg
      end
    end
    expect { kls.new('hello') }.to raise_error(TypeError, '`arg` should be Integer, not String')
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
    expect { kls.new('hello', 1, {}) }.to raise_error(TypeError, '`arg1` should be Numeric, not String')
    expect { kls.new(1, 123, {}) }.to raise_error(TypeError, '`arg2` should be String, not Integer')
    expect { kls.new(1, '123', nil) }.to raise_error(TypeError, '`arg3` should be Hash, not NilClass')
    expect { kls.new(123, 'hello', { o: 1 }) }.not_to raise_error
  end

  it 'raises TypeError for wrong type and ugly syntax' do
    kls = Class.new do
      using Typerb

      def initialize(arg)
        arg.                type!(Integer)
        # NOTE cannot split into multiline, i.e. this will not work
        # arg.
        #    type!(Integer)
        @arg = arg
      end
    end
    expect { kls.new('hello') }.to raise_error(TypeError, '`arg` should be Integer, not String')
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
    expect { kls.new({}) }.to raise_error(TypeError, '`arg` should be Integer or String, not Hash')
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
end
