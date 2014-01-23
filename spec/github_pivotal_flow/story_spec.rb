require 'spec_helper'

module GithubPivotalFlow
  describe Story do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      @project = double('project')
      @stories = double('stories')
      @story = double('story')
      @pivotal_story = double('pivotal_story')
      @pivotal_project = double('pivotal_project')
      @menu = double('menu')
      allow(@project).to receive(:pivotal_project).and_return(@pivotal_project)
      allow(@pivotal_project).to receive(:stories).and_return(@stories)
    end

    describe '.pretty_print' do
      it 'pretty-prints story information' do
        story = double('story')
        story.should_receive(:name)
        story.should_receive(:description).and_return("description-1\ndescription-2")
        PivotalTracker::Note.should_receive(:all).and_return([PivotalTracker::Note.new(:noted_at => Date.new, :text => 'note-1')])

        Story.pretty_print story

        expect($stdout.string).to eq(
                                      "      Title: \n" +
                                          "Description: description-1\n" +
                                          "             description-2\n" +
                                          "     Note 1: note-1\n" +
                                          "\n")
      end

      it 'does not pretty print description or notes if there are none (empty)' do
        story = double('story')
        story.should_receive(:name)
        story.should_receive(:description)
        PivotalTracker::Note.should_receive(:all).and_return([])

        Story.pretty_print story

        expect($stdout.string).to eq(
                                      "      Title: \n" +
                                          "\n")
      end

      it 'does not pretty print description or notes if there are none (nil)' do
        story = double('story')
        story.should_receive(:name)
        story.should_receive(:description).and_return('')
        PivotalTracker::Note.should_receive(:all).and_return([])

        Story.pretty_print story

        expect($stdout.string).to eq(
                                      "      Title: \n" +
                                          "\n")
      end
    end

    describe '.select_story' do
      it 'selects a story directly if the filter is a number' do
        expect(@stories).to receive(:find).with(12345678).and_return(@pivotal_story)
        story = Story.select_story @project, '12345678'

        expect(story).to be_a(Story)
        expect(story.pivotal_story).to eq(@pivotal_story)
      end

      it 'selects a story if the result of the query is a single story' do
        expect(@stories).to receive(:all).with(
            :current_state => %w(rejected unstarted unscheduled),
            :limit => 1,
            :story_type => 'release'
        ).and_return([@pivotal_story])

        story = Story.select_story @project, 'release', 1

        expect(story).to be_a(Story)
        expect(story.pivotal_story).to eq(@pivotal_story)
      end

      it 'prompts the user for a story if the result of the query is more than a single story' do
        expect(@stories).to receive(:all).with(
            :current_state => %w(rejected unstarted unscheduled),
            :limit => 5,
            :story_type => 'feature'
        ).and_return([
                         PivotalTracker::Story.new(:name => 'name-1'),
                         PivotalTracker::Story.new(:name => 'name-2')
                     ])
        expect(@menu).to receive(:prompt=)
        expect(@menu).to receive(:choice).with('name-1')
        expect(@menu).to receive(:choice).with('name-2')
        expect(Story).to receive(:choose) { |&arg| arg.call @menu }.and_return(@pivotal_story)

        story = Story.select_story @project, 'feature'

        expect(story).to be_a(Story)
        expect(story.pivotal_story).to eq(@pivotal_story)
      end

      it 'prompts the user with the story type if no filter is specified' do
        expect(@stories).to receive(:all).with(
            :current_state => %w(rejected unstarted unscheduled),
            :limit => 5
        ).and_return([
                         PivotalTracker::Story.new(:story_type => 'chore', :name => 'name-1'),
                         PivotalTracker::Story.new(:story_type => 'bug', :name => 'name-2')
                     ])
        expect(@menu).to receive(:prompt=)
        expect(@menu).to receive(:choice).with('CHORE   name-1')
        expect(@menu).to receive(:choice).with('BUG     name-2')
        expect(Story).to receive(:choose) { |&arg| arg.call @menu }.and_return(@pivotal_story)

        story = Story.select_story @project

        expect(story).to be_a(Story)
        expect(story.pivotal_story).to eq(@pivotal_story)
      end
    end

    describe '#create_branch!' do
      before do
        Git.stub(
          checkout: nil,
          pull_remote: nil,
          create_branch: nil,
          set_config: nil,
          get_config: nil,
          push: nil,
          commit: nil,
          get_remote: 'origin',
        )
        @pivotal_story.stub(
            story_type: 'feature',
            id: '123456',
            name: 'test',
            description: 'description')
        @story = GithubPivotalFlow::Story.new(@project, @pivotal_story)
        allow(@story).to receive(:ask).and_return('test')
      end

      it 'prompts the user for a branch extension name' do
        allow(@story).to receive(:branch_prefix).and_return('feature/')
        expect(@story).to receive(:ask).with("Enter branch name (feature/123456-<branch-name>): ").and_return('super-branch')

        @story.create_branch!('Message')
      end

      it 'includes a tag to skip the ci build for the initial blank commit' do
        @story.stub(branch_name: 'feature/123456-my_branch')
        expect(Git).to receive(:commit).with(hash_including(commit_message: 'Message [ci skip]')).and_return(true)

        @story.create_branch!('Message')
      end

      it 'pushes the local branch and sets the upstream using the -u flag' do
        @story.stub(branch_name: 'feature/123456-my_branch')
        expect(Git).to receive(:push).with(instance_of(String), hash_including(set_upstream: true))

        @story.create_branch!('Message')
      end
    end
  end
end