# -*- encoding: utf-8 -*-
require File.expand_path('../lib/casting/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Jim Gay']
  gem.email         = ['jim@saturnflyer.com']
  gem.description   = %q{Casting assists in method delegation which preserves the binding of 'self' to the object receiving a message.

    This allows you to define behavior and apply it to an object temporarily without extending the object's super class structure.}
  gem.summary       = %q{Proper method delegation.}
  gem.homepage      = 'http://github.com/saturnflyer/casting'

  gem.files         = ['lib/casting.rb',
                      'lib/casting/client.rb',
                      'lib/casting/context.rb',
                      'lib/casting/delegation.rb',
                      'lib/casting/method_consolidator.rb',
                      'lib/casting/missing_method_client.rb',
                      'lib/casting/missing_method_client_class.rb',
                      'lib/casting/null.rb',
                      'lib/casting/super_delegate.rb',
                      'lib/casting/version.rb',
                      'LICENSE',
                      'Rakefile',
                      'README.md']
  gem.test_files    = ['test/test_helper.rb',
                      'test/casting_test.rb',
                      'test/class_refinement_test.rb',
                      'test/client_test.rb',
                      'test/context_test.rb',
                      'test/delegation_test.rb',
                      'test/method_consolidator_test.rb',
                      'test/missing_method_client_test.rb',
                      'test/null_module_test.rb',
                      'test/module_cleanup_test.rb',
                      'test/super_test.rb']
  gem.name          = 'casting'
  gem.version       = Casting::VERSION
  gem.license       = 'MIT'
end
