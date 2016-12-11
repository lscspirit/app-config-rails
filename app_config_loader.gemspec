# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'app_config_loader/version'

Gem::Specification.new do |spec|
  spec.name          = "app_config_loader"
  spec.version       = AppConfigLoader::VERSION
  spec.authors       = ["Derrick Yeung"]
  spec.email         = ["lscspirit@hotmail.com"]

  spec.summary       = %q{Application configuration using YAML}
  spec.description   = %q{A easy way to define application configurations using YAML in your Rails environment.}
  spec.homepage      = 'https://github.com/lscspirit/app_config_loader'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "faker"
end
