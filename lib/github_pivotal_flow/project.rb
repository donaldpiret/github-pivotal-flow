module GithubPivotalFlow
  class Project < Struct.new(:owner, :name, :host)
    def self.from_url(url)
      if (matchdata = /^git@([a-z0-9\._-]+):([a-z0-9_-]+)\/([a-z0-9_-]+)(\.git)?$/.match(url.strip))
        host = matchdata[1]
        owner = matchdata[2]
        name = matchdata[3]
      else
        url = URI(url) if !url.is_a?(URI)
        _, owner, name = url.path.split('/', 4)
        host = url.host
      end
      self.new(owner, name.sub(/\.git$/, ''), host)
    end

    def initialize(*args)
      super
      self.name = self.name.tr(' ', '-')
      self.host ||= 'github.com'
      self.host = host.sub(/^ssh\./i, '') if 'ssh.github.com' == host.downcase
    end

    def name_with_owner
      "#{owner}/#{name}"
    end

    def ==(other)
      name_with_owner == other.name_with_owner
    end
  end
end