module AppConfigLoader
  class ConfigEntry
    include Comparable

    attr_reader :env, :domain, :key_components, :value

    #
    # Constructor
    #
    def initialize(full_key, value, use_domain = false)
      @use_domain = use_domain
      @env, @domain, @key_components = parse_full_key full_key
      @value = value
    end

    #
    # Accessor
    #

    # Config key without env and domain
    #
    # @return [String] config key without the env and domain
    def key
      @key_components.join('.')
    end

    # Config key including env and domain
    # The domain portion is included if +config.use_domain+ is +true+
    #
    # @return [String] config key including the env and domain
    def full_key
      prefix = @env == :any ? '*.' : "#{@env}."
      prefix += @domain == :any ? '*.' : "#{@domain}." if @use_domain
      "#{prefix}#{self.key}"
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

    def to_s
      "#{self.full_key}: #{self.value}"
    end

    #
    # Comparison
    #

    def ==(other)
      other.class == self.class &&
        other.env == self.env &&
        other.domain == self.domain &&
        other.key_components == self.key_components &&
        other.value == self.value
    end
    alias_method :eql?, :==

    def <=>(other)
      # first compare key size
      comp = self.key_components.count <=> other.key_components.count
      return comp if comp != 0

      # lexically compare the actual key components
      other_keys = other.key_components
      self.key_components.each_with_index do |key, index|
        comp = key <=> other_keys[index]
        return comp if comp != 0
      end

      # compare specificity
      comp = self.specificity <=> other.specificity
      return comp if comp != 0

      # compare env
      comp = wildcard_compare self.env, other.env
      return comp if comp != 0

      # compare domain
      wildcard_compare self.domain, other.domain
    end

    private

    def parse_full_key(full_key)
      key_ary = full_key.split('.')

      raise InvalidConfigKey, "invalid config key '#{full_key}': must have a env component" unless key_ary.length > 1
      raise InvalidConfigKey, "invalid config key '#{full_key}': must have a domain component when 'use_domain' is enabled" unless !@use_domain || key_ary.length > 2

      begin
        env    = normalize_key_component key_ary[0], true
        domain = @use_domain ? normalize_key_component(key_ary[1], true) : :any
        components = (@use_domain ? key_ary[2..-1] : key_ary[1..-1]).map{ |k| normalize_key_component k }
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

    def wildcard_compare(target, other)
      if (diff = target <=> other) # comparing a symbol with string returns nil
        diff
      elsif target == :any
        -1
      else
        1
      end
    end
  end
end