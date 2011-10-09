# Monkeypatch Process to allow for consistent value of Process.pid in tests
module Process
  class << self
    alias :redis_spawn_original_pid :pid
  
    def pid
      if caller[0] =~ /redis\/spawn/
        return 0
      else
        return redis_spawn_original_pid
      end
    end
  end
end
