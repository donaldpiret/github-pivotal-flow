module GhPivotalFlow
  # A class that exposes configuration that commands can use
  class Configuration
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
      Story.new(project.stories.find(story_id.to_i), :branch_name => Git.branch_name)
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
        feature_prefix = 'feature' if feature_prefix.nil? || feature_prefix.empty?
        Git.set_config KEY_FEATURE_PREFIX, feature_prefix, :local
        puts
      end

      feature_prefix
    end

    def hotfix_prefix
      hotfix_prefix = Git.get_config KEY_HOTFIX_PREFIX, :inherited

      if hotfix_prefix.empty?
        hotfix_prefix = ask('Please enter your git-flow hotfix branch prefix: [hotfix]').strip
        hotfix_prefix = 'hotfix' if hotfix_prefix.nil? || hotfix_prefix.empty?
        Git.set_config KEY_HOTFIX_PREFIX, hotfix_prefix, :local
        puts
      end

      hotfix_prefix
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

      if master_branch.empty?
        master_branch = ask('Please enter your git-flow production branch name: [master]').strip
        master_branch = 'master' if master_branch.nil? || master_branch.empty?
        Git.set_config KEY_MASTER_BRANCH, master_branch, :local
        puts
      end
      Git.ensure_branch_exists(master_branch)

      master_branch
    end

    private

    KEY_API_TOKEN = 'pivotal.api-token'.freeze
    KEY_PROJECT_ID = 'pivotal.project-id'.freeze
    KEY_STORY_ID = 'pivotal-story-id'.freeze
    KEY_FEATURE_PREFIX = 'gitflow.prefix.feature'.freeze
    KEY_HOTFIX_PREFIX = 'gitflow.prefix.hotfix'.freeze
    KEY_DEVELOPMENT_BRANCH = 'gitflow.branch.develop'.freeze
    KEY_MASTER_BRANCH = 'gitflow.branch.master'.freeze
  end
end