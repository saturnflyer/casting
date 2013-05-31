require 'casting'

class Activation

  def initialize(user, time=Time.now)
    @user = user.cast_as(Activator)
    @time = time
  end
  attr_reader :user, :time

  def create
    user.create_activation(time)
  end

  def validate
    user.activated?(time)
  end

  module Activator
    def activated?(now=Time.now)
      activation = Activation.find_by_user_id(id) || NullActivation.instance
      activation.created_at < now
    end

    def create_activation(now=Time.now)
      Activation.create!(self, now)
    rescue Activation::Invalid
      go_to #...
    end
  end

end

activation = Activation.new(user)
activation.create
activation = Activation.new(user, last_wednesday)
activation.validate?