require 'spec_helper'

module GhPivotalFlow
  describe Git do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    it 'should return the current branch name' do
      Shell.should_receive(:exec).with('git branch', true).and_return("   master\n * dev_branch")

      current_branch = Git.current_branch

      expect(current_branch).to eq('dev_branch')
    end

    it 'should return the repository root' do
      Dir.mktmpdir do |root|
        child_directory = File.expand_path 'child', root
        Dir.mkdir child_directory

        git_directory = File.expand_path '.git', root
        Dir.mkdir git_directory

        Dir.should_receive(:pwd).and_return(child_directory)

        repository_root = Git.repository_root

        expect(repository_root).to eq(root)
      end
    end

    it 'should raise an error there is no repository root' do
      Dir.mktmpdir do |root|
        child_directory = File.expand_path 'child', root
        Dir.mkdir child_directory

        Dir.should_receive(:pwd).and_return(child_directory)

        expect { Git.repository_root }.to raise_error
      end
    end

    it 'should get configuration when :branch scope is specified' do
      Git.should_receive(:current_branch).and_return('test_branch_name')
      Shell.should_receive(:exec).with('git config branch.test_branch_name.test_key', false).and_return('test_value')

      value = Git.get_config 'test_key', :branch

      expect(value).to eq('test_value')
    end

    it 'should get configuration when :inherited scope is specified' do
      Shell.should_receive(:exec).with('git config test_key', false).and_return('test_value')

      value = Git.get_config 'test_key', :inherited

      expect(value).to eq('test_value')
    end

    it 'should raise an error when an unknown scope is specified (get)' do
      expect { Git.get_config 'test_key', :unknown }.to raise_error
    end

    it 'should set configuration when :branch scope is specified' do
      Git.should_receive(:current_branch).and_return('test_branch_name')
      Shell.should_receive(:exec).with('git config --local branch.test_branch_name.test_key test_value', true)

      Git.set_config 'test_key', 'test_value', :branch
    end

    it 'should set configuration when :global scope is specified' do
      Shell.should_receive(:exec).with('git config --global test_key test_value', true)

      Git.set_config 'test_key', 'test_value', :global
    end

    it 'should set configuration when :local scope is specified' do
      Shell.should_receive(:exec).with('git config --local test_key test_value', true)

      Git.set_config 'test_key', 'test_value', :local
    end

    it 'should raise an error when an unknown scope is specified (set)' do
      expect { Git.set_config 'test_key', 'test_value', :unknown }.to raise_error
    end

    it 'should create a branch and set the root_branch and root_remote properties on it' do
      Git.stub(:current_branch).and_return('master')
      Shell.should_receive(:exec).with('git branch --quiet dev_branch', true)

      Git.create_branch 'dev_branch'
    end

    it 'should not add a hook if it already exists' do
      Dir.mktmpdir do |root|
        Git.should_receive(:repository_root).and_return(root)
        hook = "#{root}/.git/hooks/prepare-commit-msg"
        File.should_receive(:exist?).with(hook).and_return(true)

        Git.add_hook 'prepare-commit-msg', __FILE__

        File.should_receive(:exist?).and_call_original
        expect(File.exist?(hook)).to be_false
      end
    end

    it 'should add a hook if it does not exist' do
      Dir.mktmpdir do |root|
        Git.should_receive(:repository_root).and_return(root)
        hook = "#{root}/.git/hooks/prepare-commit-msg"
        File.should_receive(:exist?).with(hook).and_return(false)

        Git.add_hook 'prepare-commit-msg', __FILE__

        File.should_receive(:exist?).and_call_original
        expect(File.exist?(hook)).to be_true
      end
    end

    it 'should add a hook if it already exists and overwrite is true' do
      Dir.mktmpdir do |root|
        Git.should_receive(:repository_root).and_return(root)
        hook = "#{root}/.git/hooks/prepare-commit-msg"

        Git.add_hook 'prepare-commit-msg', __FILE__, true

        File.should_receive(:exist?).and_call_original
        expect(File.exist?(hook)).to be_true
      end
    end

    it 'should merge and delete branches' do
      Shell.should_receive(:exec).with("git merge --quiet --no-ff -m \"Merge development_branch to master\" development_branch", true)

      Git.merge 'development_branch', commit_message: 'Merge development_branch to master', no_ff: true
    end

    it 'should push changes without refs' do
      Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
      Shell.should_receive(:exec).with('git push --quiet origin ', true)

      Git.push
    end

    it 'should push changes with refs' do
      Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
      Shell.should_receive(:exec).with('git push --quiet origin foo bar', true)

      Git.push 'foo', 'bar'
    end

    it 'should create a commit' do
      Shell.should_receive(:exec).with("git commit --quiet --allow-empty -m \"test_message\"", true)

      Git.commit commit_message: 'test_message', allow_empty: true
    end

    it 'should create a tag' do
      Shell.should_receive(:exec).with('git tag 1.0.0.RELEASE', true)

      Git.tag '1.0.0.RELEASE'
    end
  end
end
