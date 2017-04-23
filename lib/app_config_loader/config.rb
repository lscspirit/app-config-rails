module AppConfigLoader
  class Config
    attr_accessor :const_name, :env, :domain, :local_overrides

    def config_paths
      @config_paths ||= []
    end

    def use_domain
      @use_domain === true
    end
    alias_method :use_domain?, :use_domain

    def use_domain=(use)
      @use_domain = !!use
    end

    def domain
      use_domain? ? @domain : nil
    end
  end
end