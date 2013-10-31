require 'test_helper'

describe Casting, '.delegating' do
  it 'delegates missing methods to object delegates' do
    skip 'extending objects not used in this version of Ruby' if test_rebinding_methods?

    client = test_person
    client.extend(Casting::Client)
    client.delegate_missing_methods

    attendant = test_person
    attendant.extend(TestPerson::Greeter)

    assert_raises(NoMethodError){
      client.greet
    }
    Casting.delegating(client => attendant) do
      assert_equal 'hello', client.greet
    end
    assert_raises(NoMethodError){
      client.greet
    }
  end
end

describe Casting::Delegation do

  it 'calls a method defined on another object of the same type' do
    skip 'extending objects not used in this version of Ruby' if test_rebinding_methods?

    client = test_person
    attendant = test_person
    attendant.extend(TestPerson::Greeter)
    delegation = Casting::Delegation.new('greet', client).to(attendant)
    assert_equal 'hello', delegation.call
  end

  it 'passes arguments to a delegated method' do
    skip 'extending objects not used in this version of Ruby' if test_rebinding_methods?

    client = test_person
    attendant = test_person
    attendant.extend(TestPerson::Verbose)
    delegation = Casting::Delegation.new('verbose', client).to(attendant).with('arg1','arg2')
    assert_equal 'arg1,arg2', delegation.call
  end

  it 'delegates when given a module' do
    skip 'extending objects not used in this version of Ruby' if test_rebinding_methods?

    client = test_person
    delegation = Casting::Delegation.new('greet', client).to(TestPerson::Greeter)
    assert_equal 'hello', delegation.call
  end

  it 'does not delegate when given a class' do
    skip 'extending objects not used in this version of Ruby' if test_rebinding_methods?

    client = test_person
    assert_raises(TypeError){
      Casting::Delegation.new('class_defined', client).to(Unrelated)
    }
  end
end