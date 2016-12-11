require 'yaml'

module AppConfigLoader
  class Parser
    def initialize(use_domain = false)
      @use_domain = use_domain
    end

    # Parse a YAML format text and returns flattened list of all key entries
    #
    # @return Array<KeyEntry> list of key entries
    def parse(content)
      flatten_keys YAML.load(content)
    end

    private

    def flatten_keys(cfg, current_full_key = nil)
      cfg.reduce([]) do |flattened, (key, value)|
        raise InvalidConfigKey, 'config key component must be a string' unless key.is_a?(String)

        this_key = current_full_key ? "#{current_full_key}.#{key}" : key
        if value.is_a? Hash
          flattened += flatten_keys value, this_key
        else
          flattened << ConfigEntry.new(this_key, value, @use_domain)
        end

        flattened
      end
    end
  end
end