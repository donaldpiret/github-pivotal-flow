require 'spec_helper'

module GithubPivotalFlow
  describe Start do
    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      @project = double('project')
      @story = double('story')
      @ghclient = double('ghclient')
      @ghproject = double('ghproject')
      @configuration = double('configuration')
      @configuration.stub(
          development_branch: 'development',
          master_branch: 'master',
          feature_prefix: 'feature/',
          hotfix_prefix: 'hotfix/',
          release_prefix: 'release/',
          api_token: 'token',
          project_id: '123',
          github_project: @ghproject,
          story: @story)
      allow(Git).to receive(:repository_root)
      allow(GitHubAPI).to receive(:new).and_return(@ghclient)
      allow(Configuration).to receive(:new).and_return(@configuration)
      allow(PivotalTracker::Project).to receive(:find).and_return(@project)
      @start = Start.new()
    end

    it 'should run' do
      @start.options[:args] = 'test_filter'
      @story.stub(:unestimated? => false, :release? => false, params_for_pull_request: {})

      expect(Story).to receive(:select_story).with(@project, 'test_filter').and_return(@story)
      expect(Story).to receive(:pretty_print)
      expect(@story).to receive(:create_branch!)
      expect(Git).to receive(:add_hook)
      expect(@configuration).to receive(:story=).with(@story).and_return(true)
      #@story.should_receive(:params_for_pull_request).and_return({})
      expect(@ghclient).to receive(:create_pullrequest)
      expect(@story).to receive(:mark_started!)

      @start.run!
    end
  end
end