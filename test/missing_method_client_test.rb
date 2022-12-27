require "test_helper"

module One
  def similar
    "from One"
  end
end

module Two
  def similar
    "from Two"
  end
end

describe Casting::MissingMethodClient, "#cast_as" do
  let(:client) {
    test_person.extend(Casting::Client, Casting::MissingMethodClient)
  }

  it "sets the object's delegate for missing methods" do
    client.cast_as(TestPerson::Greeter)
    assert_equal "hello", client.greet
  end

  it "delegates to objects of the same type" do
    # avoid using another client
    client = test_person
    client.extend(TestPerson::Greeter)
    attendant = client.clone
    client.extend(Casting::Client, Casting::MissingMethodClient)

    client.singleton_class.send(:undef_method, :greet)
    client.cast_as(attendant)
    assert_equal "hello", client.greet
  end

  it "raises an error when given the client object" do
    assert_raises(Casting::InvalidAttendant) {
      client.cast_as(client)
    }
  end

  it "returns the object for further operation" do
    jim = test_person.extend(Casting::Client, Casting::MissingMethodClient)

    assert_equal "hello", jim.cast_as(TestPerson::Greeter).greet
  end

  it "delegates methods to the last module added containing the method" do
    jim = test_person.extend(Casting::Client, Casting::MissingMethodClient)

    assert_equal "from Two", jim.cast_as(One, Two).similar
  end
end

describe Casting::MissingMethodClient, "#uncast" do
  let(:client) {
    test_person.extend(Casting::Client, Casting::MissingMethodClient)
  }

  it "removes the last added delegate" do
    client.cast_as(TestPerson::Greeter)
    assert_equal "hello", client.greet
    client.uncast
    assert_raises(NoMethodError) { client.greet }
  end

  it "maintains any previously added delegates" do
    client.cast_as(TestPerson::Verbose)
    assert_equal "one,two", client.verbose("one", "two")
    client.uncast
    assert_raises(NoMethodError) { client.verbose("one", "two") }
  end

  it "returns the object for further operation" do
    jim = test_person.extend(Casting::Client, Casting::MissingMethodClient)

    assert_equal "name from TestPerson", jim.uncast.name
  end

  it "removes the specified number of delegates" do
    jim = test_person.extend(Casting::Client, Casting::MissingMethodClient)
    jim.cast_as(TestPerson::Greeter, TestPerson::Verbose)

    assert_includes(jim.delegated_methods(true), :psst)
    assert_includes(jim.delegated_methods(true), :verbose)

    jim.uncast(2)

    refute_includes(jim.delegated_methods(true), :psst)
    refute_includes(jim.delegated_methods(true), :verbose)
  end
end

describe Casting::MissingMethodClient, "#delegated_methods" do
  let(:client) {
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "returns all instance methods including private from the object's delegates" do
    assert_includes(client.delegated_methods(true), :psst)
  end

  it "returns all public instance methods from the object and it's delegates" do
    refute_includes(client.delegated_methods(false), :psst)
  end

  it "returns all protected instance methods from the object and it's delegates" do
    assert_includes(client.delegated_methods(true), :hey)
  end
end

describe Casting::MissingMethodClient, "#delegated_public_methods" do
  let(:client) {
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "returns all public methods from the object's delegates" do
    assert_includes(client.delegated_public_methods, :greet)
  end

  it "excludes all private  methods from the object's delegates" do
    refute_includes(client.delegated_public_methods, :psst)
  end

  it "excludes all protected methods from the object's delegates" do
    refute_includes(client.delegated_public_methods, :hey)
  end

  it "includes methods from superclasses" do
    client.cast_as(Nested)
    assert_includes(client.delegated_public_methods(true), :nested_deep)
  end

  it "excludes methods from superclasses" do
    client.cast_as(Nested)
    refute_includes(client.delegated_public_methods(false), :nested_deep)
  end
end

describe Casting::MissingMethodClient, "#delegated_protected_methods" do
  let(:client) {
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "excludes all public methods from the object's delegates" do
    refute_includes(client.delegated_protected_methods, :greet)
  end

  it "excludes all private  methods from the object's delegates" do
    refute_includes(client.delegated_protected_methods, :psst)
  end

  it "includes all protected methods from the object's delegates" do
    assert_includes(client.delegated_protected_methods, :hey)
  end

  it "includes methods from superclasses" do
    client.cast_as(Nested)
    assert_includes(client.delegated_protected_methods(true), :protected_nested_deep)
  end

  it "excludes methods from superclasses" do
    client.cast_as(Nested)
    refute_includes(client.delegated_protected_methods(false), :protected_nested_deep)
  end
end

describe Casting::MissingMethodClient, "#delegated_private_methods" do
  let(:client) {
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "excludes all public methods from the object's delegates" do
    refute_includes(client.delegated_private_methods, :greet)
  end

  it "includes all private  methods from the object's delegates" do
    assert_includes(client.delegated_private_methods, :psst)
  end

  it "excludes all protected methods from the object's delegates" do
    refute_includes(client.delegated_private_methods, :hey)
  end

  it "includes methods from superclasses" do
    client.cast_as(Nested)
    assert_includes(client.delegated_private_methods(true), :private_nested_deep)
  end

  it "excludes methods from superclasses" do
    client.cast_as(Nested)
    refute_includes(client.delegated_private_methods(false), :private_nested_deep)
  end
end
