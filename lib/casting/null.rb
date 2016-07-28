module Casting
  module Null
    def self.instance_method(*_)
      Empty.instance_method(:null)
    end
    def self.method_defined?(*_)
      true
    end
  end
  module Blank
    def self.instance_method(*_)
      Empty.instance_method(:blank)
    end
    def self.method_defined?(*_)
      true
    end
  end
  module Empty
    def null(*, &_block); end
    def blank(*, &_block)
      ""
    end
  end 
end
