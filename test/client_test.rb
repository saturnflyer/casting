require 'test_helper'

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

  it 'executes delegated methods with a block' do
    client = TestPerson.new
    client.extend(Casting::Client)
    mod = Module.new
    mod.module_eval do
      def blocky(arg, &block)
        block.call(arg, self)
      end
    end

    output = client.delegate('blocky', mod, 'argument') do |arg, me|
      %{#{arg} from #{me.name}}
    end

    assert_equal 'argument from name from TestPerson', output
  end

  it 'passes the object as the client for delegation' do
    client = Object.new
    client.extend(Casting::Client)

    delegation = client.delegation('id')

    assert_equal client, delegation.client
  end

  it 'refuses to delegate to itself' do
    client = TestPerson.new
    client.extend(Casting::Client)

    assert_raises(Casting::InvalidAttendant){
      client.delegate('to_s', client)
    }
  end

  it 'does not delegate singleton methods' do
    client = test_person.extend(Casting::Client)
    client.delegate_missing_methods
    attendant = test_person

    def attendant.hello
      'hello'
    end
    assert_raises(TypeError){
      client.delegate('hello', attendant)
    }
  end
end
