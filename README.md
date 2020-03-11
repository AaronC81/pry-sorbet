# pry-sorbet

pry-sorbet is a Pry extension which enables it to work seamlessly with Sorbet
projects.

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

### Fixes method source

Since Sorbet runtime wraps methods with a signature to execute runtime checks
on parameters and return values, the source location of methods end up pointing
to a file location in the `sorbet-runtime` gem.

`pry-sorbet` automatically fixes the information returned by the `show-source`
(also known as `$`) command to list the correct method source location.

Moreover, an extra entry is added to the header of the method listing, named
`Sorbet`, which displays the method signature if it exists.

**Before:** Incorrect method source, no method signature

```
From: /Users/user/.gem/ruby/2.6.5/gems/sorbet-runtime-0.5.5427/lib/types/private/methods/_methods.rb @ line 208:
Owner: Foo
Visibility: public
Number of lines: 35

T::Private::ClassUtils.replace_method(mod, method_name) do |*args, &blk|
  if !T::Private::Methods.has_sig_block_for_method(new_method)
    # This should only happen if the user used alias_method to grab a handle
    # to the original pre-unwound `sig` method. I guess we'll just proxy the
    # call forever since we don't know who is holding onto this handle to
    # replace it.
```

**After:** Method source and a signature!

```
From: test/test.rb @ line 8:
Owner: Foo
Visibility: public
Sorbet: sig { params(bar: Symbol, baz: Integer).returns(String) }
Number of lines: 3

def foo(bar, baz)
  [baz.to_s, bar.to_s].join(":")
end
```

### Helps with debugging

Because of the same method wrapping, debugging source code that has Sorbet signatures
becomes really painful. When stepping through the code, one always hits code locations
that are in the `sorbet-runtime` library and most of the time it makes people end up
missing the actual method invocation.

`pry-sorbet` adds a Sorbet specific command, `sorbet-unwrap` that can be ran to unwrap
all Sorbet wrapped methods. This allows developers to easily step through their code
without having to deal with the `sorbet-runtime` library.

**Before**

```
$ ruby -I lib -r pry-sorbet test/test.rb

From: test/test.rb @ line 14 :

     4: class Foo
     5:   extend T::Sig
     6:
     7:   sig { params(bar: Symbol, baz: Integer).returns(String) }
     8:   def foo(bar, baz)
     9:     [baz.to_s, bar.to_s].join(":")
    10:   end
    11: end
    12:
    13: binding.pry
 => 14: puts Foo.new.foo(:bar, 1)

[1] pry(main)> step

From: /Users/user/.gem/ruby/2.6.5/gems/sorbet-runtime-0.5.5427/lib/types/private/methods/_methods.rb @ line 209 Foo#foo:

    204:     # which is called only on the *first* invocation.
    205:     # This wrapper is very slow, so it will subsequently re-wrap with a much faster wrapper
    206:     # (or unwrap back to the original method).
    207:     new_method = nil
    208:     T::Private::ClassUtils.replace_method(mod, method_name) do |*args, &blk|
 => 209:       if !T::Private::Methods.has_sig_block_for_method(new_method)
    210:         # This should only happen if the user used alias_method to grab a handle
    211:         # to the original pre-unwound `sig` method. I guess we'll just proxy the
    212:         # call forever since we don't know who is holding onto this handle to
    213:         # replace it.
    214:         new_new_method = mod.instance_method(method_name)
```

**After**

```
$ ruby -I lib -r pry-sorbet test/test.rb

From: test/test.rb @ line 14 :

     4: class Foo
     5:   extend T::Sig
     6:
     7:   sig { params(bar: Symbol, baz: Integer).returns(String) }
     8:   def foo(bar, baz)
     9:     [baz.to_s, bar.to_s].join(":")
    10:   end
    11: end
    12:
    13: binding.pry
 => 14: puts Foo.new.foo(:bar, 1)

[1] pry(main)> sorbet-unwrap
[2] pry(main)> step

From: test/test.rb @ line 9 Foo#foo:

     8: def foo(bar, baz)
 =>  9:   [baz.to_s, bar.to_s].join(":")
    10: end
```

Method unwrapping is not done automatically, you still need to call the `sorbet-unwrap`
command before stepping through code. However, you can make this automatic by adding the
following snippet to your  `~/.pryrc` file:

```ruby
if defined?(PrySorbet)
  Pry.hooks.add_hook(:before_session, "sorbet-unwrap") do |output, binding, pry|
    pry.run_command "sorbet-unwrap"
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AaronC81/pry-sorbet.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
