require 'test_helper'

class TestContext
  using Casting::Context
  extend Casting::Context
  
  initialize :admin, :user
  
  def approve
    tell :admin, :say, 'I approve'
  end
  
  def user_approve
    tell :user, :approve
  end
  
  module Admin
    def say(what)
      what
    end
  end
  
  module User
    def approve
      'Yay!'
    end
  end
end

describe Casting::Context do
  it 'applies module methods to the objects' do
    admin = TestPerson.new
    admin.extend(Casting::Client)
    user = TestPerson.new
    user.extend(Casting::Client)
    
    context = TestContext.new admin: admin, user: user
    
    expect(context.approve).must_equal ('I approve')
    expect(context.user_approve).must_equal ('Yay!')
  end
end