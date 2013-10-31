require 'test_helper'

describe Casting::Delegation do

  it 'finds the module defining a method and uses it to delegate' do
    skip 'not able to bind module methods in this version of Ruby' unless test_rebinding_methods?

    client = test_person
    attendant = Unrelated.new
    delegation = Casting::Delegation.new('unrelated', client).to(attendant)
    assert_equal attendant.unrelated, delegation.call
  end

  it 'does not delegate to methods defined in classes' do
    skip 'not able to bind module methods in this version of Ruby' unless test_rebinding_methods?

    client = test_person
    attendant = Unrelated.new
    assert_raises(TypeError){
      Casting::Delegation.new('class_defined', client).to(attendant)
    }
  end
end