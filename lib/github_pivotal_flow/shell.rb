module GithubPivotalFlow
  class Shell
    def self.exec(command, abort_on_failure = true)
      result = `#{command}`
      if $?.exitstatus != 0 && abort_on_failure
        print "Failed command: #{command} "
        abort 'FAIL'
      end

      result
    end
  end
end