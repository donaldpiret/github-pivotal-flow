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

$:.unshift(File.dirname(__FILE__))

require 'highline/import'
require 'pivotal-tracker'

require File.join('core_ext', 'object', 'blank')

module GithubPivotalFlow
  KEY_USER_NAME = 'user.name'.freeze
  KEY_API_TOKEN = 'pivotal.api-token'.freeze
  KEY_PROJECT_ID = 'pivotal.project-id'.freeze
  KEY_STORY_ID = 'pivotal-story-id'.freeze
  KEY_FEATURE_PREFIX = 'gitflow.prefix.feature'.freeze
  KEY_HOTFIX_PREFIX = 'gitflow.prefix.hotfix'.freeze
  KEY_RELEASE_PREFIX = 'gitflow.prefix.release'.freeze
  KEY_DEVELOPMENT_BRANCH = 'gitflow.branch.develop'.freeze
  KEY_MASTER_BRANCH = 'gitflow.branch.master'.freeze
  KEY_GITHUB_USERNAME = 'github.username'.freeze
  KEY_GITHUB_API_TOKEN = 'github.api-token'.freeze
end

require File.join('github_pivotal_flow', 'version')

require File.join('github_pivotal_flow', 'shell')
require File.join('github_pivotal_flow', 'git')
require File.join('github_pivotal_flow', 'project')
require File.join('github_pivotal_flow', 'configuration')
require File.join('github_pivotal_flow', 'github_api')
require File.join('github_pivotal_flow', 'story')
require File.join('github_pivotal_flow', 'command')
require File.join('github_pivotal_flow', 'start')
require File.join('github_pivotal_flow', 'finish')