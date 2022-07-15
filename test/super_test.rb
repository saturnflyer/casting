require 'test_helper'

module AnyWay
  def which_way
    "any way"
  end
  def way_with_args(one, two, &block)
    [one, two, block&.call].compact.inspect
  end
  def way_with_keyword_args(one:, two:, &block)
    [one, two, block&.call].compact.inspect
  end
end

module ThisWay
  include Casting::SuperDelegate
  def which_way
    "this way or #{super_delegate(ThisWay)}"
  end
  def way_with_args(one, two, &block)
    [one, two, block&.call].compact.inspect
  end
  def way_with_keyword_args(one:, two:, &block)
    [one, two, block&.call].compact.inspect
  end
  def no_super
    super_delegate
  end
end

module ThatWay
  include Casting::SuperDelegate
  def which_way
    "#{ super_delegate(ThatWay) } and that way!"
  end
  def way_with_args(one, two, &block)
    super_delegate(one, two, block&.call).compact
  end
  def way_with_keyword_args(one:, two:, &block)
    [one, two, block&.call].compact.inspect
  end
end

describe Casting, 'modules using delegate_super' do
  it 'call the method from the next delegate with the same arguments' do
    client = TestPerson.new.extend(Casting::Client)
    client.delegate_missing_methods
    client.cast_as(AnyWay, ThatWay, ThisWay)

    assert_equal 'this way or any way and that way!', client.which_way
  end

  it 'passes arguments' do
    client = TestPerson.new.extend(Casting::Client)
    client.delegate_missing_methods
    client.cast_as(ThatWay, ThisWay)

    assert_equal %{["first", "second", "block"]}, client.way_with_args('first', 'second'){ 'block' }
  end

  it 'passes keyword arguments' do
    client = TestPerson.new.extend(Casting::Client)
    client.delegate_missing_methods
    client.cast_as(ThatWay, ThisWay)

    assert_equal %{["first", "second", "block"]}, client.way_with_keyword_args(one: 'first', two: 'second'){ 'block' }
  end

  it 'raises an error when method is not defined' do
    client = TestPerson.new.extend(Casting::Client)
    client.delegate_missing_methods
    client.cast_as(ThisWay)

    err = expect{
      client.no_super
    }.must_raise(NoMethodError)

    expect(err.message).must_match(/super_delegate: no delegate method \`no_super' for \#<TestPerson:\dx[a-z0-9]*> from ThisWay/)
  end
end
