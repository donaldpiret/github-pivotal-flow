require 'spec_helper'

module GithubPivotalFlow
  describe Shell do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    it 'should return result when exit code is 0' do
      Shell.should_receive(:`).with('test_command').and_return('test_result')
      $?.should_receive(:exitstatus).and_return(0)

      result = Shell.exec 'test_command'

      expect(result).to eq('test_result')
    end

    it "should abort with 'FAIL' when the exit code is not 0" do
      Shell.should_receive(:`).with('test_command')
      $?.should_receive(:exitstatus).and_return(-1)

      lambda { Shell.exec 'test_command' }.should raise_error(SystemExit)

      expect($stderr.string).to match(/FAIL/)
    end

    it 'should return result when the exit code is not 0 and told not to abort on failure' do
      Shell.should_receive(:`).with('test_command')
      $?.should_receive(:exitstatus).and_return(-1)

      Shell.exec 'test_command', false
    end
  end
end