require 'spec_helper'

module GithubPivotalFlow
  describe Command do
    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
      @configuration = double('configuration')
      @project = double('project')
      allow(Configuration).to receive(:new).and_return(@configuration)
      allow(PivotalTracker::Project).to receive(:find).and_return(@project)
      @configuration.stub(
        validate: true,
        project_id: 123456,
        project: @project,
      )
    end

    describe '#initialize' do
      it 'validates the configuration when started' do
        expect(@configuration).to receive(:validate).once
        @start = Command.new
      end

      it 'finds the project corresponding to the current repo' do
        expect(@configuration).to receive(:project).once.and_return(@project)
        @start = Command.new
      end
    end
  end
end