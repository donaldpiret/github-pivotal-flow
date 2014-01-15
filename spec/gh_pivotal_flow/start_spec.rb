require 'spec_helper'

module GhPivotalFlow
  describe Start do
    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      @project = double('project')
      @story = double('story')
      Git.should_receive(:repository_root)
      Configuration.any_instance.should_receive(:api_token)
      Configuration.any_instance.should_receive(:project_id)
      PivotalTracker::Project.should_receive(:find).and_return(@project)
      @start = Start.new()
    end

    it 'should run' do
      @start.options[:args] = 'test_filter'
      Story.should_receive(:select_story).with(@project, 'test_filter').and_return(@story)
      Story.should_receive(:pretty_print)
      @story.should_receive(:create_branch)
      Configuration.any_instance.should_receive(:story=)
      Git.should_receive(:add_hook)
      @story.should_receive(:mark_started!)

      @start.run!
    end

    describe "create_branch" do
      pending
      #Git.should_receive(:get_config).with('user.name').and_return('test_owner')

    end
  end
end