module AppConfigLoader
  class Railtie < Rails::Railtie
    config.before_configuration do
      # initialize the app config before Rails initialization unless it has already been initialized
      AppConfigLoader.init unless AppConfigLoader.initialized?
    end

    rake_tasks do
      # install a rake task for initializing the module
      load File.expand_path('../tasks.rake', __FILE__)
    end
  end
end