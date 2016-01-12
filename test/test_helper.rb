require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'minitest/autorun'
require 'casting'

BlockTestPerson = Struct.new(:name)
BlockTestPerson.send(:include, Casting::Client)
BlockTestPerson.delegate_missing_methods

class TestPerson
  def name
    'name from TestPerson'
  end

  module Greeter
    def greet
      'hello'
    end

    protected

    def hey; end

    private

    def psst; end
  end

  module Verbose
    def verbose(arg1, arg2)
      [arg1, arg2].join(',')
    end
  end
end

class SubTestPerson < TestPerson
  def sub_method
    'sub'
  end
end

class Unrelated
  module More
    def unrelated
      'unrelated'
    end
  end
  include More

  def class_defined
    'oops!'
  end
end

module Deep
  def nested_deep; end
  protected
  def protected_nested_deep; end
  private
  def private_nested_deep; end
end

module Nested
  include Deep

  def nested; end
  protected
  def protected_nested; end
  private
  def private_nested; end
end

def test_person
  TestPerson.new
end
