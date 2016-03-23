module AppConfigRails
  class Config
    attr_accessor :env, :domain, :local_overrides

    def config_paths
      @config_paths ||= []
    end

    def use_domain
      @use_domain === true
    end

    def use_domain=(use)
      @use_domain = !!use
    end
  end
end