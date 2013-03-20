module Casting

  VERSION = '0.2.1'

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  module Client
    def delegation(delegated_method_name)
      Casting::Delegation.new(delegated_method_name, self)
    end

    def delegate(delegated_method_name, attendant, *args)
      delegation(delegated_method_name).to(attendant).with(*args).call
    end
  end

  class Delegation

    attr_reader :client

    def initialize(delegated_method_name, client)
      @delegated_method_name = delegated_method_name
      @client = client
    end

    def to(object_or_module)
      case
      when Module === object_or_module then
        @attendant = @client.clone.extend(object_or_module)
      when !(@client.is_a? object_or_module.class) then
        raise TypeError.new("#{__method__} argument must be an instance of #{@client.class}")
      else
        @attendant = object_or_module
      end

      self
    end

    def with(*args)
      @arguments = args
      self
    end

    def call
      raise MissingAttendant.new unless @attendant

      delegated_method = @attendant.method(@delegated_method_name).unbind

      if @arguments
        delegated_method.bind(@client).call(*@arguments)
      else
        delegated_method.bind(@client).call
      end
    end
  end
end