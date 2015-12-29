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
# In order to use this the objects sent into the context contstructor *must*
# include Casting::Client so that the `cast` method is available to them
#
module Casting
  module Context

    def self.extended(base)
      base.send(:include, InstanceMethods)
    end

    def initialize(*setup_args)
      attr_reader(*setup_args)
      private(*setup_args)

      mod = Module.new
      line = __LINE__; string = %<
        def initialize(#{setup_args.join(',')})
          #{setup_args.map do |arg|
            ['@',arg,' = ',arg].join
          end.join("\n")}
          #{setup_args.map do |arg|
            ["assign(",arg,", self.role_for('",arg,"'))"].join
          end.join("\n")}
          Thread.current[:context] = self
        end
      >
      mod.class_eval string, __FILE__, line
      const_set('Initializer', mod)
      include mod
    end

    module InstanceMethods
      def context
        self
      end
  
      def assignments
        @assignments ||= []
      end
  
      def assign(object, role)
        assignments << [object, role]
      end

      def dispatch(object, method_name, *args, &block)
        object.cast(method_name, context.role_implementing(object, method_name), *args, &block)
      end
    
      def role_implementing(object, method_name)
        assigned_roles(object).find{|role| role.method_defined?(method_name) }
      end
    
      def assigned_roles(object)
        assignments.select{|pair|
          pair.first == object
        }.map(&:last)
      end

      def role_for(name)
        role_name = name.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
        self.class.const_get(role_name)
      rescue NameError
        Module
      end
    
      def role_implements?(object, method_name)
        roles = assigned_roles(object).compact
        return false if roles.empty?
        roles.any?{|role|
          role.method_defined?(method_name)
        }
      end
    
      def r(name)
        context.send(name)
      end
    
      def tell(name, meth)
        r(name).cast(meth, context.role_for(name))
      end
    end

    refine Object do
      def context
        Thread.current[:context]
      end

      def context=(obj)
        Thread.current[:context] = obj
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
    end
  end
end