require "json"
require "casting"

module Names
  def names
    "names here"
  end
end

module Secrets
  def secrets
    "secrets here"
  end
end

module Redacted
  def secrets
    "***********"
  end
end

class Jsoner
  include Casting::Client
  delegate_missing_methods

  def as_json(*attributes)
    {}.tap do |hash|
      attributes.each do |att|
        hash[att] = send(att)
      end
    end
  end
end

empty = Jsoner.new
empty.cast_as(Casting::Null)
puts empty.as_json(:names, :secrets)

secret = Jsoner.new
secret.cast_as(Casting::Null, Secrets)
puts secret.as_json(:names, :secrets)

everything = Jsoner.new
everything.cast_as(Casting::Null, Secrets, Names)
puts everything.as_json(:names, :secrets)

names = Jsoner.new
names.cast_as(Casting::Null, Names)
puts names.as_json(:names, :secrets)

redacted = Jsoner.new
redacted.cast_as(Casting::Null, Secrets, Redacted)
puts redacted.as_json(:names, :secrets)

# {:names=>nil, :secrets=>nil}
# {:names=>nil, :secrets=>"secrets here"}
# {:names=>"names here", :secrets=>"secrets here"}
# {:names=>"names here", :secrets=>nil}
# {:names=>nil, :secrets=>"***********"}
