require 'test_helper'
require 'casting'

unless RedCard.check '2.0'

describe Casting, '.delegating' do
  it 'delegates missing methods to object delegates' do
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

  # it 'errors with a method defined on another object not of the same module type' do
  #   client = test_person
  #   attendant = test_person
  #   attendant.extend(TestPerson::Greeter)
  #   assert_raises(TypeError){
  #     Casting::Delegation.new('greet', client).to(attendant)
  #   }
  # end

  it 'calls a method defined on another object of the same type' do
    client = test_person
    attendant = test_person
    attendant.extend(TestPerson::Greeter)
    delegation = Casting::Delegation.new('greet', client).to(attendant)
    assert_equal 'hello', delegation.call
  end

  it 'passes arguments to a delegated method' do
    client = test_person
    attendant = test_person
    attendant.extend(TestPerson::Verbose)
    delegation = Casting::Delegation.new('verbose', client).to(attendant).with('arg1','arg2')
    assert_equal 'arg1,arg2', delegation.call
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
end

end # RedCard