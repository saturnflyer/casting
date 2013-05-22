require 'redcard'

module Casting

  def self.delegating(assignments)
    assignments.each do |object, mod|
      object.send(:instance_variable_set, :@__previous_delegate__, object.instance_variable_get(:@__current_delegate__))
      object.send(:instance_variable_set, :@__current_delegate__, mod)
    end
    yield
  ensure
    assignments.each do |object, mod|
      object.send(:instance_variable_set, :@__current_delegate__, object.instance_variable_get(:@__previous_delegate__))
      object.send(:remove_instance_variable, :@__previous_delegate__)
    end
  end

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  class InvalidAttendant < StandardError
  end

  module Client

    def self.included(base)
      def base.delegate_missing_methods
        self.send(:include, ::Casting::MissingMethodClient)
      end
    end

    def delegation(delegated_method_name)
      Casting::Delegation.new(delegated_method_name, self)
    end

    def delegate(delegated_method_name, attendant, *args)
      delegation(delegated_method_name).to(attendant).with(*args).call
    end

    def delegate_missing_methods
      self.extend ::Casting::MissingMethodClient
    end
  end

  module MissingMethodClient
    def method_missing(meth, *args, &block)
      if delegate_has_method?(meth)
        delegate(meth, @__current_delegate__, *args, &block)
      else
        super
      end
    end

    private

    def delegate_has_method?(meth)
      return false unless @__current_delegate__

      if Module === @__current_delegate__
        @__current_delegate__.instance_methods
      else
        @__current_delegate__.methods
      end.include?(meth)
    end
  end

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
      rescue TypeError => e
        raise unless RedCard.check '2.0'
        @attendant = method_module || raise
      end
      self
    end

    def with(*args)
      @arguments = args
      self
    end

    def call
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
      rescue TypeError => e
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

  class Delegation

    attr_reader :prepared_delegation
    private :prepared_delegation

    def initialize(delegated_method_name, client)
      @prepared_delegation = PreparedDelegation.new(:delegated_method_name => delegated_method_name, :client => client)
    end

    def client
      prepared_delegation.client
    end

    def to(object_or_module)
      prepared_delegation.to(object_or_module)
      self
    end

    def with(*args)
      prepared_delegation.with(*args)
      self
    end

    def call
      prepared_delegation.call
    end

  end
end
