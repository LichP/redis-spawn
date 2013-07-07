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
unixsocket /tmp/redis-spawned.#{PROCESS_PID}.sock
loglevel notice
logfile /tmp/redis-spawned.#{PROCESS_PID}.log
timeout 0
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /tmp/redis-spawned.#{PROCESS_PID}.data
appendonly no
appendfsync everysec
no-appendfsync-on-rewrite no
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
TEST_CONF_END
end

test "build_config with defaults" do
  assert @test_config_defaults == Redis::SpawnServer.new(start: false).build_config
end

setup do
  @test_config_overrides = <<TEST_CONF_END
port 0
bind 127.0.0.1
unixsocket /tmp/redis-spawned.override.sock
loglevel notice
logfile /tmp/redis-spawned.override.log
timeout 0
databases 8
save 900 1
save 300 10
save 100 1000
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression no
rdbchecksum yes
dbfilename dump.rdb
dir /tmp/redis-spawned.override.data
appendonly no
appendfsync everysec
no-appendfsync-on-rewrite no
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
TEST_CONF_END
end
  
test "build_config with overrides" do
  overrides = {
    unixsocket:     "/tmp/redis-spawned.override.sock",
    logfile:        "/tmp/redis-spawned.override.log",
    databases:      8,
    save:           ["900 1", "300 10", "100 1000", "60 10000"],
    rdbcompression: "no",
    dir:            "/tmp/redis-spawned.override.data"
  }
  assert @test_config_overrides == Redis::SpawnServer.new(start: false, server_opts: overrides).build_config
end

  