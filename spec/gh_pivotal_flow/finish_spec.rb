require 'spec_helper'

module GhPivotalFlow
  describe Finish do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      @project = double('project')
      @story = double('story')
      Git.should_receive(:repository_root)
      Configuration.any_instance.should_receive(:api_token)
      Configuration.any_instance.should_receive(:project_id)
      PivotalTracker::Project.should_receive(:find).and_return(@project)
      @finish = Finish.new
    end

    it 'should publish the branch by default' do
      Configuration.any_instance.should_receive(:story).and_return(@story)
      @story.should_receive(:can_merge?).and_return(true)
      @story.should_receive(:publish_branch)

      @finish.run!
    end
  end
end
