require "redis"

class Redis
  module SpawnServer
    @server_config_defaults = {
      port:                     "0",
      bind:                     "127.0.0.1",
      unixsocket:               "/tmp/redis-spawned.#{Process.pid}.sock",
      loglevel:                 "notice",
      logfile:                  "/tmp/redis-spawned.#{Process.pid}.log",
      databases:                "16",
      save:                     ["900 1", "300 10", "60 10000"],
      rdbcompression:           "yes",
      dbfilename:               "dump.rdb",
      dir:                      "/tmp/redis-spawned.#{Process.pid}.data",
      appendonly:               "no",
      appendfsync:              "everysec",
      vm_enabled:               "no",
      hash_max_zipmap_entries:  "512",
      hash_max_zipmap_value:    "64",
      list_max_ziplist_entries: "512",
      list_max_ziplist_value:   "64",
      set_max_intset_entries:   "512",
      activerehashing:          "yes"
    }
    
    # Return a server configuration hash with passed options merged with
    # defaults
    #
    # @param [Hash] server_opts: the options to override defaults with
    # 
    # @return a fully populated server configuration hash
    def self.full_config_hash(server_opts = {})
      @server_config_defaults.merge(server_opts)
    end

    # Build a configuration file line
    #
    # @param [Symbol, String] key: The configuration parameter. Underscores in
    #                              the key are transposed to dashes
    # @param [String, Object] value: The value to set for this configuration
    #                                parameter
    #
    # @return A line of Redis server configuration data
    def self.build_config_line(key, value)
      key.to_s.gsub(/_/, "-") + " " + value.to_s
    end

    # Build configuration file data from supplied options and defauls
    #
    # @param [Hash] server_opts: Hash of server configuration options which
    #                            override the defaults
    #
    # @return Redis server compatible configuration file data
    def self.build_config(server_opts = {})
      config_data = ""
      full_config_hash(server_opts).each do |key, value|
        if value.kind_of?(Array)
          value.each { |subvalue| config_data << build_config_line(key, subvalue) << "\n" }
        else
          config_data << build_config_line(key, value) << "\n"
        end
      end
      config_data
    end

    # Write a Redis configuration file to disk and ensure the directory named
    # in the 'dir' server parameter exists
    #
    # @param [String] filename: The name of the config file
    # @param [Hash] server_opts: Hash of server configuration options which
    #                            override the defaults
    #
    # @return the name of the written file
    def self.write_config(filename, server_opts = {})
      File.open(filename, "w") do |file|
        file.write(build_config(server_opts))
      end
      Dir.mkdir(full_config_hash(server_opts)[:dir])
      filename
    end

    # Spawn a Redis server configured with the supplied options. By default,
    # the spawned server will be a child of the current process and won't
    # daemonize (@todo allow daemonization)
    #
    # @param supplied_opts: the server options
    #
    # @return pid of the spawned server
    def self.spawn(supplied_opts = {})
      default_opts = {
        generated_config_file: "/tmp/redis-spawned.#{Process.pid}.config",
        server_opts:           {}
      }
      opts = default_opts.merge(supplied_opts)
      
      # If config_file is passed in opts use it as the name of the config file.
      # Otherwise, generate our own
      config_file = if opts[:config_file]
        opts[:config_file]
      else
        write_config(opts[:generated_config_file], opts[:server_opts])
      end
      
      # Make sure we clean up after our children and avoid a zombie invasion
      trap("CLD") do
        pid = Process.wait
      end

      pid = fork { exec("redis-server #{config_file}") }
      #logger.info("Spawned redis server with PID #{pid}")
      at_exit { Process.kill("TERM", pid) } # Maybe make this configurable to allow the server to continue after exit
      pid
    end
  end
end
