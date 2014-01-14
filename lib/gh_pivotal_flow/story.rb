# Utilities for dealing with +PivotalTracker::Story+s
module GhPivotalFlow
  class Story
    attr_accessor :story, :branch_name, :root_branch_name

    # Print a human readable version of a story.  This pretty prints the title,
    # description, and notes for the story.
    #
    # @param [PivotalTracker::Story] story the story to pretty print
    # @return [void]
    def self.pretty_print(story)
      print_label LABEL_TITLE
      print_value story.name

      description = story.description
      if !description.nil? && !description.empty?
        print_label 'Description'
        print_value description
      end

      PivotalTracker::Note.all(story).sort_by { |note| note.noted_at }.each_with_index do |note, index|
        print_label "Note #{index + 1}"
        print_value note.text
      end

      puts
    end

    # Selects a Pivotal Tracker story by doing the following steps:
    #
    # @param [PivotalTracker::Project] project the project to select stories from
    # @param [String, nil] filter a filter for selecting the story to start.  This
    #   filter can be either:
    #   * a story id: selects the story represented by the id
    #   * a story type (feature, bug, chore): offers the user a selection of stories of the given type
    #   * +nil+: offers the user a selection of stories of all types
    # @param [Fixnum] limit The number maximum number of stories the user can choose from
    # @return [PivotalTracker::Story] The Pivotal Tracker story selected by the user
    def self.select_story(project, filter = nil, limit = 5)
      if filter =~ /[[:digit:]]/
        story = project.stories.find filter.to_i
      else
        story = find_story project, filter, limit
      end
      self.new(story)
    end

    # @param [PivotalTracker::Story] story the story to wrap
    def initialize(story, options = {})
      raise "Invalid PivotalTracker::Story" if story.nil?
      @story = story
      @branch_name = options.delete(:branch_name)
      @branch_suffix = @branch_name.split('-').last if @branch_name
      @branch_suffix ||= ''
    end

    def mark_started!
      print 'Starting story on Pivotal Tracker... '
      self.story.update(
          :current_state => 'started',
          :owned_by => Git.get_config('user.name', :inherited)
      )
      puts 'OK'
    end

    def mark_finished!

    end

    def create_branch
      set_branch_suffix
      puts "Creating branch for story with branch name #{branch_name} pointing to #{root_branch_name}"
      Git.create_branch(branch_name, root_branch_name)
    end

    def merge_to_root(commit_message = nil, options = {})
      commit_message ||= "Merge #{branch_name} to #{root_branch_name}"
      commit_message << "\n\n[#{options[:no_complete] ? '' : 'Completes '}##{story.id}]"
      puts "Merging #{branch_name} to #{root_branch_name}... "
      Git.merge(branch_name, commit_message)
      self.delete_branch
    end

    def publish_branch(commit_message = '', options = {})
      commit_message << "\n\n" if commit_message.length > 0
      commit_message << "[#{options[:no_complete] ? '' : 'Completes '}##{story.id}]"
      puts "Updating #{branch_name} and pushing to remote..."
      Git.update(branch_name, commit_message)
      Git.publish(branch_name)
    end

    def delete_branch
      puts "Deleting #{branch_name}... "
      Git.delete_branch(branch_name)
    end

    def set_branch_suffix
      @branch_suffix = ask("Enter branch name (#{branch_prefix}/#{story.id}-<branch-name>): ")
    end

    def branch_name
      return @branch_name if @branch_name
      branch_name = "#{branch_prefix}/#{story.id}"
      branch_name << "-#{@branch_suffix}" if @branch_suffix.length > 0
      puts
      (@branch_name = branch_name)
    end

    def root_branch_name
      case self.story_type
      when 'chore'
        'master'
      when 'bug'
        self.labels.include?('hotfix') ? 'master' : 'development'
      else
        'development'
      end
    end

    def labels
      @story.labels.split(',').collect(&:strip)
    end

    def method_missing(m, *args, &block)
      return @story.send(m, *args, &block)
    end

    def can_merge?
      print "Checking for trivial merge from #{branch_name} to #{root_branch_name}... "
      Git.pull_remote(root_branch_name)
      root_tip = Shell.exec "git rev-parse #{root_branch_name}"
      common_ancestor = Shell.exec "git merge-base #{root_branch_name} #{branch_name}"

      if root_tip != common_ancestor
        abort 'FAIL'
      end

      puts 'OK'
    end

    private
    CANDIDATE_STATES = %w(rejected unstarted unscheduled).freeze
    LABEL_DESCRIPTION = 'Description'.freeze
    LABEL_TITLE = 'Title'.freeze
    LABEL_WIDTH = (LABEL_DESCRIPTION.length + 2).freeze
    CONTENT_WIDTH = (HighLine.new.output_cols - LABEL_WIDTH).freeze

    def self.print_label(label)
      print "%#{LABEL_WIDTH}s" % ["#{label}: "]
    end

    def self.print_value(value)
      if value.nil? || value.empty?
        puts ''
      else
        value.scan(/\S.{0,#{CONTENT_WIDTH - 2}}\S(?=\s|$)|\S+/).each_with_index do |line, index|
          if index == 0
            puts line
          else
            puts "%#{LABEL_WIDTH}s%s" % ['', line]
          end
        end
      end
    end

    def self.find_story(project, type, limit)
      criteria = {
          :current_state => CANDIDATE_STATES,
          :limit => limit
      }
      if type
        criteria[:story_type] = type
      end

      candidates = project.stories.all criteria
      if candidates.length == 1
        story = candidates[0]
      else
        story = choose do |menu|
          menu.prompt = 'Choose story to start: '

          candidates.each do |story|
            name = type ? story.name : '%-7s %s' % [story.story_type.upcase, story.name]
            menu.choice(name) { story }
          end
        end

        puts
      end

      story
    end

    def branch_prefix
      case self.story_type
      when 'feature'
        'feature'
      when 'bug'
        self.labels.include?('hotfix') ? 'hotfix' : 'feature'
      when 'release'
        'release'
      when 'chore'
        'chore'
      else
        'misc'
      end
    end
  end
end