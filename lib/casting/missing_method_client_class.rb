module Casting
  module MissingMethodClientClass
    def self.extended(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      private

      def __class_delegates__
        self.class.__delegates__
      end

      def method_missing(meth, *args, &block)
        attendant = method_class_delegate(meth)
        if !!attendant
          cast(meth, attendant, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(meth, *)
        !!method_class_delegate(meth) || super
      end

      def method_class_delegate(meth)
        __class_delegates__.find { |attendant|
          attendant.method_defined?(meth)
        }
      end
    end

    def cast_as(attendant)
      __delegates__.unshift(attendant)
      self
    end

    def uncast
      __delegates__.shift
      self
    end

    def __delegates__
      Thread.current[:class_delegates] ||= {}
      Thread.current[:class_delegates][name] ||= []
    end
  end
end
