require 'test_helper'

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