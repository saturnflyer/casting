require 'casting/client'

module Casting

  class InvalidClientError < StandardError; end

  def self.delegating(assignments)
    assignments.each do |object, mod|
      cast_object(object, mod)
    end
    yield
  ensure
    assignments.each do |object, mod|
      uncast_object(object)
    end
  end

  def self.cast_object(object, mod)
    raise InvalidClientError.new unless object.is_a?(Casting::MissingMethodClient)
    object.send(:instance_variable_set, :@__previous_delegate__, object.instance_variable_get(:@__current_delegate__))
    object.send(:instance_variable_set, :@__current_delegate__, mod)
  end

  def self.uncast_object(object)
    return unless object.is_a?(Casting::MissingMethodClient)
    object.send(:instance_variable_set, :@__current_delegate__, object.instance_variable_get(:@__previous_delegate__))
    object.send(:remove_instance_variable, :@__previous_delegate__)
  end

end
