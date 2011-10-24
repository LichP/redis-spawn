require File.expand_path("./helper", File.dirname(__FILE__))

test "spawn with defaults" do
  spawn_instance = Redis::SpawnServer.new
  assert_equal `ps -o cmd= -p #{spawn_instance.pid}`, "redis-server /tmp/redis-spawned.#{Process.pid}.config\n"
  Process.kill("TERM", spawn_instance.pid)
end

