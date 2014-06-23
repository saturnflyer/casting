require 'test_helper'

if test_rebinding_methods?
  describe Casting::Null do
    it 'will answer to any method with nil' do
      client = TestPerson.new
      client.extend(Casting::Client)
      attendant = Casting::Null

      assert_nil client.delegate('greet', attendant)
    end
  end

  describe Casting::Blank do
    it 'will answer to any method with an empty string' do
      client = TestPerson.new
      client.extend(Casting::Client)
      attendant = Casting::Blank

      assert_empty client.delegate('greet', attendant)
    end
  end
end