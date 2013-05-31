require 'casting'

Thread.current[:class_delegates] = {}

module Casting
  def self.refining(assignments)
    assignments.each do |klass, mod|
      klass.refine_with(mod)
    end
    yield
  ensure
    assignments.each do |klass, mod|
      klass.unrefine
    end
  end

  module Refiner
    def self.extended(base)
      base.class_eval{
        def __class_delegates__
          self.class.__delegates__
        end

        def method_missing(meth, *args, &block)
          if !!method_class_delegate(meth)
            delegate(meth, method_class_delegate(meth), *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(meth, *)
          !!method_class_delegate(meth) || super
        end

        def method_class_delegate(meth)
          __class_delegates__.find{|attendant|
            if Module === attendant
              attendant.instance_methods
            else
              attendant.methods
            end.include?(meth)
          }
        end
      }
    end

    def refine_with(mod)
      __delegates__.unshift(mod)
      self
    end

    def unrefine
      __delegates__.shift
    end

    def __delegates__
      Thread.current[:class_delegates] ||= {}
      Thread.current[:class_delegates][self.name] ||= []
    end
  end
end

User = Struct.new(:name)
class User
  include Casting::Client
  delegate_missing_methods

  extend Casting::Refiner
end

module Greeter
  def hello
    puts "Hi, I am #{name}"
  end
end

jim = User.new('Jim')
amy = User.new('Amy')

Casting.refining(User => Greeter) do
  jim.hello
  amy.hello
end

amy.hello