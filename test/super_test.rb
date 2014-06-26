require 'test_helper'

module AnyWay
  def which_way
    "any way"
  end
end

module ThisWay
  include Casting::SuperDelegate
  def which_way
    "this way or #{super_delegate(ThisWay)}"
  end
end

module ThatWay
  include Casting::SuperDelegate
  def which_way
    "#{ super_delegate } and that way!"
  end
end

describe Casting, 'modules using delegate_super' do
  it 'call the method from the next delegate with the same arguments' do
    client = TestPerson.new.extend(Casting::Client)
    client.delegate_missing_methods
    client.cast_as(AnyWay, ThisWay, ThatWay)

    assert_equal 'this way or any way and that way!', client.which_way
  end
end