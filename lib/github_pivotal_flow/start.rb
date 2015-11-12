# The class that encapsulates starting a Pivotal Tracker Story
module GithubPivotalFlow
  class Start < GithubPivotalFlow::Command

    def run!
      filter = [@options[:args]].flatten.first
      #TODO: Validate the format of the filter argument
      story = Story.select_story(@project, filter, 1, options = @options)
      Story.pretty_print story
      story.request_estimation! if story.unestimated?
      story.create_branch!
      @configuration.story = story # Tag the branch with story attributes
      Git.add_hook 'prepare-commit-msg', File.join(File.dirname(__FILE__), 'prepare-commit-msg.sh')
      story.mark_started!
      return 0
    end

    def parse_argv(*args)
      OptionParser.new do |opts|
        opts.banner = "Usage: git start <feature|chore|bug|story_id>"
        opts.on("-t", "--api-token=", "Pivotal Tracker API key") { |k| options[:api_token] = k }
        opts.on("-p", "--project-id=", "Pivotal Tracker project id") { |p| options[:project_id] = p }
        opts.on("-r", "--root-branch-name=", "Root branch name") { |r| options[:root_branch_name] = r }
        opts.on("-f", "--hotfix", "Hotfix") { |h| options[:is_hotfix] = true }

        opts.on_tail("-h", "--help", "This usage guide") { put opts.to_s; exit 0 }
      end.parse!(args)
    end
  end
end
