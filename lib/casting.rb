require 'redcard'

module Casting

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  class InvalidAttendant < StandardError
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
      @attendant = method_carrier(object_or_module)
      check_valid_type
      self
    end

    def with(*args)
      @arguments = args
      self
    end

    def call
      raise MissingAttendant.new unless @attendant

      if @arguments
        delegated_method.bind(@client).call(*@arguments)
      else
        delegated_method.bind(@client).call
      end
    end

    private

    def check_valid_type
      begin
        !@client.nil? && delegated_method.bind(@client)
      rescue TypeError => e
        raise TypeError.new("`to' argument must be an instance of #{@client.class}")
      end
    end

    def method_carrier(object_or_module)
      if Module === object_or_module
        if RedCard.check '2.0'
          return object_or_module
        else
          @client.clone.extend(object_or_module)
        end
      else
        object_or_module
      end
    end

    def delegated_method
      if Module === @attendant
        @attendant.instance_method(@delegated_method_name)
      else
        @attendant.method(@delegated_method_name).unbind
      end
    rescue NameError => e
      raise InvalidAttendant.new(e.message)
    end
  end
end