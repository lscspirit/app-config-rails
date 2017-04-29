require 'app_config_loader/errors'
require 'app_config_loader/config'
require 'app_config_loader/loader'
require 'app_config_loader/parser'
require 'app_config_loader/config_entry'
require 'app_config_loader/config_map'
require 'app_config_loader/config_with_indifferent_access'

require 'app_config_loader/railtie' if defined?(Rails)

module AppConfigLoader
  #
  # Config
  #

  def self.configure
    yield self.config if block_given?
  end

  def self.init
    cfg = self.config

    raise NameError, "cannot assign app config because '#{cfg.const_name}' is already defined" if Object.const_defined?(cfg.const_name)
    Object.const_set cfg.const_name, self.load(cfg)

    @inited = true
  end

  def self.initialized?
    !!@inited
  end

  def self.load(config = nil)
    raise ArgumentError, 'config must be a AppConfigLoader::Config instance' unless config.nil? || config.is_a?(AppConfigLoader::Config)
    Loader.new(config || self.config).load
  end

  private

  def self.config
    @config ||= self.default_config
  end

  def self.default_config
    cfg = AppConfigLoader::Config.new

    cfg.const_name = 'APP_CONFIG'

    if defined?(Rails)
      cfg.env = Rails.env || ENV['RACK_ENV'] || ENV['RUBY_ENV'] || 'development'
      cfg.config_paths << Rails.root.join('config', 'app_configs')
      cfg.local_overrides = Rails.root.join('config', 'app_configs', 'local_overrides.yml')
    else
      cfg.env = ENV['RACK_ENV'] || ENV['RUBY_ENV'] || 'development'
      cfg.config_paths << File.join(Dir.pwd, 'app_configs')
      cfg.local_overrides = File.join(Dir.pwd, 'config', 'local_overrides.yml')
    end

    cfg
  end
end