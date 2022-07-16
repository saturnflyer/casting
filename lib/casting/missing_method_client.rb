require 'casting/method_consolidator'

module Casting
  module MissingMethodClient

    def cast_as(*attendants)
      attendants.each do |attendant|
        validate_attendant(attendant)
        attendant.cast_object(self) if attendant.respond_to?(:cast_object)
        __delegates__.unshift(attendant)
      end
      self
    end

    def uncast(count=1)
      count.times do
        attendant = __delegates__.shift
        attendant.uncast_object(self) if attendant.respond_to?(:uncast_object)
      end
      self
    end

    def delegated_methods(all=true)
      __delegates__.flat_map{|attendant|
        attendant_methods(attendant, all)
      }
    end

    def delegated_public_methods(include_super=true)
      __delegates__.flat_map{|attendant|
        attendant_public_methods(attendant, include_super)
      }
    end

    def delegated_protected_methods(include_super=true)
      __delegates__.flat_map{|attendant|
        attendant_protected_methods(attendant, include_super)
      }
    end

    def delegated_private_methods(include_super=true)
      __delegates__.flat_map{|attendant|
        attendant_private_methods(attendant, include_super)
      }
    end

    private

    def __delegates__
      Thread.current[:instance_delegates] ||= {}
      Thread.current[:instance_delegates][object_id] ||= []
      Thread.current[:instance_delegates][object_id]
    end

    def method_missing(meth, *args, **kwargs, &block)
      attendant = method_delegate(meth)
      if !!attendant
        cast(meth, attendant, *args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(meth, *)
      !!method_delegate(meth) || super
    end

    def method_delegate(meth)
      __delegates__.find{|attendant|
        attendant.respond_to?(:method_defined?) && attendant.method_defined?(meth) ||
        attendant_methods(attendant).include?(meth)
      }
    end

    def attendant_methods(attendant, all=true)
      collection = attendant_public_methods(attendant) + attendant_protected_methods(attendant)
      collection += attendant_private_methods(attendant) if all
      collection
    end

    def attendant_public_methods(attendant, include_super=true)
      if Module === attendant
        attendant.public_instance_methods(include_super)
      else
        attendant.public_methods(include_super)
      end
    end

    def attendant_protected_methods(attendant, include_super=true)
      if Module === attendant
        attendant.protected_instance_methods(include_super)
      else
        attendant.protected_methods(include_super)
      end
    end

    def attendant_private_methods(attendant, include_super=true)
      if Module === attendant
        attendant.private_instance_methods(include_super)
      else
        attendant.private_methods(include_super)
      end
    end
  end
end
