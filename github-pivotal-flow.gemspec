# Git Pivotal Tracker Integration
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Gem::Specification.new do |s|
  s.name        = 'github-pivotal-flow'
  s.version     = '0.0.7'
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
  s.add_development_dependency 'debugger', '~> 1.6'
  s.add_development_dependency 'simplecov', '~> 0.7'
  s.add_development_dependency 'yard', '~> 0.8'

end
