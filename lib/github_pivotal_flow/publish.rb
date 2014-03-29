# The class that encapsulates finishing a Pivotal Tracker Story
module GithubPivotalFlow
  class Publish < Command

    # Publishes the branch and opens the pull request
    def run!
      story = @configuration.story
      fail("Could not find story associated with branch") unless story
      Git.clean_working_tree?
      Git.push(story.branch_name, set_upstream: true)
      unless story.release?
        print "Creating pull-request on Github... "
        pull_request_params = story.params_for_pull_request.merge(project: @configuration.project)
        @configuration.github_client.create_pullrequest(pull_request_params)
        puts 'OK'
      end
      return 0
    end

    private

    def parse_argv(*args)
      OptionParser.new do |opts|
        opts.banner = "Usage: git publish [options]"
        opts.on("-t", "--api-token=", "Pivotal Tracker API key") { |k| options[:api_token] = k }
        opts.on("-p", "--project-id=", "Pivotal Tracker project id") { |p| options[:project_id] = p }

        opts.on_tail("-h", "--help", "This usage guide") { put opts.to_s; exit 0 }
      end.parse!(args)
    end
  end
end
