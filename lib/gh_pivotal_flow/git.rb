module GhPivotalFlow
  class Git
    def self.current_branch
      exec('git branch').scan(/\* (.*)/)[0][0]
    end

    def self.checkout(branch_name)
      exec "git checkout --quiet #{branch_name}" unless branch_name == self.current_branch
    end

    def self.pull(ref, origin)
      exec "git pull --quiet #{[origin, ref].compact.join(' ')}"
    end

    def self.get_remote
      remote = get_config('remote', :branch).strip
      return exec('git remote').strip if remote.blank?
      remote
    end

    def self.pull_remote(branch_name = nil)
      prev_branch = self.current_branch
      branch_name ||= self.current_branch
      self.checkout(branch_name)
      remote = self.get_remote
      self.pull(branch_name, remote) unless remote.blank?
      self.checkout(prev_branch)
    end

    def self.create_branch(branch_name, start_point = nil, options = {})
      return if branch_exists?(branch_name)
      exec "git branch --quiet #{[branch_name, start_point].compact.join(' ')}"
      puts 'OK'
    end

    def self.branch_exists?(name)
      system "git show-ref --quiet --verify refs/heads/#{name}"
    end

    def self.ensure_branch_exists(branch_name)
      return if branch_name == current_branch || self.branch_exists?(branch_name)
      exec "git branch --quiet #{branch_name}", false
    end

    def self.merge(branch_name, options = {})
      command = "git merge --quiet"
      command << " -m \"#{options[:commit_message]}\"" unless options[:commit_message].blank?
      command << " --no-ff" if options[:no_ff]
      exec "#{command} #{branch_name}"
      puts 'OK'
    end

    def self.publish(branch_name)
      branch_name ||= self.current_branch
      exec "git checkout --quiet #{branch_name}" unless branch_name == self.current_branch
      exec "git push #{self.get_remote} #{branch_name}"
    end

    def self.commit(options = {})
      command = "git commit --quiet"
      command << " -m \"#{options[:commit_message]}\"" unless options[:commit_message].blank?
      command << " --allow-empty" if options[:allow_empty]
      exec command
    end

    def self.tag(tag_name)
      exec "git tag #{tag_name}"
    end

    def self.delete_branch(branch_name, options = {})
      command = "git branch"
      command << (options[:force] ? " -D" : " -d")
      exec "#{command} #{branch_name}"
      puts 'OK'
    end

    def self.push(*refs)
      remote = self.get_remote

      print "Pushing to #{remote}... "
      exec "git push --quiet #{remote} " + refs.join(' ')
      puts 'OK'
    end

    def self.push_tags
      exec "git push --tags #{self.get_remote}"
    end

    def self.get_config(key, scope = :inherited)
      if :branch == scope
        exec("git config branch.#{self.current_branch}.#{key}", false).strip
      elsif :inherited == scope
        exec("git config #{key}", false).strip
      else
        raise "Unable to get Git configuration for scope '#{scope}'"
      end
    end

    def self.set_config(key, value, scope = :local)
      if :branch == scope
        exec "git config --local branch.#{self.current_branch}.#{key} #{value}"
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
  end
end