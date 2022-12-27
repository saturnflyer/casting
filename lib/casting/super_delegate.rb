module Casting
  module SuperDelegate
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
    def super_delegate(mod = :none, *args, **kwargs, &block)
      method_name = name_of_calling_method(caller_locations)
      owner = (mod unless mod == :none) || method_delegate(method_name)

      super_delegate_method = unbound_method_from_next_delegate(method_name, owner)
      super_delegate_method.bind_call(self, *args, **kwargs, &block)
    rescue NameError
      raise NoMethodError.new("super_delegate: no delegate method `#{method_name}' for #{inspect} from #{owner}")
    end

    def unbound_method_from_next_delegate(method_name, *skipped)
      method_delegate_skipping(method_name, *skipped).instance_method(method_name)
    end

    def method_delegate_skipping(meth, skipped)
      skipped_index = __delegates__.index(skipped)
      __delegates__[(skipped_index + 1)..__delegates__.length].find { |attendant|
        attendant_methods(attendant).include?(meth)
      }
    end

    def calling_location(call_stack)
      call_stack.reject { |line|
        line.to_s.match? Regexp.union(casting_library_matcher, gem_home_matcher, debugging_matcher)
      }.first
    end

    def name_of_calling_method(call_stack)
      calling_location(call_stack).label.to_sym
    end

    def casting_library_matcher
      Regexp.new(Dir.pwd.to_s + "/lib")
    end

    def gem_home_matcher
      Regexp.new(ENV["GEM_HOME"])
    end

    def debugging_matcher
      Regexp.new("internal:trace_point")
    end
  end
end
