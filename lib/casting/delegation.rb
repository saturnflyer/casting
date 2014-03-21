require 'casting/prepared_delegation'

module Casting
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

    def with(*args, &block)
      prepared_delegation.with(*args, &block)
      self
    end

    def call(*args)
      prepared_delegation.call(*args)
    end

  end
end