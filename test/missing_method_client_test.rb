require 'test_helper'
require 'casting/client'

describe Casting::MissingMethodClient, '#cast_as' do
  def client
    @client ||= test_person.extend(Casting::Client, Casting::MissingMethodClient)
  end

  it "sets the object's delegate for missing methods" do
    client.cast_as(TestPerson::Greeter)
    assert_equal 'hello', client.greet
  end

  it "returns the object for further operation" do
    jim = test_person.extend(Casting::Client, Casting::MissingMethodClient)

    assert_equal 'hello', jim.cast_as(TestPerson::Greeter).greet
  end
end

describe Casting::MissingMethodClient, '#uncast' do
  def client
    @client ||= test_person.extend(Casting::Client, Casting::MissingMethodClient)
  end

  it "removes the last added delegate" do
    client.cast_as(TestPerson::Greeter)
    assert_equal 'hello', client.greet
    client.uncast
    assert_raises(NoMethodError){ client.greet }
  end

  it "maintains any previously added delegates" do
    client.cast_as(TestPerson::Verbose)
    assert_equal 'one,two', client.verbose('one', 'two')
    client.uncast
    assert_raises(NoMethodError){ client.verbose('one', 'two') }
  end

  it "returns the object for further operation" do
    jim = test_person.extend(Casting::Client, Casting::MissingMethodClient)

    assert_equal 'name from TestPerson', jim.uncast.name
  end
end