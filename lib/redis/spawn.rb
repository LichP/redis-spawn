require "redis"

class Redis
  class SpawnServer
    @_default_server_opts = {
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

    @_running_servers = {}
    
    def self.default_server_opts
      @_default_server_opts
    end

    def self.default_server_opts=(new_defaults_hash)
      @_default_server_opts = new_defaults_hash
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

    # Spawn a Redis server configured with the supplied options. By default,
    # the spawned server will be a child of the current process and won't
    # daemonize (@todo allow daemonization)
    #
    # @param supplied_opts: options for this server including any configuration overrides
    #
    # @return [SpawnServer] instance corresponding to the spawned server
    def self.spawn(supplied_opts = {})
      self.new(supplied_opts)
    end
    
    attr_reader :opts, :supplied_opts, :server_opts, :pid

    def initialize(supplied_opts = {})
      default_opts = {
        generated_config_file: "/tmp/redis-spawned.#{Process.pid}.config",
        cleanup_files:         [:socket, :log, :config],
        server_opts:           {},
        start:                 true
      }
      @supplied_opts = supplied_opts
      @opts = default_opts.merge(supplied_opts)
      self.server_opts = opts[:server_opts]
      
      opts[:start] ? self.start : 0

      # Return the instance
      self
    end
    
    # Prepare a redis configuration file then start the server
    #
    # @return pid of the server
    def start
      # If config_file is passed in opts use it as the name of the config file.
      # Otherwise, generate our own
      @config_file = if opts.has_key?(:config_file)
        # Don't attempt to cleanup files when supplied with pre-existing
        # config file unless specifically asked
        opts[:cleanup_files] = [] unless supplied_opts.has_key?(:cleanup_files)
        opts[:config_file]
      else
        self.write_config
      end
      
      # Ensure the data directory exists
      Dir.exists?(self.server_opts[:dir]) || Dir.mkdir(self.server_opts[:dir])

      # Spawn the redis server for this instance
      self.spawn
    end
    
    # Spawn a redis server. Only call this function once a config file exists
    # and is specified
    #
    # @return the pid of the spawned server
    def spawn
      # Abort if there's no config file
      unless @config_file && File.exist?(@config_file)
        raise "Config file #{@config_file.inspect} not found"
      end
   
      # Make sure we clean up after our children and avoid a zombie invasion
      trap("CLD") do
        pid = Process.wait
      end

      # Start the server
      @pid = fork { exec("redis-server #{@config_file}") }
      #logger.info("Spawned redis server with PID #{pid}")

      at_exit do
        # Maybe make this configurable to allow the server to continue after exit
        self.shutdown!
      end
      
      self.pid
    end
    
    # Check whether the server is stated by checking if a value is assigned to @pid
    def started?
      self.pid ? true : false
    end
    
    # Shutdown the spawned redis-server if it is running
    def shutdown
      if self.started?
        self.shutdown!
      else
        nil
      end
    end
    
    # Forcibly shutdown the spawned redis-server. Used internally by #shutdown.
    def shutdown!
      Process.kill("TERM", self.pid)
    rescue Errno::ESRCH
      # Already dead - do nothing
      nil
    ensure
      @pid = nil
      self.cleanup_files      
    end    
    
    # Attribute write for server opts: merges supplied opts with defaults
    # to create fully populated server opts
    #
    # @param [Hash] opts: partially populated server options hash
    def server_opts=(opts)
      @server_opts = self.class.default_server_opts.merge(opts)
    end

    # Write the Redis configuration file to disk.
    #
    # @return the name of the written file
    def write_config
      File.open(self.opts[:generated_config_file], "w") do |file|
        ## @todo Migrate class based build_config to instance based build_config
        file.write(self.build_config)
      end
      self.opts[:generated_config_file]
    end

    # Build configuration file data
    #
    # @return Redis server compatible configuration file data
    def build_config
      config_data = ""
      self.server_opts.each do |key, value|
        if value.kind_of?(Array)
          value.each { |subvalue| config_data << self.class.build_config_line(key, subvalue) << "\n" }
        else
          config_data << self.class.build_config_line(key, value) << "\n"
        end
      end
      config_data
    end

    # Clean up server files associated with this instance. Expects
    # #opts[:cleanup_files] to already be set up
    def cleanup_files
      files_from_symbols(opts[:cleanup_files]) do |file|
        File.exist?(file) && File.delete(file)
      end
    end

    # Iterates over the supplied symbols and yields corresponding filenames
    #
    # @param [Array] file_syms: array of symbols to iterate over
    def files_from_symbols(file_syms)
      file_syms.each do |file_sym|
        yield case file_sym
          when :socket
            server_opts[:unixsocket]
          when :log
            server_opts[:logfile]
          when :config
            @config_file || opts[:generated_config_file]
        end
      end
    end

    # Shortcut for getting name of the configured unix socket file
    def socket
      self.server_opts[:unixsocket]
    end

  end
end
