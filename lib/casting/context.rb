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
#    initialize(:some, :thing)
#    # doing that defines your constructr but would cause it too look for
#    # modules named Some and Thing
#    module Some; end
#    module Thing; end
#
#    # if you want different module names (why would you?) then you'd need
#    # to do all this:
#    def initialize(some, thing)
#      assign [some, SomeRole], [thing, OtherRole]
#      Thread.current[:context] = self
#    end
#    attr_reader :some, :thing
#
#    module SomeRole; end
#    module OtherRole; end
#  end
#
# In order to use this the objects sent into the context contstructor *must*
# `include Casting::Client` so that the `cast` method is available to them
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
  
      # Keep track of objects and their behaviors
      def assign(object, role)
        assignments << [object, role]
      end

      # Execute the behavior from the role on the specifed object
      def dispatch(object, method_name, *args, &block)
        object.cast(method_name, context.role_implementing(object, method_name), *args, &block)
      end
    
      # Find the first assigned role which implements a response for the given method name
      def role_implementing(object, method_name)
        assigned_roles(object).find{|role| role.method_defined?(method_name) }
      end
    
      # Get the roles for the given object
      def assigned_roles(object)
        assignments.select{|pair|
          pair.first == object
        }.map(&:last)
      end

      # Get the behavior module for the named role.
      # This role constant for special_person is SpecialPerson.
      def role_for(name)
        role_name = name.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
        self.class.const_get(role_name)
      rescue NameError
        Module
      end
    
      # Does the object have behavior defined for the given message?
      def role_implements?(object, method_name)
        roles = assigned_roles(object).compact
        return false if roles.empty?
        roles.any?{|role|
          role.method_defined?(method_name)
        }
      end
    
      # Get the object playing a particular role
      def r(role_name)
        context.send(role_name)
      end
    
      # Execute the named method on the object plaing the name role
      def tell(role_name, method_name)
        r(role_name).cast(method_name, context.role_for(role_name))
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