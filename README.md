[![Gem Version](https://badge.fury.io/rb/typerb.svg)](https://badge.fury.io/rb/typerb)
[![CI](https://github.com/olegantonyan/typerb/actions/workflows/tests.yml/badge.svg)](https://github.com/olegantonyan/typerb/actions/workflows/tests.yml)

# Typerb

Typecheck sugar for Ruby. Requires Ruby 3.0 or newer.

```ruby
class A
  using Typerb

  def call(some_arg)
    some_arg.type!(String, Symbol)
  end

  def call_with_respond_checks(some_arg)
    some_arg.respond_to!(:strip)
  end

  def call_with_enum(arg)
    arg.enum!(:one, :two)
  end

  def call_with_subset(arg)
    arg.subset_of!(%i[one two])
  end
end

A.new.call(1)                              #=> TypeError: `some_arg` should be String or Symbol, not Integer (1)
A.new.call_with_respond_checks(1)          #=> TypeError: Integer (`some_arg`) should respond to all methods: strip
A.new.call_with_enum(:three)               #=> TypeError: Symbol (`arg`) should be one of: [one, two], not three
A.new.call_with_subset(%i[one three])      #=> TypeError: Array (`arg`) should be subset of: [:one, :two], not [:one, :three]
```

This is equivalent to:

```ruby
class A
  def call(some_arg)
    raise TypeError, "`some_arg` should be String or Symbol, not #{some_arg.class}" unless some_arg.is_a?(String) || some_arg.is_a?(Symbol)
  end

  def call_with_respond_checks(some_arg)
    raise TypeError, "#{some_arg.class} should respond to all methods: strip" unless %i[strip].all? { |meth| some_arg.respond_to?(meth) }
  end
end
```

But without the boilerplate.

There is also a `not_nil!` method, similar to the Crystal language.

```ruby
class A
  using Typerb

  def call(some_arg)
    some_arg.not_nil!
  end
end

A.new.call(nil) #=> TypeError: `some_arg` should not be nil
```

Every method returns `self` when the check passes, so checks can be chained or inlined into assignments.

## Why?

1. Catch errors as early as possible (especially nils);
2. Additional documentation: you're telling other people more about your interfaces.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'typerb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install typerb

## Usage

1. Add `using Typerb` to a class where you want to have type checks.
2. Call `.type!()` on any object to assert its type.
3. PROFIT! No more "NoMethodError for nil" 10 methods up the stack. You'll know exactly where this nil came from.

```ruby
class A
  using Typerb

  attr_reader :param, :another_param

  def initialize(param, another_param)
    @param = param.type!(String)
    @another_param = another_param.not_nil!
  end
end
```

If you're unfamiliar with the `using` keyword - this is a refinement, a kind of monkey patch with a strict
scope. Learn more about [refinements](https://docs.ruby-lang.org/en/master/syntax/refinements_rdoc.html).

The refinement adds `type!`, `not_nil!`, `respond_to!`, `enum!` and `subset_of!` to `BasicObject`, so
they can be called on any object.

`type!` raises a `TypeError` unless `self` is an instance of one of the classes passed as arguments.
The tricky part is getting the name of the variable it was called on, so that the error message points at
the exact variable instead of being an abstract `TypeError`. Typerb does that by parsing the source file
of the caller: with [Prism](https://github.com/ruby/prism) on Ruby 3.3+, and with `RubyVM::AbstractSyntaxTree`
on older versions. If neither is available, or the source cannot be read, the check still works - the message
just doesn't name the variable.

| Ruby      | Parser                       |
| --------- | ---------------------------- |
| 3.3+      | Prism                        |
| 3.0 - 3.2 | `RubyVM::AbstractSyntaxTree` |

Both parsers produce the same messages, and CI runs the suite against every supported version.

## Limitations

The variable name is omitted (the check itself still works) in two cases.

1. Several checks on the same line - there is no way to tell which one raised:

```ruby
class A
  using Typerb

  def initialize(arg1, arg2)
    arg1.type!(Integer); arg2.type!(String)
  end
end
```

2. Code whose source file cannot be read - `eval`, a console session, or a file deleted after being loaded:

```ruby
[1] pry(main)> class A
[1] pry(main)*   using Typerb
[1] pry(main)*   def call(a)
[1] pry(main)*     a.type!(Hash)
[1] pry(main)*   end
[1] pry(main)* end
[2] pry(main)> A.new.call(1)
TypeError: expected Hash, got Integer (1)
```

Please file an issue if you know a scenario where one of these is a real problem.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version,
update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git
tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/olegantonyan/typerb. This project
is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Typerb project's codebases, issue trackers, chat rooms and mailing lists is
expected to follow the [code of conduct](https://github.com/olegantonyan/typerb/blob/master/CODE_OF_CONDUCT.md).
