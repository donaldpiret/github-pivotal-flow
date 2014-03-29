require 'spec_helper'

module GithubPivotalFlow
  describe Shell do

    before do
      $stdout = StringIO.new
      $stderr = StringIO.new
    end

    it 'should return result when exit code is 0' do
      expect(Shell).to receive(:`).with('test_command').and_return('test_result')
      expect($?).to receive(:exitstatus).and_return(0)

      result = Shell.exec 'test_command'

      expect(result).to eq('test_result')
    end

    it "should abort with 'FAIL' when the exit code is not 0" do
      expect(Shell).to receive(:`).with('test_command')
      expect($?).to receive(:exitstatus).and_return(-1)

      expect { Shell.exec 'test_command' }.to raise_error

      expect($stderr.string).to match(/FAIL/)
    end

    it 'should return result when the exit code is not 0 and told not to abort on failure' do
      expect(Shell).to receive(:`).with('test_command')
      expect($?).to receive(:exitstatus).and_return(-1)

      Shell.exec 'test_command', false
    end
  end
end