# -*- encoding: utf-8 -*-
require File.expand_path("../lib/delegation", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jim Gay"]
  gem.email         = ["jim@saturnflyer.com"]
  gem.description   = %q{Proper method delegation.}
  gem.summary       = %q{Proper method delegation.}
  gem.homepage      = ""

  gem.test_files    = ['test/test_helper.rb','test/delegation_test.rb']
  gem.name          = "delegation"
  gem.version       = Delegation::VERSION
end
