module GithubPivotalFlow
  class Project
    attr_accessor :owner, :name, :host, :config

    def self.find(id)
      id = id.to_i if id.is_a?(String)
      return PivotalTracker::Project.find(id)
    end

    def initialize(args = {})
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
      url = Git.get_config("remote.#{Git.get_remote}.url")
      if (matchdata = /^git@([a-z0-9\._-]+):([a-z0-9_-]+)\/([a-z0-9_-]+)(\.git)?$/i.match(url.strip))
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
      self.name = self.name.tr(' ', '-').sub(/\.git$/, '') if self.name
      self.name ||= File.basename(Dir.getwd)
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
      @pivotal_project ||= self.class.find(self.config.project_id)
    end

    def method_missing(m, *args, &block)
      return pivotal_project.send(m, *args, &block)
    end
  end
end
