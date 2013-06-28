require 'test_helper'

describe Casting::MethodConsolidator, '#methods' do
  let(:client){
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient, Casting::MethodConsolidator)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "returns all instance methods including private from the object and it's delegates" do
    assert_includes(client.methods(true), :psst)
  end

  it "returns all public instance methods from the object and it's delegates" do
    refute_includes(client.methods(false), :psst)
  end

  it "returns all protected instance methods from the object and it's delegates" do
    assert_includes(client.methods(true), :hey)
  end
end

describe Casting::MethodConsolidator, '#public_methods' do
  let(:client){
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient, Casting::MethodConsolidator)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "returns all public_methods and those from it's delegates" do
    assert_includes(client.public_methods, :greet)
  end

  it "excludes all protected_methods and those from it's delegates" do
    refute_includes(client.public_methods, :hey)
  end

  it "excludes all private_methods from the object and it's delegates" do
    refute_includes(client.public_methods, :psst)
  end
end

describe Casting::MethodConsolidator, '#protected_methods' do
  let(:client){
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient, Casting::MethodConsolidator)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "excludes all public_methods and those from it's delegates" do
    refute_includes(client.protected_methods, :greet)
  end

  it "returns all protected_methods and those from it's delegates" do
    assert_includes(client.protected_methods, :hey)
  end

  it "excludes all private_methods from the object and it's delegates" do
    refute_includes(client.protected_methods, :psst)
  end
end

describe Casting::MethodConsolidator, '#private_methods' do
  let(:client){
    object = test_person.extend(Casting::Client, Casting::MissingMethodClient, Casting::MethodConsolidator)
    object.cast_as(TestPerson::Greeter)
    object
  }

  it "excludes all public_methods and those from it's delegates" do
    refute_includes(client.private_methods, :greet)
  end

  it "excludes all protected_methods and those from it's delegates" do
    refute_includes(client.private_methods, :hey)
  end

  it "excludes all private_methods from the object and it's delegates" do
    assert_includes(client.private_methods, :psst)
  end
end