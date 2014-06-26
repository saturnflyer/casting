require 'test_helper'

describe Casting::Delegation do

  it 'finds the module defining a method and uses it to delegate' do
    client = test_person
    attendant = Unrelated.new
    delegation = Casting::Delegation.new('unrelated', client).to(attendant)
    assert_equal attendant.unrelated, delegation.call
  end

  it 'does not delegate to methods defined in classes' do
    client = test_person
    attendant = Unrelated.new
    assert_raises(TypeError){
      Casting::Delegation.new('class_defined', client).to(attendant)
    }
  end
end