require 'test_helper'

describe Casting::Delegation do

  it 'initializes with method name and object' do
    assert Casting::Delegation.prepare('some_method', Object.new)
  end

  it 'raises an error when calling without an attendant object' do
    delegation = Casting::Delegation.prepare('some_method', Object.new)
      begin
        delegation.call
      rescue StandardError => e
      end
    assert_kind_of Casting::MissingAttendant, e
    assert_equal "You must set your attendant object using `to'.", e.message
  end

  it 'raises an error when setting an invalid attendant type' do
    delegation = Casting::Delegation.prepare('some_method', TestPerson.new)
    assert_raises(Casting::InvalidAttendant){
      delegation.to(Unrelated.new)
    }
  end

  it 'raises an error when setting a class as the attendant' do
    delegation = Casting::Delegation.prepare('some_method', TestPerson)
    assert_raises(Casting::InvalidAttendant){
      delegation.to(Unrelated.new)
    }
  end

  it 'sets an attendant to an object of an ancestor class of the object class' do
    attendant = test_person
    client = SubTestPerson.new

    delegation = Casting::Delegation.prepare('name', client)
    assert delegation.to(attendant)
  end

  it 'delegates when given a module' do
    client = test_person
    delegation = Casting::Delegation.prepare('greet', client).to(TestPerson::Greeter)
    assert_equal 'hello', delegation.call
  end

  it 'does not delegate when given a class' do
    client = test_person
    err = expect{
      Casting::Delegation.prepare('class_defined', client).to(Unrelated)
    }.must_raise(TypeError)
    expect(err.message).must_match(/ argument must be a module or an object with/)
  end

  it 'finds the module defining a method and uses it to delegate' do
    client = test_person
    attendant = Unrelated.new
    delegation = Casting::Delegation.prepare('unrelated', client).to(attendant)
    assert_equal attendant.unrelated, delegation.call
  end

  it 'does not delegate to methods defined in classes' do
    client = test_person
    attendant = Unrelated.new
    assert_raises(TypeError){
      Casting::Delegation.prepare('class_defined', client).to(attendant)
    }
  end

  it 'assigns arguments to the delegated method using with' do
    client = test_person
    attendant = TestPerson::Verbose

    delegation = Casting::Delegation.prepare('verbose', client).to(attendant)

    assert_equal 'hello,goodbye', delegation.with('hello', 'goodbye').call
  end

  it 'assigns keyword arguments to the delegated method using with' do
    client = test_person
    attendant = TestPerson::Verbose

    delegation = Casting::Delegation.prepare('verbose_keywords', client).to(attendant)

    assert_equal 'hello,goodbye', delegation.with(key: 'hello', word: 'goodbye').call
  end

  it 'assigns regular and keyword arguments to the delegated method using with' do
    client = test_person
    attendant = TestPerson::Verbose

    delegation = Casting::Delegation.prepare('verbose_multi_args', client).to(attendant)

    assert_equal('hello,goodbye,keys,words,block!', delegation.with('hello', 'goodbye', key: 'keys', word: 'words') do
      "block!"
    end.call)
  end

  it 'prefers `call` arguments over `with`' do
    client = test_person
    attendant = TestPerson::Verbose

    delegation = Casting::Delegation.prepare('verbose', client).to(attendant)

    assert_equal 'call,args', delegation.with('hello', 'goodbye').call('call','args')
  end

  it 'calls a method defined on another object of the same type' do
    client = test_person
    attendant = test_person
    attendant.extend(TestPerson::Greeter)
    delegation = Casting::Delegation.prepare('greet', client).to(attendant)
    assert_equal 'hello', delegation.call
  end

  it 'passes arguments to a delegated method' do
    client = test_person
    attendant = test_person
    attendant.extend(TestPerson::Verbose)
    delegation = Casting::Delegation.prepare('verbose', client).to(attendant).with('arg1','arg2')
    assert_equal 'arg1,arg2', delegation.call
  end

  it 'delegates when given a module' do
    client = test_person
    delegation = Casting::Delegation.prepare('greet', client).to(TestPerson::Greeter)
    assert_equal 'hello', delegation.call
  end

  it 'does not delegate when given a class' do
    client = test_person
    assert_raises(TypeError){
      Casting::Delegation.prepare('class_defined', client).to(Unrelated)
    }
  end
end
