require 'test_helper'
require 'casting'

BlockTestPerson = Struct.new(:name)
BlockTestPerson.send(:include, Casting::Client)
BlockTestPerson.delegate_missing_methods

describe Casting, '.delegating' do
  it 'delegates missing methods for the objects inisde the block' do
    client = BlockTestPerson.new('Jim')
    verbose_client = BlockTestPerson.new('Amy')

    assert_raises(NoMethodError){
      client.greet
    }
    Casting.delegating(client => TestPerson::Greeter, verbose_client => TestPerson::Verbose) do
      assert_equal 'hello', client.greet
      assert_equal 'this,that', verbose_client.verbose('this','that')
    end
    assert_raises(NoMethodError){
      client.greet
    }
  end

  it 'delegates missing methods on altered objects inside the block' do
    client = test_person.extend(Casting::Client)
    client.delegate_missing_methods

    assert_raises(NoMethodError){
      client.greet
    }
    Casting.delegating(client => TestPerson::Greeter) do
      assert_equal 'hello', client.greet
    end
    assert_raises(NoMethodError){
      client.greet
    }
  end
end

describe Casting::Delegation do

  it 'initializes with method name and object' do
    assert Casting::Delegation.new('some_method', Object.new)
  end

  it 'raises an error when calling without an attendant object' do
    delegation = Casting::Delegation.new('some_method', Object.new)
    assert_raises(Casting::MissingAttendant){
      delegation.call
    }
  end

  it 'raises an error when setting an invalid attendant type' do
    delegation = Casting::Delegation.new('some_method', TestPerson.new)
    assert_raises(Casting::InvalidAttendant){
      delegation.to(Unrelated.new)
    }
  end

  it 'sets an attendant to an object of an ancestor class of the object class' do
    attendant = test_person
    client = SubTestPerson.new

    delegation = Casting::Delegation.new('name', client)
    assert delegation.to(attendant)
  end

  it 'delegates when given a module' do
    client = test_person
    delegation = Casting::Delegation.new('greet', client).to(TestPerson::Greeter)
    assert_equal 'hello', delegation.call
  end

  it 'does not delegate when given a class' do
    client = test_person
    assert_raises(TypeError){
      Casting::Delegation.new('class_defined', client).to(Unrelated)
    }
  end

  it 'assigns arguments to the delegated method using with' do
    client = test_person
    attendant = TestPerson.new
    attendant.extend(TestPerson::Verbose)

    delegation = Casting::Delegation.new('verbose', client).to(attendant)

    attendant_output = attendant.verbose('hello', 'goodbye')
    delegation_output = delegation.with('hello', 'goodbye').call

    assert_equal attendant_output, delegation_output
  end
end

describe Casting::Client do
  it 'adds a delegate method to call a method on an attendant' do
    client = TestPerson.new
    client.extend(Casting::Client)
    attendant = TestPerson.new
    attendant.extend(TestPerson::Greeter)
    assert_equal attendant.greet, client.delegate('greet', attendant)
  end

  it 'passes additional parameters to the attendant' do
    client = TestPerson.new
    client.extend(Casting::Client)
    attendant = TestPerson.new
    attendant.extend(TestPerson::Verbose)

    attendant_output = attendant.verbose('hello', 'goodbye')
    client_output = client.delegate('verbose', attendant, 'hello', 'goodbye')

    assert_equal attendant_output, client_output
  end

  it 'passes the object as the client for delegation' do
    client = Object.new
    client.extend(Casting::Client)

    delegation = client.delegation('id')

    assert_equal client, delegation.client
  end
end