module AppConfigLoader
  class Railtie < Rails::Railtie
    config.before_initialize do
      # initialize the app config before Rails initialization
      AppConfigLoader.init
    end
  end
end