# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'seven/version'

Gem::Specification.new do |spec|
  spec.name          = "sevencan"
  spec.version       = Seven::VERSION
  spec.authors       = ["jiangzhi.xie"]
  spec.email         = ["xiejiangzhi@gmail.com"]

  spec.summary       = %q{simple permission manager}
  spec.description   = %q{simple permission manager}
  spec.homepage      = "http://seven.xjz.pw"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rspec", '~> 3.7.0'
  spec.add_development_dependency "pry", '>= 0.10'

  spec.add_development_dependency "redis", ' >= 3.0'

  spec.add_dependency "activesupport"
end
