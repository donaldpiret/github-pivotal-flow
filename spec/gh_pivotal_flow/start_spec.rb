require 'spec_helper'

describe GhPivotalFlow::Start do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    @story = double('story')
    Git.should_receive(:repository_root)
    Configuration.any_instance.should_receive(:api_token)
    Configuration.any_instance.should_receive(:project_id)
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    @start = Command::Start.new
  end

  it 'should run' do
    Story.should_receive(:select_story).with(@project, 'test_filter').and_return(@story)
    Story.should_receive(:pretty_print)
    @story.should_receive(:id).twice.and_return(12345678)
    @start.should_receive(:ask).and_return('development_branch')
    Git.should_receive(:create_branch).with('12345678-development_branch')
    Configuration.any_instance.should_receive(:story=)
    Git.should_receive(:add_hook)
    Git.should_receive(:get_config).with('user.name').and_return('test_owner')
    @story.should_receive(:update).with(
        :current_state => 'started',
        :owned_by => 'test_owner'
    )

    @start.run 'test_filter'
  end
end
