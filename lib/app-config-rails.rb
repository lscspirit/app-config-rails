require 'app-config-rails/errors'
require 'app-config-rails/config'
require 'app-config-rails/loader'
require 'app-config-rails/parser'
require 'app-config-rails/config_entry'
require 'app-config-rails/config_map'
require 'app-config-rails/config_with_indifferent_access'

module AppConfigRails
  def self.load(config = nil)
    raise ArgumentError, 'config must be a AppConfigRails::Config instance' unless config.nil? || config.is_a?(AppConfigRails::Config)

    active_cfg = config || default_config

    yield active_cfg if block_given?

    Loader.new(active_cfg).load
  end

  private

  def self.default_config
    cfg = AppConfigRails::Config.new
    cfg.env = Rails.env
    cfg.config_paths <<   Rails.root.join('config', 'app_configs')
    cfg.local_overrides = Rails.root.join('config', 'app_configs', 'local_overrides.yml')
    cfg
  end
end