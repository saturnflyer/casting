module Casting

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  class InvalidAttendant < StandardError; end

  class Delegation

    def self.prepare(delegated_method_name, client, &block)
      new(delegated_method_name: delegated_method_name, client: client, &block)
    end

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

    def with(*args, **kwargs, &block)
      @arguments = args
      @keyword_arguments = kwargs
      @block = block
      self
    end

    def call(*args, **kwargs, &block)
      raise MissingAttendant.new unless attendant

      call_block = block || @block
      call_args = if args && !args.empty?
        args
      elsif @arguments && !@arguments.empty?
        @arguments
      end
      call_kwargs = if kwargs && !kwargs.empty?
        kwargs
      elsif @keyword_arguments && !@keyword_arguments.empty?
        @keyword_arguments
      end

      if call_block
        if call_args
          if call_kwargs
            bound_method.call(*call_args, **call_kwargs, &call_block)
          else
            bound_method.call(*call_args, &call_block)
          end
        else
          if call_kwargs
            bound_method.call(**call_kwargs, &call_block)
          else
            bound_method.call(&call_block)
          end
        end
      else
        if call_args
          if call_kwargs
            bound_method.call(*call_args, **call_kwargs)
          else
            bound_method.call(*call_args)
          end
        else
          if call_kwargs
            bound_method.call(**call_kwargs)
          else
            bound_method.call
          end
        end
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
