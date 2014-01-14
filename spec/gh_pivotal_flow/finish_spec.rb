require 'spec_helper'

describe GhPivotalFlow::Finish do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    Git.should_receive(:repository_root)
    Configuration.any_instance.should_receive(:api_token)
    Configuration.any_instance.should_receive(:project_id)
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    @finish = Finish.new
  end

  it 'should run' do
    Git.should_receive(:trivial_merge?)
    Configuration.any_instance.should_receive(:story)
    Git.should_receive(:merge)
    Git.should_receive(:branch_name).and_return('master')
    Git.should_receive(:push).with('master')

    @finish.run nil
  end
end
