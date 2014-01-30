# The class that encapsulates finishing a Pivotal Tracker Story
module GithubPivotalFlow
  class Finish < Command

    # Finishes a Pivotal Tracker story
    def run!
      raise_error_if_development_or_master
      story = @configuration.story
      fail("Could not find story associated with branch") unless story
      story.can_merge?
      commit_message = options[:commit_message]
      if story.release?
        story.merge_release!(commit_message, @options)
      else
        story.merge_to_root!(commit_message, @options)
      end
      return 0
    end

    private

    def raise_error_if_development_or_master
      fail("Cannot finish development branch") if Git.current_branch == @configuration.development_branch
      fail("Cannot finish master branch") if Git.current_branch == @configuration.master_branch
    end

    def parse_argv(*args)
      OptionParser.new do |opts|
        opts.banner = "Usage: git finish [options]"
        opts.on("-t", "--api-token=", "Pivotal Tracker API key") { |k| options[:api_token] = k }
        opts.on("-p", "--project-id=", "Pivotal Tracker project id") { |p| options[:project_id] = p }
        opts.on("-m", "--message=", "Specify a commit message") { |m| options[:commit_message] = m }

        opts.on("--no-complete", "Do not mark the story completed on Pivotal Tracker") { options[:no_complete] = true }
        opts.on_tail("-h", "--help", "This usage guide") { put opts.to_s; exit 0 }
      end.parse!(args)
    end
  end
end
