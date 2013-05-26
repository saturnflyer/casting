module Casting
  module MissingMethodClient
    def method_missing(meth, *args, &block)
      if delegate_has_method?(meth)
        delegate(meth, @__current_delegate__, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(meth, *)
      delegate_has_method?(meth) || super
    end

    private

    def delegate_has_method?(meth)
      return false unless @__current_delegate__

      if Module === @__current_delegate__
        @__current_delegate__.instance_methods
      else
        @__current_delegate__.methods
      end.include?(meth)
    end
  end
end