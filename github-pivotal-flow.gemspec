# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'github_pivotal_flow/version'

Gem::Specification.new do |s|
  s.name        = 'github-pivotal-flow'
  s.version     = GithubPivotalFlow::VERSION
  s.summary     = 'Git commands for integration with Pivotal Tracker and Github pull requests'
  s.description = 'Provides a set of additional Git commands to help developers when working with Pivotal Tracker and Github pull requests'
  s.authors     = ['Donald Piret']
  s.email       = 'donald@donaldpiret.com'
  s.homepage    = 'https://github.com/roomorama/github-pivotal-flow'
  s.license     = 'MIT'

  s.files            = %w(LICENSE README.md) + Dir['lib/**/*.rb'] + Dir['lib/**/*.sh'] + Dir['bin/*']
  s.executables      = Dir['bin/*'].map { |f| File.basename f }
  s.test_files       = Dir['spec/**/*_spec.rb']

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'highline', '~> 1.6'
  s.add_dependency 'pivotal-tracker', '~> 0.5'

  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'redcarpet', '~> 2.2'
  s.add_development_dependency 'rspec', '~> 2.14'
  s.add_development_dependency 'rspec-mocks', '~> 2.14'
  s.add_development_dependency 'simplecov', '~> 0.7'
  s.add_development_dependency 'yard', '~> 0.8'

end
