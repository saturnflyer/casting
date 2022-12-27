# Execute this script with:
#   ruby -I lib examples/dci.rb

require "casting"

def log(message)
  puts("Transaction log: " + message)
end

# What it is
Account = Struct.new(:name, :balance)
class Account
  include Casting::Client
  delegate_missing_methods

  alias_method :to_s, :name
end

checking = Account.new(":checking:", 500)
savings = Account.new("~savings~", 2)

# What it does
Transfer = Struct.new(:amount, :source, :destination)
class Transfer
  def execute
    Casting.delegating(source => Source) do
      source.transfer(amount, destination)
    end
  end

  module Source
    def transfer(amount, destination)
      log("#{self} transferring #{amount} to #{destination}")

      Funding.new(self, -amount).enter &&
        Funding.new(destination, amount).enter

      log("#{self} successfully transferred #{amount} to #{destination}")
    rescue Funding::InsufficientFunds
      log("#{self} unable to transfer #{amount} to #{destination}")
    end
  end
end

Funding = Struct.new(:account, :amount)
class Funding
  def enter
    Casting.delegating(account => Sink) do
      account.add_funds(amount)
    end
  end

  class InsufficientFunds < StandardError; end

  module Sink
    def add_funds(amount)
      log_total
      log("Adding #{amount} to #{self}")

      self.balance += amount

      if self.balance > 0
        log("Funded #{self} with #{amount}")
      else
        self.balance -= amount
        log("#{self} has insufficient funds for #{amount}")
        raise Funding::InsufficientFunds.new
      end
    ensure
      log_total
    end

    def log_total
      log("#{self} ==total== is #{balance}")
    end
  end
end

puts "Transferring..."
Transfer.new(30, checking, savings).execute
Transfer.new(50, savings, checking).execute
