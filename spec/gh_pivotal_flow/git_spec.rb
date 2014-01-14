require 'spec_helper'

describe GhPivotalFlow::Git do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  it 'should return the current branch name' do
    Shell.should_receive(:exec).with('git branch').and_return("   master\n * dev_branch")

    current_branch = Git.branch_name

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
    Git.should_receive(:branch_name).and_return('test_branch_name')
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
    Git.should_receive(:branch_name).and_return('test_branch_name')
    Shell.should_receive(:exec).with('git config --local branch.test_branch_name.test_key test_value')

    Git.set_config 'test_key', 'test_value', :branch
  end

  it 'should set configuration when :global scope is specified' do
    Shell.should_receive(:exec).with('git config --global test_key test_value')

    Git.set_config 'test_key', 'test_value', :global
  end

  it 'should set configuration when :local scope is specified' do
    Shell.should_receive(:exec).with('git config --local test_key test_value')

    Git.set_config 'test_key', 'test_value', :local
  end

  it 'should raise an error when an unknown scope is specified (set)' do
    expect { Git.set_config 'test_key', 'test_value', :unknown }.to raise_error
  end

  it 'should create a branch and set the root_branch and root_remote properties on it' do
    Git.should_receive(:branch_name).and_return('master')
    Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
    Shell.should_receive(:exec).with('git pull --quiet --ff-only')
    Shell.should_receive(:exec).and_return('git checkout --quiet -b dev_branch')
    Git.should_receive(:set_config).with('root-branch', 'master', :branch)
    Git.should_receive(:set_config).with('root-remote', 'origin', :branch)

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

  it 'should fail if root tip and common_ancestor do not match' do
    Git.should_receive(:branch_name).and_return('development_branch')
    Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    Shell.should_receive(:exec).with('git checkout --quiet master')
    Shell.should_receive(:exec).with('git pull --quiet --ff-only')
    Shell.should_receive(:exec).with('git checkout --quiet development_branch')
    Shell.should_receive(:exec).with('git rev-parse master').and_return('root_tip')
    Shell.should_receive(:exec).with('git merge-base master development_branch').and_return('common_ancestor')

    lambda { Git.trivial_merge? }.should raise_error(SystemExit)

    expect($stderr.string).to match(/FAIL/)
  end

  it 'should pass if root tip and common ancestor match' do
    Git.should_receive(:branch_name).and_return('development_branch')
    Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    Shell.should_receive(:exec).with('git checkout --quiet master')
    Shell.should_receive(:exec).with('git pull --quiet --ff-only')
    Shell.should_receive(:exec).with('git checkout --quiet development_branch')
    Shell.should_receive(:exec).with('git rev-parse master').and_return('HEAD')
    Shell.should_receive(:exec).with('git merge-base master development_branch').and_return('HEAD')

    Git.trivial_merge?

    expect($stdout.string).to match(/OK/)
  end

  it 'should merge and delete branches' do
    Git.should_receive(:branch_name).and_return('development_branch')
    Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    Shell.should_receive(:exec).with('git checkout --quiet master')
    Shell.should_receive(:exec).with("git merge --quiet --no-ff -m \"Merge development_branch to master\n\n[Completes #12345678]\" development_branch")
    Shell.should_receive(:exec).with('git branch --quiet -D development_branch')

    Git.merge PivotalTracker::Story.new(:id => 12345678), nil
  end

  it 'should suppress Completes statement' do
    Git.should_receive(:branch_name).and_return('development_branch')
    Git.should_receive(:get_config).with('root-branch', :branch).and_return('master')
    Shell.should_receive(:exec).with('git checkout --quiet master')
    Shell.should_receive(:exec).with("git merge --quiet --no-ff -m \"Merge development_branch to master\n\n[#12345678]\" development_branch")
    Shell.should_receive(:exec).with('git branch --quiet -D development_branch')

    Git.merge PivotalTracker::Story.new(:id => 12345678), true
  end

  it 'should push changes without refs' do
    Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
    Shell.should_receive(:exec).with('git push --quiet origin ')

    Git.push
  end

  it 'should push changes with refs' do
    Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
    Shell.should_receive(:exec).with('git push --quiet origin foo bar')

    Git.push 'foo', 'bar'
  end

  it 'should create a commit' do
    story = PivotalTracker::Story.new(:id => 123456789)
    Shell.should_receive(:exec).with("git commit --quiet --all --allow-empty --message \"test_message\n\n[#123456789]\"")

    Git.create_commit 'test_message', story
  end

  it 'should create a release tag' do
    story = PivotalTracker::Story.new(:id => 123456789)
    Git.should_receive(:branch_name).and_return('master')
    Git.should_receive(:create_branch).with('pivotal-tracker-release', false)
    Git.should_receive(:create_commit).with('1.0.0.RELEASE Release', story)
    Shell.should_receive(:exec).with('git tag v1.0.0.RELEASE')
    Shell.should_receive(:exec).with('git checkout --quiet master')
    Shell.should_receive(:exec).with('git branch --quiet -D pivotal-tracker-release')

    Git.create_release_tag '1.0.0.RELEASE', story
  end
end
