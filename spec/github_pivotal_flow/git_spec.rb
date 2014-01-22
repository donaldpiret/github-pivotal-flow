require 'spec_helper'

module GithubPivotalFlow
  describe Git do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    describe '.current_branch' do
      it 'returns the current branch name' do
        expect(Shell).to receive(:exec).with('git branch', true).and_return("   master\n * dev_branch")

        current_branch = Git.current_branch

        expect(current_branch).to eq('dev_branch')
      end
    end

    describe '.repository_root' do
      it 'returns the repository root' do
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

      it 'raises an error if there is no repository root' do
        Dir.mktmpdir do |root|
          child_directory = File.expand_path 'child', root
          Dir.mkdir child_directory

          Dir.should_receive(:pwd).and_return(child_directory)

          expect { Git.repository_root }.to raise_error
        end
      end
    end

    describe '.get_config' do
      it 'gets configuration scoped by branch when :branch scope is specified' do
        Git.should_receive(:current_branch).and_return('test_branch_name')
        Shell.should_receive(:exec).with('git config branch.test_branch_name.test_key', false).and_return('test_value')

        value = Git.get_config 'test_key', :branch

        expect(value).to eq('test_value')
      end

      it 'gets configuration when :inherited scope is specified' do
        Shell.should_receive(:exec).with('git config test_key', false).and_return('test_value')

        value = Git.get_config 'test_key', :inherited

        expect(value).to eq('test_value')
      end

      it 'raises an error when an unknown scope is specified (get)' do
        expect { Git.get_config 'test_key', :unknown }.to raise_error
      end
    end

    describe '.set_config' do
      it 'sets configuration when :branch scope is specified' do
        Git.should_receive(:current_branch).and_return('test_branch_name')
        Shell.should_receive(:exec).with('git config --local branch.test_branch_name.test_key test_value', true)

        Git.set_config 'test_key', 'test_value', :branch
      end

      it 'sets configuration when :global scope is specified' do
        Shell.should_receive(:exec).with('git config --global test_key test_value', true)

        Git.set_config 'test_key', 'test_value', :global
      end

      it 'sets configuration when :local scope is specified' do
        expect(Shell).to receive(:exec).with('git config --local test_key test_value', true)

        Git.set_config 'test_key', 'test_value', :local
      end

      it 'raises an error when an unknown scope is specified (set)' do
        expect { Git.set_config 'test_key', 'test_value', :unknown }.to raise_error
      end
    end

    describe '.create_branch' do
      it 'creates a branch' do
        Git.stub(:current_branch).and_return('master')
        Shell.should_receive(:exec).with('git branch --quiet dev_branch', true)
        Git.create_branch 'dev_branch'
      end
    end

    #FIXME: Can't seem to set an expectation on File for some reason...
    describe '.add_hook' do
      it 'does not add a hook if it already exists' do
        Dir.mktmpdir do |root|
          Git.should_receive(:repository_root).and_return(root)
          hook = "#{root}/.git/hooks/prepare-commit-msg"
          expect(File).to receive(:exist?).with(hook).and_return(true)

          Git.add_hook 'prepare-commit-msg', __FILE__
          expect(File).to receive(:exist?).and_call_original
          expect(File.exist?(hook)).to be_false
        end
      end

      it 'adds a hook if it does not exist' do
        Dir.mktmpdir do |root|
          Git.should_receive(:repository_root).and_return(root)
          hook = "#{root}/.git/hooks/prepare-commit-msg"
          #File.should_receive(:exist?).with(hook).and_return(false)
          expect(File).to receive(:exist?).with(hook).and_return(false)

          Git.add_hook 'prepare-commit-msg', __FILE__
          expect(File).to receive(:exist?).with(hook).and_call_original
          expect(File.exist?(hook)).to be_true
        end
      end

      it 'adds a hook if it already exists and overwrite is true' do
        Dir.mktmpdir do |root|
          Git.should_receive(:repository_root).and_return(root)
          hook = "#{root}/.git/hooks/prepare-commit-msg"

          Git.add_hook 'prepare-commit-msg', __FILE__, true

          File.should_receive(:exist?).and_call_original
          expect(File.exist?(hook)).to be_true
        end
      end
    end

    describe '.merge' do
      it 'merges branches' do
        Shell.should_receive(:exec).with("git merge --quiet --no-ff -m \"Merge development_branch to master\" development_branch", true)

        Git.merge 'development_branch', commit_message: 'Merge development_branch to master', no_ff: true
      end
    end

    describe '.push' do
      before do
        Git.should_receive(:get_config).with('remote', :branch).and_return('origin')
      end

      it 'pushes changes back to the origin without refs' do
        Shell.should_receive(:exec).with('git push --quiet origin ', true)

        Git.push
      end

      it 'pushes changes back to the origin with refs' do
        Shell.should_receive(:exec).with('git push --quiet origin foo bar', true)

        Git.push 'foo', 'bar'
      end

      it 'supports passing in the set_upstream option after a ref' do
        Shell.should_receive(:exec).with('git push --quiet -u origin foo', true)

        Git.push 'foo', set_upstream: true
      end
    end

    describe '.commit' do
      it 'creates a commit' do
        Shell.should_receive(:exec).with("git commit --quiet --allow-empty -m \"test_message\"", true)

        Git.commit commit_message: 'test_message', allow_empty: true
      end

      it 'correctly escapes quotes for the commit message' do
        expect(Shell).to receive(:exec).with(%Q(git commit --quiet --allow-empty -m "It's a \"hard\" not life"), true)

        Git.commit commit_message: "It's a \"hard\" not life", allow_empty: true
      end
    end

    describe '.tag' do
      it 'creates a tag' do
        Shell.should_receive(:exec).with('git tag 1.0.0.RELEASE', true)

        Git.tag '1.0.0.RELEASE'
      end
    end
  end
end
