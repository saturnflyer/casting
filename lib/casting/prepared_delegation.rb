require 'redcard'

module Casting

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  class InvalidAttendant < StandardError; end

  class PreparedDelegation

    attr_reader :client
    attr_reader :delegated_method_name, :attendant, :arguments
    private :delegated_method_name, :attendant, :arguments

    def initialize(settings)
      @delegated_method_name = settings[:delegated_method_name]
      @client = settings[:client]
      @attendant = settings[:attendant]
      @arguments = settings[:arguments]
    end

    def to(object_or_module)
      @attendant = method_carrier(object_or_module)
      begin
        check_valid_type
      rescue TypeError
        raise unless RedCard.check '2.0'
        @attendant = method_module || raise
      end
      self
    end

    def with(*args)
      @arguments = args
      self
    end

    def call(*args)
      @arguments = args unless args.empty?
      raise MissingAttendant.new unless attendant

      if arguments
        delegated_method.bind(client).call(*arguments)
      else
        delegated_method.bind(client).call
      end
    end

    private

    def check_valid_type
      begin
        !client.nil? && delegated_method.bind(client)
      rescue TypeError
        raise TypeError.new("`to' argument must be a module or an instance of #{client.class}")
      end
    end

    def method_carrier(object_or_module)
      if Module === object_or_module
        if RedCard.check '2.0'
          object_or_module
        else
          client.clone.extend(object_or_module)
        end
      else
        object_or_module
      end
    end

    def method_module
      delegated_method.owner unless delegated_method.owner.is_a?(Class)
    end

    def delegated_method
      if Module === attendant
        attendant.instance_method(delegated_method_name)
      else
        attendant.method(delegated_method_name).unbind
      end
    rescue NameError => e
      raise InvalidAttendant.new(e.message)
    end

  end
end