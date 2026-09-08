# frozen_string_literal: true

# Parser fixture: line numbers below are asserted in test/parsers_test.rb.
def local(arg)
  arg.type!(Integer)
end

def multiline(arg)
  arg
    .type!(Integer)
end

def two_on_one_line(first, second)
  first.type!(Integer); second.type!(Integer)
end

def literal_receiver
  'x'.type!(Integer)
end

def another_check(arg)
  arg.not_nil!
end
