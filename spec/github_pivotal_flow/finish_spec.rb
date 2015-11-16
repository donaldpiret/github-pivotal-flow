require 'spec_helper'

module GithubPivotalFlow
  describe Finish do
    let(:fake_git) { double('Git').as_null_object }

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      @project = double('project')
      @story = double('story', branch_name: 'feature/1234-sample_story')
      @configuration = double('configuration',
        development_branch: 'development',
        master_branch: 'master',
        feature_prefix: 'feature/',
        hotfix_prefix: 'hotfix/',
        release_prefix: 'release/',
        api_token: 'token',
        project_id: '123',
        project: @project,
        github_client: @ghclient,
        story: @story,
        validate: true
      )
      allow(Configuration).to receive(:new).and_return(@configuration)
      allow(Project).to receive(:find).and_return(@project)
      @finish = Finish.new
      allow(Git).to receive(:current_branch).and_return(@story.branch_name)
      allow(@configuration).to receive(:story).and_return(@story)
    end

    it 'fails if you are on the development branch' do
      allow(Git).to receive(:current_branch).and_return(@configuration.development_branch)
      expect { @finish.run! }.to raise_error("Cannot finish development branch")
    end

    it 'fails if you are on the master branch' do
      allow(Git).to receive(:current_branch).and_return(@configuration.master_branch)
      expect { @finish.run! }.to raise_error("Cannot finish master branch")
    end

    it 'fails if we cannot find the story this branch relates to' do
      allow(@configuration).to receive(:story).and_return(nil)
      expect { @finish.run! }.to raise_error("Could not find story associated with branch")
    end

    it 'merges the branch back to its root by default' do
      expect(@story).to receive(:release?).and_return(false)
      expect(@story).to receive(:can_merge?).and_return(true)
      expect(@story).to receive(:merge_to_roots!).and_return(nil)

      @finish.run!
    end

    it 'merges the branch back to the development branch as well if this is a hotfix' do

    end

    it 'merges as a release instead if it is a release branch' do
      expect(@story).to receive(:release?).and_return(true)
      expect(@story).to receive(:can_merge?).and_return(true)
      expect(@story).to receive(:merge_release!)

      @finish.run!
    end
  end
end
