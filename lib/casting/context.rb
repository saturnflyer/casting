# This is an experimental implementation of allowing contextual use of behaviors.
#
# This relies on versions of Ruby supporting refinements.
#
# You *must* include the following module and use it for refinements, and
# you *must* set the current context for the thread:
#
#  class SomeContext
#    using Casting::Context
#    include Casting::Context
#
#    def initialize(some, object)
#      assign [some, SomeRole], [object, OtherRole]
#      Thread.current[:context] = self
#    end
#    attr_reader :some, :object
#
#    module SomeRole; end
#    module OtherRole; end
#  end
#
module Casting
  module Context
    def context
      self
    end
  
    def assignments
      @assignments ||= []
    end
  
    def assign(*collection)
      Array(collection).each do |pair|
        assignments << pair
      end
    end
  
    def role_for(name)
      self.class.const_get(name.to_s.capitalize)
    rescue NameError
      Object
    end
  
    refine Object do
      def context
        Thread.current[:context]
      end
      
      def context=(obj)
        Thread.current[:context] = obj
      end
    
      def r(name)
        context.send(name)
      end
    
      def tell(name, meth)
        r(name).cast(meth, context.role_for(name))
      end
    
      def role_implements?(object, method_name)
        roles = assigned_roles(object).compact
        return false if roles.empty?
        assigned_roles(object).compact.any?{|role|
          role.method_defined?(method_name)
        }
      end
    
      def dispatch(object, method_name, *args, &block)
        object.cast(method_name, context.role_implementing(object, method_name), *args, &block)
      end
    
      def role_implementing(object, method_name)
        assigned_roles(object).find{|role| role.method_defined?(method_name) }
      end
    
      def method_missing(meth, *args, &block)
        if context.role_implements?(self, meth)
          context.dispatch(self, meth, *args, &block)
        elsif context.respond_to?(meth, true) && context != self
          context.send(meth, *args, &block)
        else
          super
        end
      end
    
      private
    
      def assigned_roles(object)
        assignments.select{|pair|
          pair.first == object 
        }.map(&:last)
      end
    end
  end
end