require 'test_helper'

module ThisWay
  def which_way
    "this way"
  end
end

module ThatWay
  include Casting::Super
  def which_way
    "#{ super_delegate } and that way!"
  end
end

describe Casting, 'modules using delegate_super' do
  it 'call the method from the next delegate with the same arguments' do
    skip 'extending objects not used in this version of Ruby' if test_rebinding_methods?
    client = TestPerson.new.extend(Casting::Client)
    client.delegate_missing_methods
    client.cast_as(ThisWay, ThatWay)

    assert_equal 'this way and that way!', client.which_way
  end
end