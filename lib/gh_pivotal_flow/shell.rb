# Utilities for dealing with the shell
module GhPivotalFlow
  class Shell

    # Executes a command
    #
    # @param [String] command the command to execute
    # @param [Boolean] abort_on_failure whether to +Kernel#abort+ with +FAIL+ as
    #   the message when the command's +Status#existstatus+ is not +0+
    # @return [String] the result of the command
    def self.exec(command, abort_on_failure = true)
      result = `#{command}`
      if $?.exitstatus != 0 && abort_on_failure
        abort 'FAIL'
      end

      result
    end
  end
end