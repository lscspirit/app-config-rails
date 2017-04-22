module AppConfigLoader
  class ConfigMap
    def initialize
      @key_map = {}
    end

    def add(entry, overwrite = false)
      deep_add(@key_map, entry.key_components) do |existing|
        if existing
          # only override the existing entry if 'force' is true or
          # the new entry has a higher specificity
          overwrite || entry.specificity >= existing.specificity ? entry : existing
        else
          entry
        end
      end
    end

    def <<(entry)
      add entry, false
    end

    def get(key)
      components = key.split('.')
      components.reduce(@key_map) do |parent, comp|
        # return nil if the parent is not a Hash
        break nil unless parent.is_a?(Hash)
        parent[comp.to_sym]
      end
    end
    alias_method :[], :get

    def to_a
      deep_list @key_map
    end

    def merge(config_map)
      config_map.to_a.each { |override| self.add override, true }
    end

    private

    def deep_add(parent, keys, &block)
      current_key = keys[0].to_sym

      val = parent[current_key]

      if keys.count == 1

        #
        # the last key
        #

        # check if the key has child configuration
        raise ConfigKeyConflict, "key conflict: '#{current_key}' has at least one child config" if val.is_a?(Hash)

        # yield to the block to determine what value to assign to the key
        parent[current_key] = yield val
      else
        #
        # has more keys
        #

        # check if the key already has a value assigned
        raise ConfigKeyConflict, "key conflict: '#{current_key}' already has a value assigned" unless val.nil? || val.is_a?(Hash)

        # go to the next level
        val = (parent[current_key] ||= {})
        deep_add val, keys[1..-1], &block
      end
    end

    def deep_list(root)
      list = []

      root.each do |key, value|
        if value.is_a?(Hash)
          list += deep_list value
        else
          list << value
        end
      end

      list
    end
  end
end