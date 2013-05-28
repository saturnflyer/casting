require 'test_helper'

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