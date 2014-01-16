module GhPivotalFlow
  class Flow
    private
    def self.exec(command, abort_on_failure = true)
      return Shell.exec(command, abort_on_failure)
    end
  end
end