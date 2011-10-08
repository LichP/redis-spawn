require File.expand_path("./helper", File.dirname(__FILE__))

test "build_config_line" do
  assert "key value"                     == Redis::SpawnServer.build_config_line("key", "value")
  assert "symbolkey value"               == Redis::SpawnServer.build_config_line(:symbolkey, "value")
  assert "symbol-with-underscores value" == Redis::SpawnServer.build_config_line(:symbol_with_underscores, "value")
  assert "key 0"                         == Redis::SpawnServer.build_config_line("key", 0)
end

setup do
  @test_config_defaults = <<TEST_CONF_END
port 0
bind 127.0.0.1
unixsocket /tmp/redis-spawned.0.sock
loglevel notice
logfile /tmp/redis-spawned.0.log
databases 16
save 900 1
save 300 10
save 60 10000
rdbcompression yes
dbfilename dump.rdb
dir /tmp/redis-spawned.0.data
appendonly no
appendfsync everysec
vm-enabled no
hash-max-zipmap-entries 512
hash-max-zipmap-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
activerehashing yes
TEST_CONF_END
end

test "build_config with defaults" do
  assert @test_config_defaults == Redis::SpawnServer.build_config
end
