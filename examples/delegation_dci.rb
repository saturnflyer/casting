# Execute this script with:
#   ruby -I lib examples/delegation_dci.rb

require 'casting'
require 'casting/context'

def log(message)
  puts('Transaction log: ' + message.to_s)
end

# What it is
class Account
  include Casting::Client
  def initialize(name, balance)
    @name = name
    @balance = balance.to_i
  end
  attr_reader :name, :balance
  alias_method :to_s, :name
end

checking = Account.new(':checking:', 500)
savings = Account.new('~savings~', 2)


# What it does
class Transfer
  extend Casting::Context
  using Casting::Context
  
  initialize :amount, :source, :destination
  
  def execute
    log("#{source} has #{source.balance}")
    log("#{destination} has #{destination.balance}")
    result = catch(:result) do
      destination.increase_balance
    end
    log(result)
  end
  
  module Destination
    def increase_balance
      source.decrease_balance
      log("#{self} accepting #{amount} from #{source}")
      @balance = balance.to_i + amount
    end
  end

  module Source
    def decrease_balance
      log("#{self} releasing #{amount} to #{destination}")
      check_balance
      @balance = balance.to_i - amount
      log("#{self} released #{amount}. balance is now #{balance}")
    end
    
    def check_balance
      if balance < amount
        throw(:result, "#{self} has insufficient funds for withdrawal of #{amount}. Current balance is #{balance}")
      end
    end
  end
end

puts "Transferring..."
Transfer.new(amount: 30, source: checking, destination: savings).execute
Transfer.new(amout: 50, source: savings, destination: checking).execute