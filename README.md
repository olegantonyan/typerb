# Typerb

Proof of concept type-checking library for Ruby 2.6.

```ruby
class A
  using Typerb

  def strong_type_call(some_arg)
    some_arg.type!(String, Symbol)
  end

  def call_like_interface(some_arg)
    some_arg.should_respond_to!(:strip)
  end

end

A.new.strong_type_call(1)  #=> TypeError: '`some_arg` should be String or Symbol, not Integer'
A.new.call_like_interface(1) #=> TypeError: 'Integer should respond to all methods: strip'
```

This is equivalent to:
```ruby
class A
  def strong_type_call(some_arg)
    raise TypeError, "`some_arg` should be String or Symbol, not #{some_arg.class}" unless [String, Symbol].include?(some_arg.class)
  end

  def call_like_interface(some_arg)
    raise TypeError, "#{some_arg.class} should respond to all methods: strip" unless [:strip].all{|meth| some_arg.respond_to?(meth)}
  end
end
```

But without boilerplate.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'typerb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install typerb

If this fails with error
```
ERROR:  Error installing typerb:
        There are no versions of typerb (>= 0) compatible with your Ruby & RubyGems
        typerb requires Ruby version >= 2.6.0.pre.preview3. The current ruby version is 2.6.0.
```
even when you have Ruby 2.6.0-preview3 installed, then try installing it through Gemfile from git:
```ruby
gem 'typerb', github: 'olegantonyan/typerb'
```

## Usage

1. Add `using Typerb` to a class where you want to have type check.
2. Call `.type!()` on any object to assert its type.
3. PROFIT! No more "NoMethodError for nil" 10 methods up the stack. You'll know exactly where this nil came from.

If you're unfamiliar with `using` keyword - this is refinement - a relatively new feature in Ruby (since 2.0). It's kind of monkey-patch, but with strict scope. Learn more about [refinements](https://ruby-doc.org/core-2.5.3/doc/syntax/refinements_rdoc.html).

This refinement adds `type!()` method to `Object` class so you can call it on almost much any object (except those inherited from `BasicObject`, but these are rare).

The method will raise an exception if `self` is not an instance of one of the classes passed as arguments. The tricky part, however, is to get the variable name on which it's called. You need this to get a nice error message telling you exactly which variable has wrong type, not just an abstract `TypeError`. That's why we need Ruby 2.6 with its new `RubyVM::AST` (https://ruby-doc.org/core-2.6.0.preview3/RubyVM/AST.html).

## Limitations

It requires Ruby 2.6.0-preview3. Relies on `RubyVM::AST` which may change in release version. So, expect breaking changes in Ruby.

Known limitations:

1. Multi-line method call:
```ruby
class A
  using Typerb

  def call(some_arg)
    some_arg.
            type!(String) # this won't work. type!() call must be on the same line with the variable it's called on
                          # some_arg.    type!(String) is ok though
  end
end
```

2. Method defined in console:
```ruby
[1] pry(main)> class A
[1] pry(main)*   using Typerb
[1] pry(main)*   def call(a)
[1] pry(main)*     a.type!(Hash)
[1] pry(main)*   end
[1] pry(main)* end
[2] pry(main)> A.new.call(1)
TypeError: expected Hash, got Integer  # here we cannot get the source code for a line containing "a.type!(Hash)", so cannot see the variable name
```

These limitations shouldn't be a problem in any case. Please, file an issue if you know a scenario where one of these could be a real problem.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/olegantonyan/typerb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Typerb project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/olegantonyan/typerb/blob/master/CODE_OF_CONDUCT.md).
