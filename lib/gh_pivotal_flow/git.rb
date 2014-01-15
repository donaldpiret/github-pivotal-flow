module GhPivotalFlow
  class Git

    # Returns the name of the currently checked out branch
    #
    # @return [String] the name of the currently checked out branch
    def self.branch_name
      exec('git branch').scan(/\* (.*)/)[0][0]
    end

    # Creates a branch with a given +name+.  First pulls the current branch to
    # ensure that it is up to date and then creates and checks out the new
    # branch.  If specified, sets branch-specific properties that are passed in.
    #
    # @param [String] name the name of the branch to create
    # @param [Boolean] print_messages whether to print messages
    # @return [void]
    def self.create_branch(name, origin_branch_name = nil, options = {})
      root_branch = (origin_branch_name || self.branch_name)
      exec "git checkout --quiet #{root_branch}"

      root_remote = get_config(KEY_REMOTE, :branch)
      unless root_remote.blank? || name == root_branch
        print "Pulling #{root_branch}... "
        exec "git pull #{root_remote} #{root_branch} --quiet"
        puts 'OK'
      end

      print "Creating and checking out #{name}... "
      exec "git checkout --quiet -b #{name}"
      set_config(KEY_ROOT_BRANCH, root_branch, :branch)
      set_config(KEY_ROOT_REMOTE, root_remote, :branch) unless root_remote.blank?
      puts 'OK'
    end

    def self.ensure_branch_exists(branch)
      return if self.branch_name == branch
      exec("git branch --quiet #{branch}", false)
    end

    # Creates a commit with a given message.  The commit includes all change
    # files.
    #
    # @param [String] message The commit message, which will be appended with
    #   +[#<story-id]+
    # @param [PivotalTracker::Story] story the story associated with the current
    #   commit
    # @return [void]
    def self.create_commit(message, story)
      exec "git commit --quiet --all --allow-empty --message \"#{message}\n\n[##{story.id}]\""
    end

    # Creates a tag with the given name.  Before creating the tag, commits all
    # outstanding changes with a commit message that reflects that these changes
    # are for a release.
    #
    # @param [String] name the name of the tag to create
    # @param [PivotalTracker::Story] story the story associated with the current
    #   tag
    # @return [void]
    def self.create_release_tag(name, story)
      root_branch = branch_name

      print "Creating tag v#{name}... "

      create_branch RELEASE_BRANCH_NAME, nil, false
      create_commit "#{name} Release", story
      exec "git tag v#{name}"
      exec "git checkout --quiet #{root_branch}"
      exec "git branch --quiet -D #{RELEASE_BRANCH_NAME}"

      puts 'OK'
    end

    def self.pull_remote(branch)
      current_branch = self.branch_name
      return if branch == current_branch
      exec "git checkout --quiet #{branch}"
      remote = get_config KEY_ROOT_REMOTE, :branch
      unless remote.blank?
        exec 'git pull --quiet --ff-only'
      end
      exec "git checkout --quiet #{current_branch}"
    end

    def self.merge(name = nil, commit_message = nil)
      name ||= self.branch_name
      exec "git checkout --quiet #{name}"
      target_branch = get_config KEY_ROOT_BRANCH, :branch
      self.pull_remote(target_branch)
      exec "git checkout --quiet #{target_branch}"
      command = "git merge --quiet --no-ff"
      command << " -m \"#{commit_message}\"" if commit_message
      exec "#{command} #{name}"
      puts 'OK'
    end

    # Update the branch from it's target branch.
    # Start by checking out the branch, read the config for the target branch
    # Check if the target branch has a remote. If so pull down the changes
    # Then merge the target branch back into the main branch.
    def self.update(branch_name = nil, commit_message = nil)
      branch_name ||= self.branch_name
      exec "git checkout --quiet #{branch_name}"
      target_branch = get_config KEY_ROOT_BRANCH, :branch
      self.pull_remote(target_branch)
      command = "git merge --quiet --no-ff"
      command << " -m \"#{commit_message}\"" if commit_message
      exec "#{command} #{target_branch}"
      puts 'OK'
    end

    def self.publish(branch_name)
      branch_name ||= self.branch_name
      exec "git checkout --quiet #{branch_name}"
      root_remote = get_config KEY_REMOTE, :branch
      root_remote = exec("git remote").strip if root_remote.blank?
      exec "git push #{root_remote} #{branch_name}"
    end

    def self.delete_branch(branch_name)
      exec "git branch --quiet -D #{branch_name}"
      puts 'OK'
    end

    # Push changes to the remote of the current branch
    #
    # @param [String] refs the explicit references to push
    # @return [void]
    def self.push(*refs)
      remote = get_config KEY_REMOTE, :branch

      print "Pushing to #{remote}... "
      exec "git push --quiet #{remote} " + refs.join(' ')
      puts 'OK'
    end

    # Returns a Git configuration value.  This value is read using the +git
    # config+ command. The scope of the value to read can be controlled with the
    # +scope+ parameter.
    #
    # @param [String] key the key of the configuration to retrieve
    # @param [:branch, :inherited] scope the scope to read the configuration from
    #   * +:branch+: equivalent to calling +git config branch.branch-name.key+
    #   * +:inherited+: equivalent to calling +git config key+
    # @return [String] the value of the configuration
    # @raise if the specified scope is not +:branch+ or +:inherited+
    def self.get_config(key, scope = :inherited)
      if :branch == scope
        exec("git config branch.#{branch_name}.#{key}", false).strip
      elsif :inherited == scope
        exec("git config #{key}", false).strip
      else
        raise "Unable to get Git configuration for scope '#{scope}'"
      end
    end

    # Sets a Git configuration value.  This value is set using the +git config+
    # command.  The scope of the set value can be controlled with the +scope+
    # parameter.
    #
    # @param [String] key the key of configuration to store
    # @param [String] value the value of the configuration to store
    # @param [:branch, :global, :local] scope the scope to store the configuration value in.
    #   * +:branch+: equivalent to calling +git config --local branch.branch-name.key value+
    #   * +:global+: equivalent to calling +git config --global key value+
    #   * +:local+:  equivalent to calling +git config --local key value+
    # @return [void]
    # @raise if the specified scope is not +:branch+, +:global+, or +:local+
    def self.set_config(key, value, scope = :local)
      if :branch == scope
        exec "git config --local branch.#{branch_name}.#{key} #{value}"
      elsif :global == scope
        exec "git config --global #{key} #{value}"
      elsif :local == scope
        exec "git config --local #{key} #{value}"
      else
        raise "Unable to set Git configuration for scope '#{scope}'"
      end
    end

    def self.repository_root
      repository_root = Dir.pwd

      until Dir.entries(repository_root).any? { |child| File.directory?(child) && (child =~ /^.git$/) }
        next_repository_root = File.expand_path('..', repository_root)
        abort('Current working directory is not in a Git repository') unless repository_root != next_repository_root
        repository_root =  next_repository_root
      end
      repository_root
    end

    def self.add_hook(name, source, overwrite = false)
      hooks_directory =  File.join repository_root, '.git', 'hooks'
      hook = File.join hooks_directory, name

      if overwrite || !File.exist?(hook)
        print "Creating Git hook #{name}...  "

        FileUtils.mkdir_p hooks_directory
        File.open(source, 'r') do |input|
          File.open(hook, 'w') do |output|
            output.write(input.read)
            output.chmod(0755)
          end
        end

        puts 'OK'
      end
    end

    private
    def self.exec(command, abort_on_failure = true)
      return Shell.exec(command, abort_on_failure)
    end

    KEY_REMOTE = 'remote'.freeze
    KEY_ROOT_BRANCH = 'root-branch'.freeze
    KEY_ROOT_REMOTE = 'root-remote'.freeze
    RELEASE_BRANCH_NAME = 'pivotal-tracker-release'.freeze
  end
end