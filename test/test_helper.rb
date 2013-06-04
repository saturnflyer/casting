require 'simplecov'
SimpleCov.start do
  add_filter 'test'
end

require 'coveralls'
Coveralls.wear!

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

def test_person
  TestPerson.new
end
