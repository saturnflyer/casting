require 'test_helper'

describe Casting::MissingMethodClient, '#cast_as' do
  let(:client){
    test_person.extend(Casting::Client, Casting::MissingMethodClient)
  }

  it "sets the object's delegate for missing methods" do
    client.cast_as(TestPerson::Greeter)
    assert_equal 'hello', client.greet
  end

  it "delegates to objects of the same type" do
    client.extend(TestPerson::Greeter)
    attendant = client.clone
    client.singleton_class.send(:undef_method, :greet)
    client.cast_as(attendant)
    assert_equal 'hello', client.greet
  end

  it "returns the object for further operation" do
    jim = test_person.extend(Casting::Client, Casting::MissingMethodClient)

    assert_equal 'hello', jim.cast_as(TestPerson::Greeter).greet
  end
end

describe Casting::MissingMethodClient, '#uncast' do
  let(:client){
    test_person.extend(Casting::Client, Casting::MissingMethodClient)
  }

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