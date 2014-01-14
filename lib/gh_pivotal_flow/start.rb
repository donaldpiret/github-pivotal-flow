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
      story.create_branch
      @configuration.story = story
      Git.add_hook 'prepare-commit-msg', File.join(File.dirname(__FILE__), 'prepare-commit-msg.sh')
      # TODO: If the story difficulty is not yet estimated, ask to fill it in here
      story.mark_started!
      return 0
    end

    private

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
