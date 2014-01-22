require 'spec_helper'

module GithubPivotalFlow
  describe Finish do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      @project = double('project')
      @story = double('story')
      @configuration = double('configuration')
      @configuration.stub(
          development_branch: 'development',
          master_branch: 'master',
          feature_prefix: 'feature/',
          hotfix_prefix: 'hotfix/',
          release_prefix: 'release/',
          api_token: 'token',
          project_id: '123',
          story: @story)
      allow(Git).to receive(:repository_root)
      allow(Configuration).to receive(:new).and_return(@configuration)
      allow(PivotalTracker::Project).to receive(:find).and_return(@project)
      @finish = Finish.new
    end

    it 'merges the branch back to its root by default' do
      expect(@story).to receive(:release?).and_return(false)
      expect(@story).to receive(:can_merge?).and_return(true)
      expect(@story).to receive(:merge_to_root!).and_return(nil)

      @finish.run!
    end

    it 'merges as a release instead if it is a release branch' do
      expect(@story).to receive(:release?).and_return(true)
      expect(@story).to receive(:can_merge?).and_return(true)
      expect(@story).to receive(:merge_release!)

      @finish.run!
    end
  end
end
