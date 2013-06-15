# Provide a feature like the Forwardable library,
# but this leaves the methods always present.
# It provides a class level "delegate" method to do
# delegation, but adds a "forward" method to do non-delegation
# method forwarding.
#
# class SomeClass
#   include Casting::Client
#   extend CastingForwardable
#
#   delegate [:name, :id] => :collaborator, [:color, :type] => :partner
#   forward :description => :describer, [:settings, :url] => :config
# end
#
# This will define methods on instances that delegate to the
# result of another method.
#
# For example, the above :collaborator reference could return a module
#
# module SomeModule
#   def name
#     "<~#{self.object_id}~>"
#   end
# end
#
# class SomeClass
#   def collaborator
#     SomeModule
#   end
# end
#
# Or it could return an object
#
# class SomeClass
#   attr_accessor :collaborator
# end
#
# thing = SomeClass.new
# thing.collaborator = SomeModule # or some other object
# thing.name
#
module CastingForwardale
  def delegate(options)
    options.each_pair do |key, value|
      Array(key).each do |prepared_method|
        define_method prepared_method do
          delegate(prepared_method, self.__send__(value))
        end
      end
    end
  end

  def forward(options)
    options.each_pair do |key, value|
      Array(key).each do |prepared_method|
        define_method prepared_method do
          self.__send__(value).__send__(key)
        end
      end
    end
  end
end