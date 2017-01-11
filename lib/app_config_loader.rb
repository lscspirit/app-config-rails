require 'app_config_loader/errors'
require 'app_config_loader/config'
require 'app_config_loader/loader'
require 'app_config_loader/parser'
require 'app_config_loader/config_entry'
require 'app_config_loader/config_map'
require 'app_config_loader/config_with_indifferent_access'

module AppConfigLoader
  def self.load(config = nil)
    raise ArgumentError, 'config must be a AppConfigLoader::Config instance' unless config.nil? || config.is_a?(AppConfigLoader::Config)

    active_cfg = config || default_config

    yield active_cfg if block_given?

    Loader.new(active_cfg).load
  end

  private

  def self.default_config
    cfg = AppConfigLoader::Config.new
    cfg.env = defined?(Rails) ? Rails.env : 'development'
    cfg.config_paths << (defined?(Rails) ? Rails.root.join('config', 'app_configs') : File.join(__dir__, 'app_configs'))
    cfg.local_overrides = defined? (Rails) ? Rails.root.join('config', 'app_configs', 'local_overrides.yml') : File.join(__dir__, 'config', 'local_overrides.yml')
    cfg
  end
end