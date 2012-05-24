# Delegation

To use proper delegation, your approach should preserve `self` as a reference 
to the original object receiving a method.

The Ruby standard library includes a library called "delegate", but it is
a forwarding approach. With that "delegate", all messages are forwarded to 
another object.

With Delegation, your defined methods may reference `self` and during 
execution it will refer to the original client object.

## Installation

If you are using Bundler, add this line to your application's Gemfile:

    gem 'delegation'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delegation

## Usage

To use Delegation, you must first extend an object as the delegation client:

    actor = Object.new
    actor.exend(Delegation::Client)

Or you may include the module in a particular class:

    class Actor
      include Delegation::Client
    end
    actor = Actor.new

Then you may delegate methods to an attendant object:

    actor.delegate(:hello_world).to(other_actor).call

You may also delegate methods without an explicit attendant, but provide
a module containing the behavior you need to use:

    actor.delegate(:hello_world).to(GreetingModule).call

If your delegated method requires arguments, pass them using `with`:

    actor.delegate(:verbose_method).to(another_actor).with(arg1, arg2).call

## What's happening when I use this?

Ruby allows you to access methods as objects and pass them around just like any other object.

For example, if you want a method from an class you may do this:

    class Person
      def hello
        "hello"
      end
    end
    Person.instance_method(:hello) #=> #<UnboundMethod: Person#hello>

But if you attempt to use that `UnboundMethod` on an object that is not a `Person` you'll get
an error about a type mismatch.

Delegation will bind an unbound method to a client object and execute the method as though it is 
defined on the client object.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Built by Jim Gay at [Saturn Flyer](http://www.saturnflyer.com)