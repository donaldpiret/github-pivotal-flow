require 'spec_helper'

module GithubPivotalFlow
  describe Configuration do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
      @configuration = Configuration.new
    end

    it 'does not prompt the user for the API token if it is already configured' do
      Git.should_receive(:get_config).with('pivotal.api-token', :inherited).and_return('test_api_token')

      api_token = @configuration.api_token

      expect(api_token).to eq('test_api_token')
    end

    it 'prompts the user for the API token if it is not configured' do
      Git.should_receive(:get_config).with('pivotal.api-token', :inherited).and_return('')
      @configuration.should_receive(:ask).and_return('test_api_token')
      Git.should_receive(:set_config).with('pivotal.api-token', 'test_api_token', :global)
      api_token = @configuration.api_token
      expect(api_token).to eq('test_api_token')
    end

    it 'does not prompt the user for the project id if it is already configured' do
      Git.should_receive(:get_config).with('pivotal.project-id', :inherited).and_return('test_project_id')
      project_id = @configuration.project_id
      expect(project_id).to eq('test_project_id')
    end

    it 'prompts the user for the API token if it is not configured' do
      Git.should_receive(:get_config).with('pivotal.project-id', :inherited).and_return('')
      menu = double('menu')
      menu.should_receive(:prompt=)
      PivotalTracker::Project.should_receive(:all).and_return([
                                                                  PivotalTracker::Project.new(:id => 'id-2', :name => 'name-2'),
                                                                  PivotalTracker::Project.new(:id => 'id-1', :name => 'name-1')])
      menu.should_receive(:choice).with('name-1')
      menu.should_receive(:choice).with('name-2')
      @configuration.should_receive(:choose) { |&arg| arg.call menu }.and_return('test_project_id')
      Git.should_receive(:set_config).with('pivotal.project-id', 'test_project_id', :local)

      project_id = @configuration.project_id

      expect(project_id).to eq('test_project_id')
    end

    it 'persists the story when requested' do
      Git.should_receive(:set_config).with('pivotal-story-id', 12345678, :branch)

      @configuration.story = Story.new(PivotalTracker::Story.new(:id => 12345678))
    end

    describe 'story' do
      it 'fetches the story based on the story id stored inside the git config' do
        project = double('project')
        stories = double('stories')
        story = double('story')
        Git.should_receive(:get_config).with('pivotal-story-id', :branch).and_return('12345678')
        project.should_receive(:stories).and_return(stories)
        stories.should_receive(:find).with(12345678).and_return(story)

        result = @configuration.story project

        expect(result.story).to eq(story)
      end

      it 'uses the branch name to deduce the story id if no git config is found' do
        project = double('project')
        stories = double('stories')
        story = double('story')
        Git.stub(:current_branch).and_return('feature/12345678-sample_feature')
        Git.should_receive(:get_config).with('pivotal-story-id', :branch).and_return(' ')
        project.should_receive(:stories).and_return(stories)
        stories.should_receive(:find).with(12345678).and_return(story)

        result = @configuration.story project

        expect(result.story).to eq(story)
      end

      it 'prompts for the story id if the branch name does not match the known format' do
        project = double('project')
        stories = double('stories')
        story = double('story')
        Git.stub(:current_branch).and_return('unknownformat')
        Git.should_receive(:get_config).with('pivotal-story-id', :branch).and_return(' ')
        @configuration.should_receive(:ask).and_return('12345678')
        Git.should_receive(:set_config).with('pivotal-story-id', '12345678', :branch)
        project.should_receive(:stories).and_return(stories)
        stories.should_receive(:find).with(12345678).and_return(story)

        result = @configuration.story project

        expect(result.story).to eq(story)
      end
    end

    describe 'github_project' do
      it 'supports working with git urls from the configuration' do
        Git.should_receive(:get_remote).and_return('origin')
        Git.should_receive(:get_config).with('remote.origin.url').and_return('git@github.com:roomorama/github-pivotal-flow.git')
        github_project = @configuration.github_project
        expect(github_project.owner).to eq('roomorama')
        expect(github_project.name).to eq('github-pivotal-flow')
      end
    end
  end
end