module GhPivotalFlow
  class Project < Struct.new(:owner, :name, :host)
    def self.from_url(url)
      _, owner, name = url.path.split('/', 4)
      self.new(owner, name.sub(/\.git$/, ''), url.host)
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