class Delegation

  VERSION = '0.0.1'

  class MissingAttendant < StandardError
    def message
      "You must set your attendant object using `to'."
    end
  end

  module Client
    def delegate(delegated_method_name)
      Delegation.new(delegated_method_name, self)
    end
  end

  def initialize(delegated_method_name, client)
    @delegated_method_name = delegated_method_name
    @client = client
  end

  def to(object_or_module)
    case
    when Module === object_or_module then
      @attendant = @client.clone.extend(object_or_module)
    when !object_or_module.kind_of?(@client.class)
      raise ArgumentError.new("Invalid argument given. Argument must be one of #{@client.class}")
    else
      @attendant = object_or_module
    end

    self
  end

  def with(*args)
    @arguments = args
    self
  end

  def call
    raise MissingAttendant.new unless @attendant

    delegated_method = @attendant.singleton_class.instance_method(@delegated_method_name)

    if @arguments
      delegated_method.bind(@client).call(*@arguments)
    else
      delegated_method.bind(@client).call
    end
  end
end
