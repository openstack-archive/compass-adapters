require File.expand_path('../support/helpers', __FILE__)
describe "ganglia_test::gmetad" do
  include Helpers::GangliaTest
  describe 'creates the gmetad configuration' do
    it 'must exist' do
        file('/etc/ganglia/gmetad.conf').must_exist
    end
  end

  describe 'starts the gmetad daemon' do
    it 'must be running' do
      result = assert_sh("ps -ef")
      assert_includes result, "gmetad"
    end
    it 'must_be_listening_on_8651' do
        TCPSocket.open("localhost", 8651) do |client|
            assert_instance_of TCPSocket, client
            client.close
        end
    end
  end
end
