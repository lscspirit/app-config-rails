namespace :app_config_loader do
  task :init do
    # initialize AppConfigLoader unless it has already been done so
    AppConfigLoader.init unless AppConfigLoader.initialized?
  end
end

# initialize the module before db:load_config task so that app config is available for all 'db' tasks
Rake::Task['db:load_config'].enhance %w(app_config_loader:init)
