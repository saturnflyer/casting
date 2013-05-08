require 'test_helper'
require 'casting'

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

  # it 'errors with a method defined on another object not of the same module type' do
  #   client = test_person
  #   attendant = test_person
  #   attendant.extend(TestPerson::Greeter)
  #   assert_raises(TypeError){
  #     Casting::Delegation.new('greet', client).to(attendant)
  #   }
  # end

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