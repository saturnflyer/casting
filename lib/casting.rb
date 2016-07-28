require 'casting/client'
require 'casting/super_delegate'
require 'casting/null'
require 'casting/context'

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
    raise InvalidClientError.new unless object.respond_to?(:cast_as)

    object.cast_as(mod)
  end

  def self.uncast_object(object)
    return unless object.respond_to?(:uncast)

    object.uncast
  end

end
