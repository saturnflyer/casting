require "test_helper"

class TestContext
  using Casting::Context
  extend Casting::Context

  initialize :admin, :user

  def approve
    tell :admin, :say, "I approve"
  end

  def approve_with_keyword
    tell :admin, :keyword_say, what: "I approve"
  end

  def user_approve
    tell :user, :approve
  end

  module Admin
    def say(what)
      what
    end

    def keyword_say(what:)
      what
    end
  end

  module User
    def approve
      "Yay!"
    end
  end
end

class MissingModuleContext
  using Casting::Context
  extend Casting::Context

  initialize :admin, :user

  def run
    tell :admin, :go
  end
end

class BlockContext
  using Casting::Context
  extend Casting::Context

  initialize :admin do
    @blocked = true
  end
  attr :blocked
end

describe Casting::Context do
  it "accepts an initialize block" do
    admin = casting_person
    context = BlockContext.new(admin: admin)

    expect(context).must_be :blocked
  end

  it "applies module methods to Casting::Client objects" do
    admin = casting_person
    user = casting_person

    context = TestContext.new admin: admin, user: user

    expect(context.approve).must_equal("I approve")
    expect(context.approve_with_keyword).must_equal("I approve")
    expect(context.user_approve).must_equal("Yay!")
  end

  it "applies module methods to any object" do
    admin = Object.new
    user = 1

    context = TestContext.new admin: admin, user: user

    expect(context.approve).must_equal("I approve")
    expect(context.user_approve).must_equal("Yay!")
  end

  it "handles missing modules and raises missing method error" do
    admin = TestPerson.new
    user = TestPerson.new

    context = MissingModuleContext.new admin: admin, user: user

    err = expect { context.run }.must_raise(NoMethodError)
    expect(err.message).must_match(/unknown method 'go'/)
  end
end
