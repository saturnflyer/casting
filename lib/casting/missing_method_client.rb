module Casting
  module MissingMethodClient

    def cast_as(attendant)
      __delegates__.unshift(attendant)
      self
    end

    def uncast
      __delegates__.shift
      self
    end

    def method_missing(meth, *args, &block)
      if !!method_delegate(meth)
        delegate(meth, method_delegate(meth), *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(meth, *)
      !!method_delegate(meth) || super
    end

    private

    def __delegates__
      @__delegates__ ||= []
    end

    def method_delegate(meth)
      __delegates__.find{|attendant|
        if Module === attendant
          attendant.instance_methods
        else
          attendant.methods
        end.include?(meth)
      }
    end
  end
end