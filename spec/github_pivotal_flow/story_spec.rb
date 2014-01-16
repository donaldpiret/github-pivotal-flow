require 'spec_helper'

module GithubPivotalFlow
  describe Story do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new

      @project = double('project')
      @stories = double('stories')
      @story = double('story')
      @menu = double('menu')
    end

    it 'should pretty print story information' do
      story = double('story')
      story.should_receive(:name)
      story.should_receive(:description).and_return("description-1\ndescription-2")
      PivotalTracker::Note.should_receive(:all).and_return([
                                                               PivotalTracker::Note.new(:noted_at => Date.new, :text => 'note-1')
                                                           ])

      Story.pretty_print story

      expect($stdout.string).to eq(
                                    "      Title: \n" +
                                        "Description: description-1\n" +
                                        "             description-2\n" +
                                        "     Note 1: note-1\n" +
                                        "\n")
    end

    it 'should not pretty print description or notes if there are none (empty)' do
      story = double('story')
      story.should_receive(:name)
      story.should_receive(:description)
      PivotalTracker::Note.should_receive(:all).and_return([])

      Story.pretty_print story

      expect($stdout.string).to eq(
                                    "      Title: \n" +
                                        "\n")
    end

    it 'should not pretty print description or notes if there are none (nil)' do
      story = double('story')
      story.should_receive(:name)
      story.should_receive(:description).and_return('')
      PivotalTracker::Note.should_receive(:all).and_return([])

      Story.pretty_print story

      expect($stdout.string).to eq(
                                    "      Title: \n" +
                                        "\n")
    end

    it 'should select a story directly if the filter is a number' do
      @project.should_receive(:stories).and_return(@stories)
      @stories.should_receive(:find).with(12345678).and_return(@story)

      story = Story.select_story @project, '12345678'

      expect(story).to be_a(Story)
      expect(story.story).to be(@story)
    end

    it 'should select a story if the result of the query is a single story' do
      @project.should_receive(:stories).and_return(@stories)
      @stories.should_receive(:all).with(
          :current_state => %w(rejected unstarted unscheduled),
          :limit => 1,
          :story_type => 'release'
      ).and_return([@story])

      story = Story.select_story @project, 'release', 1

      expect(story).to be_a(Story)
      expect(story.story).to be(@story)
    end

    it 'should prompt the user for a story if the result of the query is more than a single story' do
      @project.should_receive(:stories).and_return(@stories)
      @stories.should_receive(:all).with(
          :current_state => %w(rejected unstarted unscheduled),
          :limit => 5,
          :story_type => 'feature'
      ).and_return([
                       PivotalTracker::Story.new(:name => 'name-1'),
                       PivotalTracker::Story.new(:name => 'name-2')
                   ])
      @menu.should_receive(:prompt=)
      @menu.should_receive(:choice).with('name-1')
      @menu.should_receive(:choice).with('name-2')
      Story.should_receive(:choose) { |&arg| arg.call @menu }.and_return(@story)

      story = Story.select_story @project, 'feature'

      expect(story).to be_a(Story)
      expect(story.story).to be(@story)
    end

    it 'should prompt the user with the story type if no filter is specified' do
      @project.should_receive(:stories).and_return(@stories)
      @stories.should_receive(:all).with(
          :current_state => %w(rejected unstarted unscheduled),
          :limit => 5
      ).and_return([
                       PivotalTracker::Story.new(:story_type => 'chore', :name => 'name-1'),
                       PivotalTracker::Story.new(:story_type => 'bug', :name => 'name-2')
                   ])
      @menu.should_receive(:prompt=)
      @menu.should_receive(:choice).with('CHORE   name-1')
      @menu.should_receive(:choice).with('BUG     name-2')
      Story.should_receive(:choose) { |&arg| arg.call @menu }.and_return(@story)

      story = Story.select_story @project

      expect(story).to be_a(Story)
      expect(story.story).to be(@story)
    end
  end
end