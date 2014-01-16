# The class that encapsulates starting a Pivotal Tracker Story
module GhPivotalFlow
  class Start < GhPivotalFlow::Command

    # Starts a Pivotal Tracker story by doing the following steps:
    # * Create a branch
    # * Add default commit hook
    # * Start the story on Pivotal Tracker
    #
    # @param [String, nil] filter a filter for selecting the story to start.  This
    #   filter can be either:
    #   * a story id
    #   * a story type (feature, bug, chore)
    #   * +nil+
    # @return [void]
    def run!
      filter = @options[:args]
      #TODO: Validate the format of the filter argument
      story = Story.select_story @project, filter
      Story.pretty_print story
      story.request_estimation! if story.unestimated?
      story.create_branch!
      @configuration.story = story # Tag the branch with story attributes
      Git.add_hook 'prepare-commit-msg', File.join(File.dirname(__FILE__), 'prepare-commit-msg.sh')
      unless story.release?
        @ghclient = GitHubAPI.new(@configuration, :app_url => 'http://github.com/roomorama/gh-pivotal-flow')
        create_pull_request_for_story!(story)
      end
      story.mark_started!
      return 0
    end

    private

    def create_pull_request_for_story!(story)
      print "Creating pull-request on Github... "
      @ghclient.create_pullrequest(
        :project => @configuration.github_project,
        :base => story.root_branch_name,
        :head => story.branch_name,
        :title => story.name,
        :body => story.description,
      )
      puts 'OK'
    end

    def parse_argv(*args)
      OptionParser.new do |opts|
        opts.banner = "Usage: git start <feature|chore|bug|story_id>"
        opts.on("-t", "--api-token=", "Pivotal Tracker API key") { |k| options[:api_token] = k }
        opts.on("-p", "--project-id=", "Pivotal Tracker project id") { |p| options[:project_id] = p }
        opts.on("-n", "--full-name=", "Your Pivotal Tracker full name") { |n| options[:full_name] = n }

        opts.on_tail("-h", "--help", "This usage guide") { put opts.to_s; exit 0 }
      end.parse!(args)
    end
  end
end
