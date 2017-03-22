# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis-insights/version'

Gem::Specification.new do |spec|
  spec.name          = 'redis-insights'
  spec.version       = RedisInsights::VERSION
  spec.authors       = ['Jonathan Owens']
  spec.email         = ['intjonathan@gmail.com']
  spec.summary       = <<-EOS.gsub(/^\s+/, '')
    A daemon for slurping Redis INFO output into New Relic Insights.
EOS
  spec.homepage      = 'https://github.com/intjonathan/insights-about-redis'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'clockwork', '~> 2.0'
  spec.add_dependency 'redis', '~> 3.3'
  spec.add_dependency 'httparty', '~> 0.14'
  spec.add_dependency 'oj', '~> 2.0'
  spec.add_dependency 'trollop', '~> 2.1'

  spec.required_ruby_version = '>= 1.9.3'
end
