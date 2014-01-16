# An abstract base class for all commands
# @abstract Subclass and override {#run} to implement command functionality
module GithubPivotalFlow
  class Command

    attr_reader :options, :configuration

    # Common initialization functionality for all command classes.  This
    # enforces that:
    # * the command is being run within a valid Git repository
    # * the user has specified their Pivotal Tracker API token
    # * all communication with Pivotal Tracker will be protected with SSL
    # * the user has configured the project id for this repository
    def initialize(*args)
      @options = {}
      args = parse_argv(*args)
      @options[:args] = args

      @repository_root = Git.repository_root
      @configuration = Configuration.new

      PivotalTracker::Client.token = @configuration.api_token
      PivotalTracker::Client.use_ssl = true

      @project = PivotalTracker::Project.find @configuration.project_id

      # Make sure that all the git flow config options are set up
      @configuration.development_branch
      @configuration.master_branch
      @configuration.feature_prefix
      @configuration.hotfix_prefix
    end

    # The main entry point to the command's execution
    # @abstract Override this method to implement command functionality
    def run!
      raise NotImplementedError
    end

    protected

    def parse_argv(*args)
      OptionParser.new do |opts|
        opts.banner = "Usage: git start <feature|chore|bug|story_id> | git finish"
        opts.on("-t", "--api-token=", "Pivotal Tracker API key") { |k| options[:api_token] = k }
        opts.on("-p", "--project-id=", "Pivotal Tracker project id") { |p| options[:project_id] = p }
        opts.on("-n", "--full-name=", "Your Pivotal Tracker full name") { |n| options[:full_name] = n }
        opts.on_tail("-h", "--help", "This usage guide") { put opts.to_s; exit 0 }
      end.parse!(args)
    end

    def current_branch_name
      Git.branch_name
    end

  end
end
