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

    it 'return a story when requested' do
      project = double('project')
      stories = double('stories')
      story = double('story')
      Git.should_receive(:get_config).with('pivotal-story-id', :branch).and_return('12345678')
      project.should_receive(:stories).and_return(stories)
      stories.should_receive(:find).with(12345678).and_return(story)

      result = @configuration.story project

      expect(result).to be_a(Story)
    end
  end
end