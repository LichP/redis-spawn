require "./lib/redis/spawn/version"

Gem::Specification.new do |s|
  s.name = "redis-spawn"
  s.version = Redis::SpawnServer::VERSION
  s.summary = %{An extension to redis-rb to facilitate spawning a redis-server specifically for your app.}
  s.description = %Q{Insert something more verbose than the summary here.}
  s.authors = ["Phil Stewart"]
  s.email = ["phil.stewart@lichp.co.uk"]
  s.homepage = "http://github.com/lichp/redis-spawn"

  s.files = Dir[
    "lib/**/*.rb",
    "README*",
    "LICENSE",
    "Rakefile",
    "test/**/*.rb"
  ]

  s.add_dependency "redis-rb", "~> 2.0"
  s.add_development_dependency "cutest", "~> 0.1"
end
