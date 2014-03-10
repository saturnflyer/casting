# Casting

[![Build Status](https://travis-ci.org/saturnflyer/casting.png?branch=master)](https://travis-ci.org/saturnflyer/casting)
[![Code Climate](https://codeclimate.com/github/saturnflyer/casting.png)](https://codeclimate.com/github/saturnflyer/casting)
[![Coverage Status](https://coveralls.io/repos/saturnflyer/casting/badge.png)](https://coveralls.io/r/saturnflyer/casting)
[![Gem Version](https://badge.fury.io/rb/casting.png)](http://badge.fury.io/rb/casting)

## Add behavior to your objects without using extend
Do it for the life of the object or only for the life of a block of code.

Casting gives you real delegation that flattens your object structure compared to libraries
like Delegate or Forwardable. With casting, you can implement your own decorators that
will be so much simpler than using wrappers.

Here's a quick example that you might try in a Rails project:

```ruby
# implement a module that contains information for the request response
# and apply it to an object in your system.
def show
  respond_with user.cast_as(UserRepresenter)
end
```

To use proper delegation, your approach should preserve `self` as a reference
to the original object receiving a method. When the object receiving the forwarded
message has its own and separate notion of `self`, you're working with a wrapper (also called
consultation) and not using delegation.

The Ruby standard library includes a library called "delegate", but it is
a consultation approach. With that "delegate", all messages are forwarded to
another object, but the attendant object maintains its own identity.

With Casting, your defined methods may reference `self` and during
execution it will refer to the original client object.

Casting was created while exploring ideas for [cleaning up ruby programs](http://clean-ruby.com).

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

Your objects will have a few additional methods: `delegation`, `cast`, and if you do not *already* have it defined (from another library, for example): `delegate`. The `delegate` method is aliased to `cast`.

Then you may delegate a method to an attendant object:

```ruby
actor.delegate(:hello_world, other_actor)
```

Or you may create an object to manage the delegation of methods to an attendant object:

```ruby
actor.delegation(:hello_world).to(other_actor).call
```

You may also delegate methods without an explicit attendant instance, but provide
a module containing the behavior you need to use:

```ruby
actor.delegate(:hello_world, GreetingModule)
# or
actor.delegation(:hello_world).to(GreetingModule).call
```

Pass arguments to your delegated method:

```ruby
actor.delegate(:verbose_method, another_actor, arg1, arg2)

actor.delegation(:verbose_method).to(another_actor).with(arg1, arg2).call

actor.delegation(:verbose_method).to(another_actor).call(arg1, arg2)
```

_That's great, but why do I need to do these extra steps? I just want to run the method._

Casting gives you the option to do what you want. You can run just a single method once, or alter your object to always delegate. Even better, you can alter your object to delegate temporarily...

## Temporary Behavior

Casting also provides an option to temporarily apply behaviors to an object.

Once your class or object is a `Casting::Client` you may send the `delegate_missing_methods` message to it and your object will use `method_missing` to delegate methods to a stored attendant.

```ruby
actor.hello_world #=> NoMethodError

Casting.delegating(actor => GreetingModule) do
  actor.hello_world #=> output the value / perform the method
end

actor.hello_world #=> NoMethodError
```

The use of `method_missing` is opt-in. If you don't want that mucking up your method calls, just don't tell it to `delegate_missing_methods`.

Before the block is run in `Casting.delegating`, a collection of delegate objects is set on the object to the provided attendant. Then the block yields, and an `ensure` block cleans up the stored attendant.

This allows you to nest your `delegating` blocks as well:

```ruby
actor.hello_world #=> NoMethodError

Casting.delegating(actor => GreetingModule) do
  actor.hello_world #=> output the value / perform the method

  Casting.delegating(actor => OtherModule) do
    actor.hello_world #=> still works!
    actor.other_method # values/operations from the OtherModule
  end

  actor.other_method #=> NoMethodError
  actor.hello_world #=> still works!
end

actor.hello_world #=> NoMethodError
```

Currently, by using `delegate_missing_methods` you forever mark that object or class to use `method_missing`. This may change in the future.

### Manual Delegate Management

If you'd rather not wrap things in the `delegating` block, you can control the delegation yourself.
For example, you can `cast_as` and `uncast` an object with a given module:

```ruby
actor.cast_as(GreetingModule)
actor.hello_world # all subsequent calls to this method run from the module
actor.uncast # manually cleanup the delegate
actor.hello_world # => NoMethodError
```

These methods are only defined on your `Casting::Client` object when you tell it to `delegate_missing_methods`. Because these require `method_missing`, they do not exist until you opt-in.

## I have a Rails app, how does this help me?

Well, a common use for this behavior would be in using decorators.

When using a wrapper, your forms can behave unexpectedly

```ruby
class UsersController
  def edit
    @user = UserDecorator.new(User.find(params[:id]))
  end
end

<%= form_for(@user) do |f| %> #=> <form action="/user_decorators/1">
```

Ruby allows you to hack this by defining the `class` method:

```ruby
class UserDecorator
  def class
    User
  end
end
```

That would solve the problem, and it works! But having an object report that
its class is something other than what it actually is can be confusing
when you're debugging.

Instead, you could cast the object as a module and your form will generate properly:

```ruby
class UsersController
  def edit
    @user = User.find(params[:id]).cast_as(UserDecorator) # as a module
  end
end

<%= form_for(@user) do |f| %> #=> <form action="/users/1">
```

This keeps your code focused on the object you care about.

## Oh, my! Could this be used to add behavior like refinements?

You can apply methods from a delegate to all instances of a class.

```ruby
person.hello_world #=> NoMethodError

Casting.delegating(Person => GreetingModule) do
  person.hello_world #=> output the value / perform the method
end

person.hello_world #=> NoMethodError
```

By default, the `delegate_missing_methods` method will set delegates on instances so you'll need to opt-in for this.

```ruby
class Person
  include Casting::Client
  delegate_missing_methods :class
end
```

_But what happens when you have method clashes or want a specific instance to behave differently?_

You can have your objects look to their instance delegates, their class delegates, or in a particular order:

```ruby
class Person
  include Casting::Client
  # default delegation to instances
  delegate_missing_methods

  # delegate methods to those defined on the class
  delegate_missing_methods :class

  # delegate methods to those defined on the class, then those defined on the instance
  delegate_missing_methods :class, :instance

  # delegate methods to those defined on the instance, then those defined on the class
  delegate_missing_methods :instance, :class
end
```

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

```ruby
GreetingModule.instance_method(:hello_world).bind(actor).call
```

Casting provides a convenience for doing this.

## What if my modules create instance variables on the object? Can I clean them up?

Yup.

If you need to set some variables so that your module can access them, it's as easy as defining `cast_object` and `uncast_object` on your module. Here's an example:

```ruby
module Special
  def self.cast_object(obj)
    obj.instance_variable_set(:@special_value, 'this is special!')
  end
  
  def self.uncast_object(obj)
    obj.remove_instance_variable(:@special_value)
  end
  
  def special_behavior
    "#{self.name} thinks... #{@special_value}"
  end
end

object.cast_as(Special)
object.special_method
object.uncast
# object no longer has the @special_value instance variable
```

You'll be able to leave your objects as if they were never touched by the module where you defined your behavior.

## Installation

If you are using Bundler, add this line to your application's Gemfile:

```ruby
gem 'casting'
```

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
