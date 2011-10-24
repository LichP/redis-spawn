require File.expand_path("./helper", File.dirname(__FILE__))
require 'digest/sha1'

setup do
  testdir = "/tmp/redis-spawn-write-config-test.dir"
  filename = "/tmp/redis-spawn-write-config-test.config"
  spawn_instance = Redis::SpawnServer.new(start:                 false,
                                          generated_config_file: filename,
                                          server_opts:           {dir: testdir})
  Dir.exists?(testdir) && Dir.rmdir(testdir)
  {
    filename:       filename,
    spawn_instance: spawn_instance,
    config_sha:     Digest::SHA1.hexdigest(spawn_instance.build_config)
  }
end

test "write_config" do |params|
  begin
    filename = params[:spawn_instance].write_config
    assert_equal filename, params[:filename]
    assert_equal Digest::SHA1.hexdigest(File.read(filename)), params[:config_sha]
#    assert Dir.exist?(params[:spawn_instance].server_opts[:dir])
  ensure
    File.delete(params[:filename])
  end
end
