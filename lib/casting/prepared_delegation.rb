# Some features are only available in versions of Ruby
# where this method is true
unless defined?(self.module_method_rebinding?)
  def module_method_rebinding?
    return @__module_method_rebinding__ if defined?(@__module_method_rebinding__)
    sample_method = Enumerable.instance_method(:to_a)
    @__module_method_rebinding__ = begin
      !!sample_method.bind(Object.new)
    rescue TypeError
      false
    end
  end
end

module Casting

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  class InvalidAttendant < StandardError; end

  class PreparedDelegation

    attr_reader :client
    attr_reader :delegated_method_name, :attendant, :arguments, :block
    private :delegated_method_name, :attendant, :arguments, :block

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
        raise unless module_method_rebinding?
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

      if arguments
        delegated_method.bind(client).call(*arguments, &block)
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
        if module_method_rebinding?
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