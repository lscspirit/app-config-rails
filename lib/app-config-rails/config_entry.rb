module AppConfigRails
  class ConfigEntry
    attr_reader :env, :domain, :key_components, :value

    #
    # Constructor
    #
    def initialize(full_key, value, use_domain = false)
      @env, @domain, @key_components = parse_full_key full_key, use_domain
      @value = value
    end

    #
    # Accessor
    #

    def key
      @key_components.join('.')
    end

    def specificity
      score = 0
      score += 1  if @env != :any       # add one point if env is specified
      score += 10 if @domain != :any    # add 10 points if domain is specified
      score
    end

    def applicable?(target_env, target_domain = nil)
      # first matches enviroment
      return false if env != target_env && env != :any

      # then matches domain
      return false if target_domain && domain != :any && domain != target_domain

      true
    end

    def ==(o)
      o.class == self.class &&
        o.env == self.env &&
        o.domain == self.domain &&
        o.key_components == self.key_components &&
        o.value == self.value
    end
    alias_method :eql?, :==

    private

    def parse_full_key(full_key, use_domain)
      key_ary = full_key.split('.')

      raise InvalidConfigKey, "invalid config key '#{full_key}': must have a env component" unless key_ary.length > 1
      raise InvalidConfigKey, "invalid config key '#{full_key}': must have a domain component when 'use_domain' is enabled" unless !use_domain || key_ary.length > 2

      begin
        env    = normalize_key_component key_ary[0], true
        domain = use_domain ? normalize_key_component(key_ary[1], true) : :any
        components = (use_domain ? key_ary[2..-1] : key_ary[1..-1]).map{ |k| normalize_key_component k }
      rescue => ex
        raise InvalidConfigKey, "invalid config key component in '#{full_key}': #{ex.message}"
      end

      return env, domain, components
    end

    def normalize_key_component(comp, wildcard = false)
      if comp == '*'
        raise 'wildcard is only allowed in the \'env\' and \'domain\' component' unless wildcard
        :any
      else
        comp.to_s
      end
    end
  end
end