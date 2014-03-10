module Casting
  module Super
    
    # Call the method of the same name defined in the next delegate stored in your object
    #
    # Because Casting creates an alternative method lookup path using a collection of delegates,
    # you may use `super_delegate` to work like `super`.
    #
    # If you use this feature, be sure that you have created a delegate collection which does
    # have the method you need or you'll see a NoMethodError.
    #
    # Example:
    #
    # module Greeter
    #   def greet
    #     "Hello"
    #   end
    # end
    #
    # module FormalGreeter
    #   include Casting::Super
    #   
    #   def greet
    #     "#{super_delegate}, how do you do?"
    #   end
    # end
    #
    # some_object.cast_as(Greeter, FormalGreeter)
    # some_object.greet #=> 'Hello, how do you do?'
    #
    def super_delegate(*args, &block)
      method_name = name_of_calling_method(caller)
      
      super_delegate_method = unbound_method_from_next_delegate(method_name, method_delegate(method_name))

      if super_delegate_method.arity == 0
        super_delegate_method.bind(self).call
      else
        super_delegate_method.bind(self).call(*args, &block)
      end
    rescue NameError
      raise NoMethodError.new("super_delegate: no delegate method `#{method_name}' for #{self.inspect}")
    end
    
    def unbound_method_from_next_delegate(method_name, *skipped)
      method_delegate_skipping(method_name, *skipped).instance_method(method_name)
    end
    
    def method_delegate_skipping(meth, *skipped)
      __delegates__.find{|attendant|
        attendant_methods(attendant).include?(meth) && !skipped.include?(attendant) 
      }
    end
    
    def name_of_calling_method(call_stack)
      call_stack.reject{|line| 
        line.to_s =~ Casting::Super::PATH_REGEXP 
      }.first.split('`').last.sub("'","").to_sym
    end
    
    PATH_REGEXP = Regexp.new(Dir.pwd.to_s + '/lib')
  end
end