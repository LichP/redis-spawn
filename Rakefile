require 'rubygems'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'redis/spawn'

task :test do
  require 'cutest'
  
  PROCESS_PID = Process.pid.to_s
  Cutest.run(Dir["./test/**/*_test.rb"])
end

task :pry do
  require 'pry'
  binding.pry
end
