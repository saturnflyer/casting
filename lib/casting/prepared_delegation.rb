module Casting

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  class InvalidAttendant < StandardError; end

  class PreparedDelegation

    attr_accessor :client, :delegated_method_name, :attendant, :arguments, :block
    private :block

    def initialize(**settings, &block)
      @delegated_method_name = settings[:delegated_method_name]
      @client = settings[:client]
      @attendant = settings[:attendant]
      @arguments = settings[:arguments]
      @block = block
    end

    def to(object_or_module)
      @attendant = object_or_module
      begin
        bound_method
      rescue TypeError
        @attendant = method_module || raise
      end
      self
    end

    def with(*args, &block)
      @arguments = args
      @block = block
      self
    end

    def call(*args)
      @arguments = args unless args.empty?
      raise MissingAttendant.new unless attendant

      if !Array(arguments).empty?
        bound_method.call(*arguments, &block)
      else
        bound_method.call
      end
    end

    private

    def bound_method
      begin
        delegated_method.bind(client)
      rescue TypeError
        raise TypeError.new("`to' argument must be a module or an object with #{delegated_method_name} defined in a module")
      end
    end

    def method_module
      mod = delegated_method.owner
      unless mod.is_a?(Class)
        mod
      end
    end

    def delegated_method
      if Module === attendant
        attendant.instance_method(delegated_method_name)
      else
        attendant.method(delegated_method_name).owner.instance_method(delegated_method_name)
      end
    rescue NameError => e
      raise InvalidAttendant.new(e.message)
    end

  end
end