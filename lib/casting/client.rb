require 'casting/delegation'
require 'casting/missing_method_client'

module Casting
  module Client

    def self.included(base)
      def base.delegate_missing_methods
        self.send(:include, ::Casting::MissingMethodClient)
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

    def delegate_missing_methods
      self.extend ::Casting::MissingMethodClient
    end

    private

    def self.add_delegate_method_to(base)
      base.class_eval{ alias_method :delegate, :cast }
    end
  end
end