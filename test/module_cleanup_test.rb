require 'test_helper'

module Cleaner
  def self.uncast_object(object)
    object.remove_instance_variable(:@cleaner_message)
  end
  
  def self.cast_object(object)
    object.instance_variable_set(:@cleaner_message, "#{object.name} will be cleaned up")
  end
  
  def cleaner_message
    @cleaner_message
  end
end

class CleanupPerson
  include Casting::Client
  delegate_missing_methods
  attr_accessor :name
end

describe 'modules with setup tasks' do
  it 'allows modules to setup an object when cast_as' do
    jim = CleanupPerson.new
    jim.name = 'Jim'
    jim.cast_as(Cleaner)
    assert_equal "Jim will be cleaned up", jim.cleaner_message
    assert_equal "Jim will be cleaned up", jim.instance_variable_get(:@cleaner_message)
  end
end

describe 'modules with cleanup tasks' do
  it 'allows modules to cleanup their required attributes when uncast' do
    jim = CleanupPerson.new
    jim.name = 'Jim'
    jim.cast_as(Cleaner)
    assert_equal "Jim will be cleaned up", jim.cleaner_message
    assert_equal "Jim will be cleaned up", jim.instance_variable_get(:@cleaner_message)
    jim.uncast
    refute jim.instance_variable_defined?(:@cleaner_message)
  end
end