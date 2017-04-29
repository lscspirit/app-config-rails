module AppConfigLoader
  class ConfigWithIndifferentAccess
    include Enumerable

    def initialize(map, prefix = nil)
      @config_map = map
      @prefix     = prefix
    end

    # Get value for a specified config key
    #
    # @param [String] key app config key
    #
    # @return the value for the key or another ConfigWithIndifferentAccess; nil if there is no value at the key
    #
    # @example Getting key value
    #   app_config['some_service.host']      # => 'dev.someservice.com'
    #   app_config.get('some_service.host')  # => 'dev.someservice.com'
    def get(key)
      # append prefix to the key if needed
      target_key = @prefix ? "#{@prefix}.#{key}" : key.to_s

      # return either nil, the value or another ConfigWithIndifferentAccess depending on
      # what is at the key
      case (entry = @config_map[target_key])
        when ConfigEntry
          entry.value
        when Hash
          self.class.new @config_map, target_key
        else
          nil
      end
    end
    alias_method :[], :get

    def to_a
      @config_map.to_a
    end

    def each(&block)
      @config_map.each(&block)
    end
  end
end