# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zimbra_intercepting_proxy/version'

Gem::Specification.new do |spec|
  spec.name          = "zimbra_intercepting_proxy"
  spec.version       = ZimbraInterceptingProxy::VERSION
  spec.author       = ["Patricio Bruna"]
  spec.email         = ["pbruna@itlinux.cl"]
  spec.summary       = "A HTTP intercepting Proxy for the Zimbra Proxy"
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/pbruna/zimbra_intercepting_proxy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'em-proxy', "~> 0.1.8"
  spec.add_dependency 'http_parser.rb', "~> 0.6"
  spec.add_dependency 'addressable', "~> 2.3"
  spec.add_dependency 'xml-simple', "~> 1.1"
  spec.add_dependency 'rest-client'
  spec.add_dependency 'ipaddress'

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "webmock"
end
