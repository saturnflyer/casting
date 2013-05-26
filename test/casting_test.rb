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

  it 'responds to added methods inside the block' do
    client = test_person.extend(Casting::Client)
    client.delegate_missing_methods

    assert !client.respond_to?(:greet)

    Casting.delegating(client => TestPerson::Greeter) do
      assert client.respond_to?(:greet)
    end

    assert !client.respond_to?(:greet)
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
    attendant = TestPerson::Verbose

    delegation = Casting::Delegation.new('verbose', client).to(attendant)

    assert_equal 'hello,goodbye', delegation.with('hello', 'goodbye').call
  end

  it 'prefers `call` arguments over `with`' do
    client = test_person
    attendant = TestPerson::Verbose

    delegation = Casting::Delegation.new('verbose', client).to(attendant)

    assert_equal 'call,args', delegation.with('hello', 'goodbye').call('call','args')
  end
end

describe Casting::Client do
  it 'will not override an existing `delegate` method' do
    client = TestPerson.new
    def client.delegate
      'existing delegate method'
    end
    client.extend(Casting::Client)

    attendant = TestPerson::Greeter

    assert_equal 'existing delegate method', client.delegate

    assert_equal 'hello', client.cast('greet', attendant)
  end

  it 'adds a delegate method to call a method on an attendant' do
    client = TestPerson.new
    client.extend(Casting::Client)
    attendant = TestPerson::Greeter

    assert_equal 'hello', client.delegate('greet', attendant)
  end

  it 'passes additional parameters to the attendant' do
    client = TestPerson.new
    client.extend(Casting::Client)
    attendant = TestPerson::Verbose

    assert_equal 'hello,goodbye', client.delegate('verbose', attendant, 'hello', 'goodbye')
  end

  it 'passes the object as the client for delegation' do
    client = Object.new
    client.extend(Casting::Client)

    delegation = client.delegation('id')

    assert_equal client, delegation.client
  end
end