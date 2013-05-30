# Warning: This is probably not thread-safe

require 'casting'

User = Struct.new(:name)
class User
  include Casting::Client
  delegate_missing_methods

  def self.refine_with(mod)
    __delegates__ << mod
  end

  def self.__delegates__
    @__delegates__ ||= []
  end

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
end

module Greeter
  def hello
    puts "Hi, I am #{name}"
  end
end

jim = User.new('Jim')
User.refine_with(Greeter)
jim.hello

amy = User.new('Amy')
amy.hello