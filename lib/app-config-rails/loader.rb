module AppConfigRails
  class Loader
    def initialize(config)
      @config = config
      @parser = Parser.new

      raise 'Environement is not set in AppConfigRails::Config' unless @config.env
    end

    # Load app config entries from yml paths listed in the
    # AppConfigRails::Config's 'config_paths' and 'local_override' properties
    def load
      cfg_map = ConfigMap.new

      # Reads the raw config entries from the file list configured
      # in the @config object
      expanded_paths.each do |path|
        begin
          raw_entries = parse_yml path
          raw_entries.each { |e| cfg_map << e }
        rescue InvalidConfigKey => ex
          raise InvalidConfigFile, "config key error '#{path}': #{ex.message}"
        end
      end

      if (override_path = local_override_path)
        override_map = ConfigMap.new

        begin
          override_entries = parse_yml override_path
          override_entries.each { |e| override_map.add e, true }

          # merges the override entries into the main config map
          cfg_map.merge override_map
        rescue InvalidConfigKey => ex
          raise InvalidConfigFile, "config key error '#{local_override_path}': #{ex.message}"
        end
      end

      ConfigWithIndifferentAccess.new cfg_map
    end

    private

    def parse_yml(path)
      @parser.parse ERB.new(File.read(path)).result
    end

    # Expands the list of path entries into absolute paths for each matching files
    #
    # @return [Array<String>] absolute paths of all entries in the @config.config_paths
    def expanded_paths
      @config.config_paths.reduce(Set.new) do |memo, path|
        if File.directory? path
          Dir.chdir(path) do
            # add all files (recursively) within the directory
            memo += Dir.glob('**/*').map { |f| File.absolute_path f, path }
          end
        elsif File.exists? path
          # add the file to the list if it exists
          memo << File.absolute_path(path)
        else
          # try to glob the entries and add the result to the list
          memo += Dir.glob(path).map { |f| File.absolute_path f, path }
        end

        memo
      end
    end

    def local_override_path
      @config.local_overrides ? File.absolute_path(@config.local_overrides) : nil
    end
  end
end