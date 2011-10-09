require File.expand_path("./helper", File.dirname(__FILE__))

test "spawn with defaults" do
  pid = Redis::SpawnServer.spawn
  assert_equal `ps -o cmd= -p #{pid}`, "redis-server /tmp/redis-spawned.#{Process.pid}.config\n"
  Process.kill("TERM", pid)
end

