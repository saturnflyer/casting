# This is an experimental implementation of allowing contextual use of behaviors.
#
# This relies on versions of Ruby supporting refinements.
#
# You *must* include the following module and use it for refinements, and
# you *must* set the current context for the thread:
#
#  class SomeContext
#    using Casting::Context
#    extend Casting::Context
#
#    initialize(:some, :thing)
#    # doing that defines your constructor but would cause it too look for
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
#    attr_reader :some, :thing, :assignments
#
#    module SomeRole; end
#    module OtherRole; end
#  end
#
module Casting
  module Context
    def self.extended(base)
      base.send(:include, InstanceMethods)
    end

    def initialize(*setup_args, &block)
      attr_reader(*setup_args)
      private(*setup_args)

      if block
        define_method(:__custom_initialize, &block)
      else
        define_method(:__custom_initialize) {}
      end

      mod = Module.new
      mod.class_eval <<~INIT, __FILE__, __LINE__ + 1
        def initialize(#{setup_args.map { |name| "#{name}:" }.join(",")})
          @assignments = []
          #{setup_args.map do |name|
            ["assign(", name, ", '", name, "')"].join
          end.join("\n")}
          __custom_initialize
          Thread.current[:context] = self
        end
        attr_reader :assignments
      INIT
      const_set(:Initializer, mod)
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
      def assign(object, role_name)
        instance_variable_set("@#{role_name}", object)
        assignments << [object, role_for(role_name)]
      end

      def contains?(obj)
        assignments.map(&:first).include?(obj)
      end

      # Execute the behavior from the role on the specifed object
      def dispatch(object, method_name, ...)
        if object.respond_to?(:cast)
          object.cast(method_name, context.role_implementing(object, method_name), ...)
        else
          Casting::Delegation.prepare(method_name, object).to(role_implementing(object, method_name)).with(...).call
        end
      end

      # Find the first assigned role which implements a response for the given method name
      def role_implementing(object, method_name)
        assigned_roles(object).find { |role| role.method_defined?(method_name) } || raise(NoMethodError, "unknown method '#{method_name}' expected for #{object}")
      end

      # Get the roles for the given object
      def assigned_roles(object)
        assignments.select { |pair|
          pair.first == object
        }.map(&:last)
      end

      # Get the behavior module for the named role.
      # This role constant for special_person is SpecialPerson.
      def role_for(name)
        role_name = name.to_s.gsub(/(?:^|_)([a-z])/) { $1.upcase }
        self.class.const_get(role_name)
      rescue NameError
        Module.new
      end
    end

    refine Object do
      def context
        Thread.current[:context]
      end

      def context=(obj)
        Thread.current[:context] = obj
      end

      # Get the object playing a particular role
      def role(role_name)
        context.send(role_name)
      end

      # Execute the named method on the object plaing the name role
      def tell(role_name, method_name, ...)
        if context == self || context.contains?(self)
          context.dispatch(role(role_name), method_name, ...)
        end
      end
    end
  end
end
