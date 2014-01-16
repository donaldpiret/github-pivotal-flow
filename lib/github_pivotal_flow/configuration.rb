require 'highline/import'
require 'uri'

module GithubPivotalFlow
  # A class that exposes configuration that commands can use
  class Configuration
    def initialize
      @github_password_cache = {}
    end

    # Returns the user's Pivotal Tracker API token.  If this token has not been
    # configured, prompts the user for the value.  The value is checked for in
    # the _inherited_ Git configuration, but is stored in the _global_ Git
    # configuration so that it can be used across multiple repositories.
    #
    # @return [String] The user's Pivotal Tracker API token
    def api_token
      api_token =  Git.get_config KEY_API_TOKEN, :inherited

      if api_token.empty?
        api_token = ask('Pivotal API Token (found at https://www.pivotaltracker.com/profile): ').strip
        Git.set_config KEY_API_TOKEN, api_token, :global
        puts
      end

      api_token
    end

    # Returns the Pivotal Tracker project id for this repository.  If this id
    # has not been configuration, prompts the user for the value.  The value is
    # checked for in the _inherited_ Git configuration, but is stored in the
    # _local_ Git configuration so that it is specific to this repository.
    #
    # @return [String] The repository's Pivotal Tracker project id
    def project_id
      project_id = Git.get_config KEY_PROJECT_ID, :inherited

      if project_id.empty?
        project_id = choose do |menu|
          menu.prompt = 'Choose project associated with this repository: '

          PivotalTracker::Project.all.sort_by { |project| project.name }.each do |project|
            menu.choice(project.name) { project.id }
          end
        end

        Git.set_config KEY_PROJECT_ID, project_id, :local
        puts
      end

      project_id
    end

    # Returns the story associated with the current development branch
    #
    # @param [PivotalTracker::Project] project the project the story belongs to
    # @return [PivotalTracker::Story] the story associated with the current development branch
    def story(project)
      story_id = Git.get_config(KEY_STORY_ID, :branch)
      Story.new(project.stories.find(story_id.to_i), :branch_name => Git.current_branch)
    end

    # Stores the story associated with the current development branch
    #
    # @param [PivotalTracker::Story] story the story associated with the current development branch
    # @return [void]
    def story=(story)
      Git.set_config KEY_STORY_ID, story.id, :branch
    end

    def feature_prefix
      feature_prefix = Git.get_config KEY_FEATURE_PREFIX, :inherited

      if feature_prefix.empty?
        feature_prefix = ask('Please enter your git-flow feature branch prefix: [feature]').strip
        feature_prefix = 'feature' if feature_prefix.blank?
        Git.set_config KEY_FEATURE_PREFIX, feature_prefix, :local
        puts
      end

      feature_prefix
    end

    def hotfix_prefix
      hotfix_prefix = Git.get_config KEY_HOTFIX_PREFIX, :inherited

      if hotfix_prefix.empty?
        hotfix_prefix = ask('Please enter your git-flow hotfix branch prefix: [hotfix]').strip
        hotfix_prefix = 'hotfix' if hotfix_prefix.blank?
        Git.set_config KEY_HOTFIX_PREFIX, hotfix_prefix, :local
        puts
      end

      hotfix_prefix
    end

    def release_prefix
      release_prefix = Git.get_config KEY_RELEASE_PREFIX, :inherited

      if release_prefix.empty?
        release_prefix = ask('Please enter your git-flow release branch prefix: [release]').strip
        release_prefix = 'release' if release_prefix.blank?
        Git.set_config KEY_RELEASE_PREFIX, release_prefix, :local
        puts
      end

      release_prefix
    end

    def development_branch
      development_branch = Git.get_config KEY_DEVELOPMENT_BRANCH, :inherited

      if development_branch.empty?
        development_branch = ask('Please enter your git-flow development branch name: [development]').strip
        development_branch = 'development' if development_branch.nil? || development_branch.empty?
        Git.set_config KEY_DEVELOPMENT_BRANCH, development_branch, :local
        puts
      end
      Git.ensure_branch_exists(development_branch)

      development_branch
    end

    def master_branch
      master_branch = Git.get_config KEY_MASTER_BRANCH, :inherited

      if master_branch.blank?
        master_branch = ask('Please enter your git-flow production branch name: [master]').strip
        master_branch = 'master' if master_branch.nil? || master_branch.empty?
        Git.set_config KEY_MASTER_BRANCH, master_branch, :local
        puts
      end
      Git.ensure_branch_exists(master_branch)

      master_branch
    end

    def github_project
      @github_project ||= Project.from_url(URI(Git.get_config("remote.#{Git.get_remote}.url")))
    end

    def github_username(host)
      return ENV['GITHUB_USER'] unless ENV['GITHUB_USER'].to_s.blank?
      github_username = Git.get_config KEY_GITHUB_USERNAME, :inherited
      if github_username.blank?
        github_username = ask('Github username: ').strip
        Git.set_config KEY_GITHUB_USERNAME, github_username, :local
      end
      github_username
    end

    def github_username=(github_username)
      Git.set_config KEY_GITHUB_USERNAME, github_username, :local unless github_username.blank?
    end

    def github_password(host, user)
      return ENV['GITHUB_PASSWORD'] unless ENV['GITHUB_PASSWORD'].to_s.empty?
      @github_password_cache["#{user}"] ||= ask_password(user)
    end

    def github_api_token(host, user)
      github_token = Git.get_config KEY_GITHUB_API_TOKEN, :inherited
      if github_token.blank?
        github_token = yield
        Git.set_config KEY_GITHUB_API_TOKEN, github_token, :local
      end
      github_token
    end

    # special prompt that has hidden input
    def ask_password(user)
      print "Github password for #{user} (never stored): "
      if $stdin.tty?
        password = askpass
        puts ''
        password
      else
        # in testing
        $stdin.gets.chomp
      end
    rescue Interrupt
      abort
    end

    def ask_auth_code
      print "two-factor authentication code: "
      $stdin.gets.chomp
    rescue Interrupt
      abort
    end

    def askpass
      noecho $stdin do |input|
        input.gets.chomp
      end
    end

    def noecho io
      require 'io/console'
      io.noecho { yield io }
    rescue LoadError
      fallback_noecho io
    end

    def fallback_noecho io
      tty_state = `stty -g 2>#{NULL}`
      system 'stty raw -echo -icanon isig' if $?.success?
      pass = ''
      while char = getbyte(io) and !(char == 13 or char == 10)
        if char == 127 or char == 8
          pass[-1,1] = '' unless pass.empty?
        else
          pass << char.chr
        end
      end
      pass
    ensure
      system "stty #{tty_state}" unless tty_state.empty?
    end

    def getbyte(io)
      if io.respond_to?(:getbyte)
        io.getbyte
      else
        # In Ruby <= 1.8.6, getc behaved the same
        io.getc
      end
    end

    def proxy_uri(with_ssl)
      env_name = "HTTP#{with_ssl ? 'S' : ''}_PROXY"
      if proxy = ENV[env_name] || ENV[env_name.downcase] and !proxy.empty?
        proxy = "http://#{proxy}" unless proxy.include? '://'
        URI.parse proxy
      end
    end

    private

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
end