# The class that encapsulates finishing a Pivotal Tracker Story
module GhPivotalFlow
  class Finish < Command

    # Finishes a Pivotal Tracker story by doing the following steps:
    # * Check that the pending merge will be trivial
    # * Merge the development branch into the root branch
    # * Delete the development branch
    # * Push changes to remote
    #
    # @return [void]
    def run!
      puts @options
      story = @configuration.story(@project)
      story.can_merge?
      commit_message = @options[:args].last.dup if @options[:args].last
      if @options[:merge]
        story.merge_to_root(commit_message, @options)
        Git.publish(story.root_branch_name)
      else
        story.publish_branch(commit_message, @options)
        story.create_pull_request(commit_message)
      end
      return 0
    end

    private

    def parse_argv(*args)
      OptionParser.new do |opts|
        opts.banner = "Usage: git finish [options]"
        opts.on("-t", "--api-token=", "Pivotal Tracker API key") { |k| options[:api_token] = k }
        opts.on("-p", "--project-id=", "Pivotal Tracker project id") { |p| options[:project_id] = p }
        opts.on("-n", "--full-name=", "Your Pivotal Tracker full name") { |n| options[:full_name] = n }

        opts.on("-c", "--no-complete", "Do not mark the story completed on Pivotal Tracker") { options[:no_complete] = true }
        opts.on("-m", "--merge", "Merge branch instead of creating a pull request") { options[:merge] = true }
        opts.on_tail("-h", "--help", "This usage guide") { put opts.to_s; exit 0 }
      end.parse!(args)
    end
  end
end
