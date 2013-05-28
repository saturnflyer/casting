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

    delegate_collection = object.send(:instance_variable_get, :@__delegates__).to_a
    delegate_collection.unshift(mod)

    object.send(:instance_variable_set, :@__delegates__, delegate_collection)

    object.send(:instance_variable_set, :@__current_delegate__, mod)
  end

  def self.uncast_object(object)
    return unless object.is_a?(Casting::MissingMethodClient)

    delegate_collection = object.send(:instance_variable_get, :@__delegates__).to_a
    delegate_collection.shift

    object.send(:instance_variable_set, :@__delegates__, delegate_collection)

    object.send(:instance_variable_set, :@__current_delegate__, delegate_collection.first)
  end

end
