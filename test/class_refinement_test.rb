require 'test_helper'

ClassDelegatingPerson = Struct.new(:name)
ClassDelegatingPerson.send(:include, Casting::Client)
ClassDelegatingPerson.delegate_missing_methods :class

InstanceDelegatingPerson = Struct.new(:name)
InstanceDelegatingPerson.send(:include, Casting::Client)
InstanceDelegatingPerson.delegate_missing_methods :instance

ClassThenInstanceDelegatingPerson = Struct.new(:name)
ClassThenInstanceDelegatingPerson.send(:include, Casting::Client)
ClassThenInstanceDelegatingPerson.delegate_missing_methods :class, :instance

InstanceThenClassDelegatingPerson = Struct.new(:name)
InstanceThenClassDelegatingPerson.send(:include, Casting::Client)
InstanceThenClassDelegatingPerson.delegate_missing_methods :instance, :class

module ClassGreeter
  def greet
    'hello from the class delegate'
  end

  def class_greeting
    'Hi!'
  end
end

module InstanceGreeter
  def greet
    'hello from the instance delegate'
  end

  def instance_greeting
    'hi!'
  end
end

describe Casting, '.delegating' do
  it 'delegates methods for all instances to a class delegate inside a block' do
    jim = ClassDelegatingPerson.new('Jim')
    amy = ClassDelegatingPerson.new('Amy')

    assert_raises(NoMethodError){
      jim.greet
    }
    Casting.delegating(ClassDelegatingPerson => TestPerson::Greeter) do
      assert_equal 'hello', jim.greet
      assert_equal 'hello', amy.greet
    end
    assert_raises(NoMethodError){
      jim.greet
    }
  end

  it 'delegates methods for given instances to an instance delegate inside a block' do
    jim = InstanceDelegatingPerson.new('Jim')
    amy = InstanceDelegatingPerson.new('Amy')

    assert_raises(NoMethodError){
      jim.greet
    }
    Casting.delegating(jim => TestPerson::Greeter) do
      assert_equal 'hello', jim.greet
      assert_raises(NoMethodError){ amy.greet }
    end
    assert_raises(NoMethodError){
      jim.greet
    }
  end

  it 'delegates first to class delegates, then to instance delegates inside a block' do
    jim = ClassThenInstanceDelegatingPerson.new('Jim')
    amy = ClassThenInstanceDelegatingPerson.new('Amy')

    assert_raises(NoMethodError){
      jim.greet
    }
    Casting.delegating(ClassThenInstanceDelegatingPerson => ClassGreeter, jim => InstanceGreeter) do
      assert_equal 'hello from the class delegate', jim.greet
      assert_equal 'hi!', jim.instance_greeting
      assert_equal 'hello from the class delegate', amy.greet
      assert(NoMethodError){ amy.instance_greeting }
    end
    assert_raises(NoMethodError){
      jim.greet
    }
  end

  it 'delegates first to instance delegates, then to class delegates inside a block' do
    jim = InstanceThenClassDelegatingPerson.new('Jim')
    amy = InstanceThenClassDelegatingPerson.new('Amy')

    assert_raises(NoMethodError){
      jim.greet
    }
    Casting.delegating(InstanceThenClassDelegatingPerson => ClassGreeter, jim => InstanceGreeter) do
      assert_equal 'hello from the instance delegate', jim.greet
      assert_equal 'hi!', jim.instance_greeting
      assert_equal 'hello from the class delegate', amy.greet
      assert(NoMethodError){ amy.instance_greeting }
    end
    assert_raises(NoMethodError){
      jim.greet
    }
  end

  it 'sets instances to respond_to? class delegate methods' do
    jim = ClassDelegatingPerson.new('Jim')

    refute jim.respond_to?(:greet)

    Casting.delegating(ClassDelegatingPerson => ClassGreeter) do
      assert jim.respond_to?(:greet)
    end

    refute jim.respond_to?(:greet)
  end
end