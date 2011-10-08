require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'redis/spawn'

task :test do
  require 'cutest'
  
  Cutest.run(Dir["./test/**/*_test.rb"])
end

task :pry do
  require 'pry'
  binding.pry
end
