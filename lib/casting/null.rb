module Casting
  module Null
    def self.instance_method(name)
      Empty.instance_method(:null)
    end
  end
  module Blank
    def self.instance_method(name)
      Empty.instance_method(:blank)
    end
  end
  module Empty
    def null(*args, &block); end
    def blank(*args, &block)
      ""
    end
  end 
end