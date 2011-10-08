require File.expand_path("./helper", File.dirname(__FILE__))

test "full_config_hash with no extra options" do
  assert Redis::SpawnServer.full_config_hash == Redis::SpawnServer.instance_variable_get(:@server_config_defaults)
end

setup do
  modified_server_config = Redis::SpawnServer.instance_variable_get(:@server_config_defaults)
  modified_server_config[:port] = 9999
  modified_server_config[:dbfilename] = "abcde"
  modified_server_config
end

test "full_config_hash with overrides" do |modified_server_config|
  assert Redis::SpawnServer.full_config_hash(port: 9999, dbfilename: "abcde") == modified_server_config
end

test "full_config_hash with nil" do
  assert_raise { Redis::SpawnServer.full_config_hash(nil) }
end
