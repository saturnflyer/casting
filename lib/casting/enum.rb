module Casting
  module Enum
    extend self

    def enum(collection, *behaviors)
      Enumerator.new do |yielder|
        collection.each do |item|
          yielder.yield(item.cast_as(*behaviors))
        end
      end
    end
  end
end
