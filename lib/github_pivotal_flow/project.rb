module GithubPivotalFlow
  class Project < Struct.new(:owner, :name, :host, :configuration)
    attr_accessor :owner, :name, :host, :configuration

    def initialize(*args)
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
      git_url = Git.get_config("remote.#{Git.get_remote}.url")
      if (matchdata = /^git@([a-z0-9\._-]+):([a-z0-9_-]+)\/([a-z0-9_-]+)(\.git)?$/.match(git_url.strip))
        self.host ||= matchdata[1]
        self.owner ||= matchdata[2]
        self.name ||= matchdata[3]
      else
        url = URI(url) if !url.is_a?(URI)
        path_components = url.path.split('/', 4)
        self.owner ||= path_components[1]
        self.name ||= path_components[2]
        self.host ||= url.host
      end
      self.name = self.name.tr(' ', '-').sub(/\.git$/, '')
      self.host ||= 'github.com'
      self.host = host.sub(/^ssh\./i, '') if 'ssh.github.com' == host.downcase
    end

    def name_with_owner
      "#{owner}/#{name}"
    end

    def ==(other)
      name_with_owner == other.name_with_owner
    end

    def pivotal_project
      @pivotal_project ||= PivotalTracker::Project.find(self.configuration.project_id)
    end
  end
end