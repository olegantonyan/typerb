# frozen_string_literal: true

require 'tempfile'
require_relative 'fixtures/class_variable'

RSpec.shared_examples 'variable name detection' do
  it 'finds a local variable' do
    kls = Class.new do
      using Typerb

      def call(arg)
        arg.type!(Integer)
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`arg` should be Integer, not String (x)')
  end

  it 'finds the receiver of a leading-dot multiline call' do
    kls = Class.new do
      using Typerb

      def call(arg)
        arg
          .type!(Integer)
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`arg` should be Integer, not String (x)')
  end

  it 'finds the receiver of a call with a multiline argument list' do
    kls = Class.new do
      using Typerb

      def call(arg)
        arg.type!(
          Integer
        )
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`arg` should be Integer, not String (x)')
  end

  it 'finds the receiver with extra spacing before the method' do
    kls = Class.new do
      using Typerb

      def call(arg)
        arg.          type!(Integer) # rubocop: disable Layout/ExtraSpacing
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`arg` should be Integer, not String (x)')
  end

  it 'finds the receiver in an assignment' do
    kls = Class.new do
      using Typerb

      def call(arg)
        checked = arg.type!(Integer)
        checked * 2
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`arg` should be Integer, not String (x)')
  end

  it 'finds the receiver inside string interpolation' do
    kls = Class.new do
      using Typerb

      def call(arg)
        "value: #{arg.type!(Integer)}"
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`arg` should be Integer, not String (x)')
  end

  it 'finds a block local variable' do
    kls = Class.new do
      using Typerb

      def call(args)
        args.each { |el| el.type!(Integer) }
      end
    end
    expect { kls.new.call(['x']) }.to raise_error(TypeError, '`el` should be Integer, not String (x)')
  end

  it 'finds an instance variable' do
    kls = Class.new do
      using Typerb

      def call(arg)
        @arg = arg
        @arg.type!(Integer)
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`@arg` should be Integer, not String (x)')
  end

  it 'finds a class variable' do
    expect { ClassVariableFixture.new.call('x') }.to raise_error(TypeError, '`@@arg` should be Integer, not String (x)')
  end

  it 'finds a global variable' do
    kls = Class.new do
      using Typerb

      def call(arg)
        $typerb_spec_global = arg
        $typerb_spec_global.type!(Integer)
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, '`$typerb_spec_global` should be Integer, not String (x)')
  end

  it 'finds a constant' do
    stub_const('TyperbSpecConst', 'x')
    kls = Class.new do
      using Typerb

      def call
        TyperbSpecConst.type!(Integer)
      end
    end
    expect { kls.new.call }.to raise_error(TypeError, '`TyperbSpecConst` should be Integer, not String (x)')
  end

  it 'finds a namespaced constant' do
    stub_const('TyperbSpecNamespace::Value', 'x')
    kls = Class.new do
      using Typerb

      def call
        TyperbSpecNamespace::Value.type!(Integer)
      end
    end
    expect { kls.new.call }.to raise_error(TypeError, '`TyperbSpecNamespace::Value` should be Integer, not String (x)')
  end

  it 'finds a chained receiver' do
    kls = Class.new do
      using Typerb

      def call(arg)
        arg.fetch(:key).type!(Integer)
      end
    end
    expect { kls.new.call(key: 'x') }.to raise_error(TypeError, '`arg.fetch(:key)` should be Integer, not String (x)')
  end

  it 'omits the name for a literal receiver' do
    kls = Class.new do
      using Typerb

      def call
        'x'.type!(Integer)
      end
    end
    expect { kls.new.call }.to raise_error(TypeError, 'expected Integer, got String (x)')
  end

  it 'omits the name when several checks share a line' do
    kls = Class.new do
      using Typerb

      def call(arg1, arg2)
        arg1.type!(Integer); arg2.type!(Integer)
      end
    end
    expect { kls.new.call('x', 1) }.to raise_error(TypeError, 'expected Integer, got String (x)')
    expect { kls.new.call(1, 'x') }.to raise_error(TypeError, 'expected Integer, got String (x)')
  end

  it 'omits the name for code evaluated from a string' do
    kls = Class.new do
      using Typerb

      def call(arg)
        eval('arg.type!(Integer)', binding, __FILE__, __LINE__)
      end
    end
    expect { kls.new.call('x') }.to raise_error(TypeError, 'expected Integer, got String (x)')
  end

  it 'omits the name when the source file is gone' do
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

    expect { TyperbGone.new.call('x') }.to raise_error(TypeError, 'expected Integer, got String (x)')
  ensure
    Object.send(:remove_const, :TyperbGone) if Object.const_defined?(:TyperbGone)
  end

  it 'keeps the caller at the top of the backtrace' do
    kls = Class.new do
      using Typerb

      def call(arg)
        arg.type!(Integer)
      end
    end
    kls.new.call('x')
  rescue TypeError => e
    expect(e.backtrace.first).to include(__FILE__)
    expect(e.backtrace.first).not_to include('lib/typerb')
  end
end

RSpec.describe Typerb::VariableName do
  context 'with the prism backend' do
    before do
      skip 'prism is not available' unless Typerb::PrismParser.available?
    end

    it_behaves_like 'variable name detection'
  end

  context 'with the RubyVM::AbstractSyntaxTree backend' do
    before do
      skip 'RubyVM::AbstractSyntaxTree is not available' unless Typerb::RubyVmParser.available?

      allow(Typerb::PrismParser).to receive(:available?).and_return(false)
    end

    it_behaves_like 'variable name detection'
  end

  context 'without any backend' do
    before do
      allow(Typerb::PrismParser).to receive(:available?).and_return(false)
      allow(Typerb::RubyVmParser).to receive(:available?).and_return(false)
    end

    it 'falls back to a message without the variable name' do
      kls = Class.new do
        using Typerb

        def call(arg)
          arg.type!(Integer)
        end
      end
      expect { kls.new.call('x') }.to raise_error(TypeError, 'expected Integer, got String (x)')
    end
  end
end
