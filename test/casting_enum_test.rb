require "test_helper"

class Person
  include Casting::Client
  delegate_missing_methods

  def initialize(name)
    @name = name
  end
  attr_reader :name
end

class PersonCollection
  include Casting::Enum

  def initialize(array)
    @array = array
  end
  attr_reader :array

  def each(*behaviors, &block)
    enum(array, *behaviors).each(&block)
  end
end

module Hello
  def hello
    "Hello, I'm #{name}"
  end
end

describe Casting::Enum, "#enum" do
  let(:people) {
    [Person.new("Jim"), Person.new("TJ"), Person.new("Sandi")]
  }
  it "iterates and applies behaviors to each item" do
    client = PersonCollection.new(people)
    assert_equal ["Hello, I'm Jim", "Hello, I'm TJ", "Hello, I'm Sandi"], client.each(Hello).map(&:hello)
  end
end
