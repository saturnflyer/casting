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
      @keyword_arguments = settings[:keyword_arguments]
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

      call_args = positional_arguments(args)
      call_kwargs = keyword_arguments(kwargs)
      call_block = block_argument(&block)

      case
      when call_args && call_kwargs
        bound_method.call(*call_args, **call_kwargs, &call_block)
      when call_args
        bound_method.call(*call_args, &call_block)
      when call_kwargs
        bound_method.call(**call_kwargs, &call_block)
      else
        bound_method.call(&call_block)
      end
    end

    private

    def block_argument(&block)
      block || @block
    end

    def positional_arguments(options)
      return options unless options.empty?
      @arguments
    end

    def keyword_arguments(options)
      return options unless options.empty?
      @keyword_arguments
    end

    def bound_method
      delegated_method.bind(client)
    rescue TypeError
      raise TypeError.new("`to' argument must be a module or an object with #{delegated_method_name} defined in a module")
    end

    def method_module
      mod = delegated_method.owner
      unless mod.is_a?(Class)
        mod
      end
    end

    def delegated_method
      if Module === attendant
        attendant
      else
        attendant.method(delegated_method_name).owner
      end.instance_method(delegated_method_name)
    rescue NameError => e
      raise InvalidAttendant, e.message
    end
  end
end
