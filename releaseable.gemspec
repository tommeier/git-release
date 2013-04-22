# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'releaseable/version'

Gem::Specification.new do |spec|
  spec.name          = "releaseable"
  spec.version       = Releaseable::VERSION
  spec.authors       = ["Tom Meier"]
  spec.email         = ["tom@venombytes.com"]
  spec.description   = %q{Changelog and release tag generator}
  spec.summary       = %q{Generate changelog from git commits and tag your release versions}
  spec.homepage      = "http://github.com/tommeier/releaseable"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
