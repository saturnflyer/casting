# -*- encoding: utf-8 -*-
require File.expand_path("../lib/casting/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jim Gay"]
  gem.email         = ["jim@saturnflyer.com"]
  gem.description   = %q{Proper method delegation.}
  gem.summary       = %q{Proper method delegation.}
  gem.homepage      = ""

  gem.files         = ['lib/casting.rb', 'lib/casting/version.rb']
  gem.test_files    = ['test/test_helper.rb','test/casting_test.rb']
  gem.name          = "casting"
  gem.version       = Casting::VERSION

  gem.add_dependency('redcard','~> 1.1.0')
end
