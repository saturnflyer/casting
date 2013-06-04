require 'casting/delegation'
require 'casting/missing_method_client'
require 'casting/missing_method_client_class'

module Casting
  module Client

    def self.included(base)
      def base.delegate_missing_methods(*which)
        Casting::Client.set_delegation_strategy(self, *which.reverse)
      end

      unless base.instance_methods.include?('delegate')
        add_delegate_method_to(base)
      end
    end

    def self.extended(base)
      unless base.respond_to?('delegate')
        add_delegate_method_to(base.singleton_class)
      end
    end

    def delegation(delegated_method_name)
      Casting::Delegation.new(delegated_method_name, self)
    end

    def cast(delegated_method_name, attendant, *args)
      delegation(delegated_method_name).to(attendant).with(*args).call
    end

    def delegate_missing_methods(*which)
      Casting::Client.set_delegation_strategy(self.singleton_class, *which.reverse)
    end

    private

    def self.set_delegation_strategy(base, *which)
      which = [:instance] if which.empty?
      which.map!{|selection|
        selection == :instance && selection = self.method(:set_method_missing_client)
        selection == :class && selection = self.method(:set_method_missing_client_class)
        selection
      }.map{|meth| meth.call(base) }
    end

    def self.add_delegate_method_to(base)
      base.class_eval{ alias_method :delegate, :cast }
    end

    def self.set_method_missing_client(base)
      base.send(:include, ::Casting::MissingMethodClient)
    end

    def self.set_method_missing_client_class(base)
      base.send(:extend, ::Casting::MissingMethodClientClass)
    end
  end
end