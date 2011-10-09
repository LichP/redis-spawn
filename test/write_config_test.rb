require File.expand_path("./helper", File.dirname(__FILE__))
require 'digest/sha1'

setup do
  testdir = "/tmp/redis-spawn-write-config-test.dir"
  server_opts = {dir: testdir}
  Dir.exists?(testdir) && Dir.rmdir(testdir)
  {
    filename:    "/tmp/redis-spawn-write-config-test.config",
    server_opts: server_opts,
    config_sha:  Digest::SHA1.hexdigest(Redis::SpawnServer.build_config(server_opts))
  }
end

test "write_config" do |params|
  begin
    filename = Redis::SpawnServer.write_config(params[:filename], params[:server_opts])
    assert filename == params[:filename]
    assert Digest::SHA1.hexdigest(File.read(filename)) == params[:config_sha]
    assert Dir.exist?(params[:server_opts][:dir])
  ensure
    Dir.rmdir(params[:server_opts][:dir])
    File.delete(params[:filename])
  end
end
