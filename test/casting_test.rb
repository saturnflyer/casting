require 'test_helper'
require 'casting'

BlockTestPerson = Struct.new(:name)
BlockTestPerson.send(:include, Casting::Client)
BlockTestPerson.delegate_missing_methods

describe Casting, '.delegating' do
  it 'delegates missing methods for the objects inside the block' do
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

  it 'raises an error if the given object is not an object that delegates missing methods' do
    client = test_person.extend(Casting::Client)

    assert_raises(Casting::InvalidClientError){
      Casting.delegating(client => TestPerson::Greeter){ }
    }
  end

  it 'allows for nested delegating' do
    client = test_person.extend(Casting::Client)
    client.delegate_missing_methods

    Casting.delegating(client => TestPerson::Greeter) do
      assert client.respond_to?(:greet)
      Casting.delegating(client => TestPerson::Verbose) do
        assert client.respond_to?(:greet)
        assert client.respond_to?(:verbose)
      end
      assert !client.respond_to?(:verbose)
    end
    assert !client.respond_to?(:greet)
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
