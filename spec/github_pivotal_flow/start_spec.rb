require 'spec_helper'

module GithubPivotalFlow
  describe Start do
    let(:fake_git) { double('Git').as_null_object }
    
    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
      @story = double('story',
        unestimated?: false,
        release?: false
      )
      @project = double('project',
        stories: [@story]
      )
      @ghclient = double('ghclient')
      @ghproject = double('ghproject')
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
      allow(PivotalTracker::Project).to receive(:find).and_return(@project)
      allow(@story).to receive(:create_branch!).and_return(true)
      allow(@configuration).to receive(:story=).with(@story).and_return(true)
      allow(@story).to receive(:mark_started!)
      @start = Start.new()
    end

    it 'selects the story and pretty prints out the options' do
      @start.options[:args] = 'test_filter'
      expect(Story).to receive(:select_story).with(@project, 'test_filter').and_return(@story)
      expect(Story).to receive(:pretty_print)

      @start.run!
    end

    context 'with a story selected' do
      before do
        @start.options[:args] = 'test_filter'
        allow(Story).to receive(:select_story).with(@project, 'test_filter').and_return(@story)
        allow(Story).to receive(:pretty_print)
      end

      it 'should runs correctly' do
        @start.run!
      end

      it 'creates the branch for the story' do
        expect(@story).to receive(:create_branch!)

        @start.run!
      end

      it 'adds the Git hook' do
        expect(Git).to receive(:add_hook)

        @start.run!
      end

      it 'stores the current story in the configuration' do
        expect(@configuration).to receive(:story=).with(@story).and_return(true)

        @start.run!
      end

      it 'marks the story as started in tracker' do
        expect(@story).to receive(:mark_started!)

        @start.run!
      end
    end
  end
end