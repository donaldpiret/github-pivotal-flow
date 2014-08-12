# Utilities for dealing with +PivotalTracker::Story+s
module GithubPivotalFlow
  class Story
    attr_accessor :pivotal_story, :project, :branch_name, :root_branch_name

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
    # @param [Project] project the project to select stories from
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
      self.new(project, story)
    end

    # @param [Project] project the Project for this repo
    # @param [PivotalTracker::Story] pivotal_story the Pivotal tracker story to wrap
    def initialize(project, pivotal_story, options = {})
      raise "Invalid PivotalTracker::Story" if pivotal_story.nil?
      @project = project
      @pivotal_story = pivotal_story
      @branch_name = options.delete(:branch_name)
      @branch_suffix = @branch_name.split('-').last if @branch_name
      @branch_suffix ||= nil
    end

    def release?
      story_type == 'release'
    end

    def unestimated?
      estimate == -1
    end

    def request_estimation!
      self.update(
        estimate: ask('Story is not yet estimated. Please estimate difficulty: ')
      )
    end

    def mark_started!
      print 'Starting story on Pivotal Tracker... '
      self.update(
          current_state: 'started',
          owned_by: Git.get_config(KEY_USER_NAME, :inherited).strip
      )
      puts 'OK'
    end

    def create_branch!(options = {})
      Git.checkout(root_branch_name)
      root_origin = Git.get_remote
      remote_branch_name = [root_origin, root_branch_name].join('/')
      print "Creating branch for story with branch name #{branch_name} from #{remote_branch_name}... "
      Git.pull_remote
      Git.create_branch(branch_name, remote_branch_name, track: true)
      Git.checkout(branch_name)
      Git.set_config('root-branch', root_branch_name, :branch)
      Git.set_config('root-remote', root_origin, :branch)
    end

    def merge_to_root!(commit_message = nil, options = {})
      commit_message = "Merge #{branch_name} to #{root_branch_name}" if commit_message.blank?
      commit_message << "\n\n[#{options[:no_complete] ? '' : 'Completes '}##{id}] "
      print "Merging #{branch_name} to #{root_branch_name}... "
      Git.checkout(root_branch_name)
      Git.pull_remote(root_branch_name)
      Git.merge(branch_name, commit_message: commit_message, no_ff: true)
      Git.push(root_branch_name)
      self.delete_branch!
      self.cleanup!
    end

    def merge_release!(commit_message = nil, options = {})
      commit_message ||= "Release #{escape_quotes(name)}"
      commit_message << "\n\n[#{options[:no_complete] ? '' : 'Completes '}##{id}] "
      print "Merging #{branch_name} to #{master_branch_name}... "
      Git.checkout(master_branch_name)
      Git.pull_remote(master_branch_name)
      if trivial_merge?(master_branch_name)
        Git.merge(branch_name, commit_message: commit_message, ff: true)
      else
        Git.merge(branch_name, commit_message: commit_message, no_ff: true)
      end
      print "Merging #{branch_name} to #{development_branch_name}... "
      Git.checkout(development_branch_name)
      Git.pull_remote(development_branch_name)
      if trivial_merge?(development_branch_name)
        Git.merge(branch_name, commit_message: commit_message, ff: true)
      else
        Git.merge(branch_name, commit_message: commit_message, no_ff: true)
      end
      Git.checkout(master_branch_name)
      Git.tag(name, annotated: true, message: "Release #{escape_quotes(name)}")
      Git.push(master_branch_name, development_branch_name)
      Git.push_tags
      self.delete_branch!
      self.cleanup!
    end

    def delete_branch!
      print "Deleting #{branch_name}... "
      Git.delete_branch(branch_name)
      puts 'OK'
    end

    def cleanup!
      Git.delete_remote_branch(branch_name)
    end

    #def create_pull_request!
    #  Shell.exec("hub pull-request -m \"#{self.name}\n\n#{self.description}\" -b #{root_branch_name} -h #{branch_name}")
    #end

    def branch_name
      @branch_name ||= branch_name_from(branch_prefix, id, branch_suffix)
    end

    def branch_suffix
      @branch_suffix ||= ask("Enter branch name (#{branch_name_from(branch_prefix, id, "<branch-name>")}): ")
    end

    def branch_name_from(branch_prefix, story_id, branch_name)
      if story_type == 'release'
        # For release branches the format is release/5.0
        "#{Git.get_config(KEY_RELEASE_PREFIX, :inherited)}#{branch_name}"
      else
        n = "#{branch_prefix}"
        n << "#{branch_name}" unless branch_name.blank?
        n
      end
    end

    def root_branch_name
      case story_type
      when 'chore'
        master_branch_name
      when 'bug'
        self.labels.include?('hotfix') ? master_branch_name : development_branch_name
      else
        development_branch_name
      end
    end

    def master_branch_name
      Git.get_config(KEY_MASTER_BRANCH, :inherited)
    end

    def development_branch_name
      Git.get_config(KEY_DEVELOPMENT_BRANCH, :inherited)
    end

    def labels
      return [] if pivotal_story.labels.blank?
      pivotal_story.labels.split(',').collect(&:strip)
    end

    def params_for_pull_request
      {
        base: root_branch_name,
        head: branch_name,
        title: name,
        body: description,
      }
    end

    def method_missing(m, *args, &block)
      return @pivotal_story.send(m, *args, &block)
    end

    def can_merge?
      Git.clean_working_tree?
    end

    def trivial_merge?(to_branch = nil)
      to_branch ||= root_branch_name
      root_tip = Shell.exec "git rev-parse #{to_branch}"
      common_ancestor = Shell.exec "git merge-base #{to_branch} #{branch_name}"
      if root_tip != common_ancestor
        return false
      end
      return true
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
      else
        criteria[:story_type] = ['feature', 'bug']
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
      case story_type
      when 'feature'
        prefix = Git.get_config(KEY_FEATURE_PREFIX, :inherited)
      when 'bug'
        prefix = labels.include?('hotfix') ? Git.get_config(KEY_HOTFIX_PREFIX, :inherited) : Git.get_config(KEY_FEATURE_PREFIX, :inherited)
      when 'release'
        prefix = Git.get_config(KEY_RELEASE_PREFIX, :inherited)
      else
        prefix = 'misc/'
      end
      prefix = "#{prefix.strip}/" unless prefix.strip[-1,1] == '/'
      return prefix.strip
    end

    def escape_quotes(string)
      string.gsub('"', '\"')
    end
  end
end
