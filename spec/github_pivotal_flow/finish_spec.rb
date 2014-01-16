require 'spec_helper'

module GithubPivotalFlow
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

    it 'merges the branch back to its root by default' do
      Configuration.any_instance.should_receive(:story).and_return(@story)
      @story.should_receive(:release?).and_return(false)
      @story.should_receive(:can_merge?).and_return(true)
      @story.should_receive(:merge_to_root!)

      @finish.run!
    end

    it 'merges as a release instead if it is a release branch' do
      Configuration.any_instance.should_receive(:story).and_return(@story)
      @story.should_receive(:release?).and_return(true)
      @story.should_receive(:can_merge?).and_return(true)
      @story.should_receive(:merge_release!)

      @finish.run!
    end
  end
end
