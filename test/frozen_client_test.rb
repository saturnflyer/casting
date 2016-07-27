require 'test_helper'

describe Casting::Client do
  it 'will not attempt to alter a frozen client' do
    client = TestPerson.new
    client.extend(Casting::Client)
    client.delegate_missing_methods
    
    client.freeze
    
    err = expect{ client.greet }.must_raise(NoMethodError)
    expect(err.message).must_match(/undefined method \`greet'/)    
  end
end