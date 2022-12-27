# This code is related to subscription services.
# Instead of making a Subscriber a separate object
# with a reference to a User, make the User play a role.

class User
  include Casting::Client
  delegate_missing_methods
end

module Subscriber
  def subscribe
    @subscription = Subscription.find_by_subscriber(self) || Subscription.create_with_subscriber(self)
    self
  end

  def subscription
    @subscription or raise NoSubscriptionError
  end

  class NoSubscriptionError < StandardError; end
end

user = User.new # <User:12353>
user.subscription # NoMethodError
user.subscribe # NoMethodError
user.cast_as(Subscriber)
user.subscription # NoSubscriptionError
user.subscribe # <User:12353 @subscription=<Subscription:123435>>
user.subscription # <Subscription:123435>
user.uncast
user.subscribe # NoMethodError
