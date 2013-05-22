# Casting

[![Build Status](https://travis-ci.org/saturnflyer/casting.png?branch=master)](https://travis-ci.org/saturnflyer/casting)
[![Code Climate](https://codeclimate.com/github/saturnflyer/casting.png)](https://codeclimate.com/github/saturnflyer/casting)

To use proper delegation, your approach should preserve `self` as a reference
to the original object receiving a method. When the object receiving the forwarded
message has its own and separate notion of `self`, the pattern is consultation.

The Ruby standard library includes a library called "delegate", but it is
a consultation approach. With that "delegate", all messages are forwarded to
another object, but the attendant object maintains its own identity.

With Casting, your defined methods may reference `self` and during
execution it will refer to the original client object.

## Supported Rubies

- MRI: 2.0, 1.9.3
- JRuby: 1.9 mode, 1.8 mode
- Rubinius: none
- Maglev: ?
- REE: none

## Usage

To use Casting, you must first extend an object as the delegation client:

```ruby
actor = Object.new
actor.extend(Casting::Client)
```

Or you may include the module in a particular class:

```ruby
class Actor
  include Casting::Client
end
actor = Actor.new
```

Your objects will have two additional methods: `delegation` and `delegate`.
Then you may delegate a method to an attendant object:

```ruby
actor.delegate(:hello_world, other_actor)
```

Or you may create an object to manage the delegation of methods to an attendant object:

```ruby
actor.delegation(:hello_world).to(other_actor).call
```

You may also delegate methods without an explicit attendant, but provide
a module containing the behavior you need to use:

```ruby
actor.delegate(:hello_world, GreetingModule)
# or
actor.delegation(:hello_world).to(GreetingModule).call
```

If your delegated method requires arguments, add them to the end of your `delagate` call:

```ruby
actor.delegate(:verbose_method, another_actor, arg1, arg2)
```

Or pass them to your delegation using `with`:

```ruby
actor.delegation(:verbose_method).to(another_actor).with(arg1, arg2).call
```

## Temporary Behavior

Casting also provides an option to temporarily apply behaviors to an object.

Once your class or object is a `Casting::Client` you may send the `delegate_missing_methods` message to it and your object will use `method_missing` to delegate methods to a stored attendant.

```
  actor.hello_world #=> NoMethodError

  Casting.delegating(actor => GreetingModule) do
    actor.hello_world #=> output the value / perform the method
  end

  actor.hello_world #=> NoMethodError
```

Before the block is run in `Casting.delegating`, the `@__current_delegate__` is set on the object to the provided attendant. Then the block yields, and an `ensure` block cleans up the stored attendant.

Currently, by using `delegate_missing_methods` you forever mark that object or class to use `method_missing`. This may change in the future.

## What's happening when I use this?

Ruby allows you to access methods as objects and pass them around just like any other object.

For example, if you want a method from a class you may do this:

```ruby
class Person
  def hello
    "hello"
  end
end
Person.new.method(:hello).unbind #=> #<UnboundMethod: Person#hello>
# or
Person.instance_method(:hello) #=> #<UnboundMethod: Person#hello>
```

But if you attempt to use that `UnboundMethod` on an object that is not a `Person` you'll get
an error about a type mismatch.

Casting will bind an unbound method to a client object and execute the method as though it is
defined on the client object. Any reference to `self` from the method block will refer to the
client object.

This behavior is different in Ruby 1.9 vs. 2.x.

According to [http://rubyspec.org](http://rubyspec.org) the behavior in MRI in 1.9 that allows this to happen is incorrect. In MRI (and JRuby) 1.9 you may unbind methods from an object that has been extended with a module, and bind them to another object of the same type that has *not* been extended with that module.

Casting uses this as a way to trick the interpreter into using the method where we want it and avoid forever extending the object of concern.

This changed in Ruby 2.0 and does not work. What does work (and is so much better) in 2.0 is that you may take any method from a module and apply it to any object. This means that Casting doesn't have to perform any tricks to temporarily apply behavior to an object.

For example, this fails in 1.9, but works in 2.0:

    GreetingModule.instance_method(:hello_world).bind(actor).call

Casting provides a convenience for doing this.

## Installation

If you are using Bundler, add this line to your application's Gemfile:

    gem 'casting'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install casting

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Built by Jim Gay at [Saturn Flyer](http://www.saturnflyer.com)
