require_relative 'test_helper'
require_relative '../lib/delegation.rb'

class TestPerson
  module Greeter
    def greet
      'hello'
    end
  end

  module Verbose
    def verbose(arg1, arg2)
      %w{arg1 arg2}.join(',')
    end
  end
end

class Unrelated
end

describe Delegation do
  it 'initializes with method name and object' do
    assert Delegation.new('some_method', Object.new)
  end

  it 'raises an error when calling without an attendant object' do
    delegation = Delegation.new('some_method', Object.new)
    assert_raises(Delegation::MissingAttendant){
      delegation.call
    }
  end

  it 'raises an error when setting an invalid attendant type' do
    delegation = Delegation.new('some_method', TestPerson.new)
    assert_raises(ArgumentError){
      delegation.to(Unrelated.new)
    }
  end

  it 'calls a method defined on another object of the same type' do
    client = TestPerson.new
    attendant = TestPerson.new
    attendant.extend(TestPerson::Greeter)
    delegation = Delegation.new('greet', client).to(attendant)
    assert_equal 'hello', delegation.call
  end

  it 'passes arguments to a delegated method' do
    client = TestPerson.new
    attendant = TestPerson.new
    attendant.extend(TestPerson::Verbose)
    delegation = Delegation.new('verbose', client).to(attendant).with('arg1','arg2')
    assert_equal 'arg1,arg2', delegation.call
  end

  it 'delegates when given a module' do
    client = TestPerson.new
    delegation = Delegation.new('greet', client).to(TestPerson::Greeter)
    assert_equal 'hello', delegation.call
  end
end

describe Delegation::Client do
  it 'adds a delegation method to return a Delegation' do
    client = Object.new
    client.extend(Delegation::Client)
    assert_instance_of Delegation, client.delegation('id')
  end
  it 'passes the object as the client for delegation' do
    client = Object.new
    client.extend(Delegation::Client)

    delegation = client.delegation('id')
    assert_equal client, delegation.client
  end
end