module Casting
  module MissingMethodClient
    def method_missing(meth, *args, &block)
      if delegate_has_method?(meth)
        delegate(meth, method_delegate(meth), *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(meth, *)
      !!method_delegate(meth) || super
    end

    private

    def method_delegate(meth)
      Array(@__delegates__).find{|attendant|
        if Module === attendant
          attendant.instance_methods
        else
          attendant.methods
        end.include?(meth)
      }
    end
  end
end