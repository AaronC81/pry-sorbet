# pry-sorbet

pry-sorbet is a Pry extension which enables it to work seamlessly with Sorbet
projects.

**Before:** Incorrect method source

```
From: /home/aaron/.rbenv/versions/2.6.3/lib/ruby/gems/2.6.0/gems/sorbet-runtime-0.4.4929/lib/types/private/methods/_methods.rb @ line 208:
Owner: #<Class:Foo>
Visibility: public
Number of lines: 35

T::Private::ClassUtils.replace_method(mod, method_name) do |*args, &blk|
  if !T::Private::Methods.has_sig_block_for_method(new_method)
    # This should only happen if the user used alias_method to grab a handle
    # to the original pre-unwound `sig` method. I guess we'll just proxy the
    # call forever since we don't know who is holding onto this handle to
```

**After:** Method source and a signature!

```
From: playground/test.rb @ line 9:
Owner: #<Class:Foo>
Visibility: public
Sorbet: sig { returns(Integer) }
Number of lines: 3

def self.bar
  3
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pry-sorbet'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pry-sorbet

## Usage

Make sure you've required `pry-sorbet`. The `$` command in Pry will be
automatically overwritten to add the Sorbet-specific functionality.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AaronC81/pry-sorbet.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
