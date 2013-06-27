module Casting
  module MissingMethodClient

    def cast_as(attendant)
      if attendant == self
        raise Casting::InvalidAttendant.new('attendant argument is the current client')
      end
      __delegates__.unshift(attendant)
      self
    end

    def uncast
      __delegates__.shift
      self
    end

    private

    def __delegates__
      @__delegates__ ||= []
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