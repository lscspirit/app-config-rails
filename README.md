# AppConfigLoader

A customizable YAML configuration library for Rails and Ruby, featuring wildcards, nesting, namespacing and local override. 

## Getting Started

Add the following line to your Gemfile:

```ruby
gem 'app_config_loader'
```

Run the bundle command to install it.

Create a YAML file in the default directory `config/app_configs` to put your app config. For example:

```YAML
# config/app_configs/some_service.yml

'*.some_service':
  'host': dev.someservice.com

'production.some_service':
  'host': prod.someservice.com
```

From this point onward, you can access your app config values through `APP_CONFIG`.

```ruby
# when AppConfigLoader's env is not "production"
APP_CONFIG['some_service.host']  # => 'dev.someservice.com'

# when AppConfigLoader's env is set to "production"
APP_CONFIG['some_service.host']  # => 'prod.someservice.com'
```

### Non-Rails Environment

When using `AppConfigLoader` outside of Rails, getting started is a little different:

* the default app config file directory is `<pwd>/app_configs`
* you need to manually initialize `AppConfigLoader` by including the following early on in your code:
  ```ruby
  AppConfigLoader.init
  ```

## Configuration

You can configure where and how AppConfigLoader load your app config file(s). 

In Rails, the following code should be placed
before Rails is initialized but after your Rails application is defined (e.g. `config/application.rb`). Outside Rails, this should be placed before the `AppConfigLoader.init` call. 

```ruby
AppConfigLoader.configure do |config|
  config.use_domain = true
  config.domain = 'us'
  config.config_paths << '/path/to/additional_config.yml'
end
```

Below is a list of all options available:

* `config.const_name` - (String) the name of the constant to which the config object is assigned. **Default:** `APP_CONFIG`
* `config.env` - (String) app config environment. This determines which set of app config values to load. **Default:** Rails - `Rails.env`, non-Rails - `ENV['RACK_ENV'] || ENV['RUBY_ENV']`
* `config.use_domain` - (Boolean) whether the app config key uses a domain. **Default:** `false`
* `config.domain` - (String) app config domain. This determines which set of app config values to load. It is only applicable if `use_domain` is set to true. **Default:** `nil`
* `config.config_paths` - (Array&lt;String&gt;) a list of paths from where app config YAML files should be loaded. Path can either be a file or a directory. With a directory path, all YAML files within that directory will be loaded. **Default:** Rails - `['<rails root>/config/app_configs']`, non-Rails - `['<pwd>/app_configs']`
* `config.local_overrides` - (String) path to a local overrides app config file. Entries in this file take precedence over all values from other files. **Default:** Rails - `<rails root>/config/app_configs/local_overrides.yml`, non-Rails - `<pwd>/app_configs/local_overrides.yml`

## Defining your App Configs

All app configs are defined as key-value entries in YAML format. A app config value can be any valid YAML value, except for Hash. The app config key must follow either of the format below depending on whether `use_domain` is enabled:

* `<env>.<key...>` - when `use_domain` is disabled (e.g. `production.some_service.host`)
* `<env>.<domain>.<key...>` - when `use_domain` is enabled (e.g. `production.us.some_service.host`)

#### Basic Example

```YAML
# app config in YAML file
'test.timeout': 3000
'test.some_service.host': 'dev.someservice.com'

'production.timeout': 500
'production.some_service.host': 'prod.someservice.com'
'production.some_service.port': 8000
```

```ruby
# Rails initialization
AppConfigLoader.configure do |config|
  config.env = 'test'
end

# after AppConfigLoader is initialized
APP_CONFIG['timeout']             # => 3000
APP_CONFIG['some_service.host']   # => dev.someservice.com
APP_CONFIG['some_service.port']   # => nil
```

```ruby
# Rails initialization
AppConfigLoader.configure do |config|
  config.env = 'production'
end

# after AppConfigLoader is initialized
APP_CONFIG['timeout']             # => 500
APP_CONFIG['some_service.host']   # => prod.someservice.com
APP_CONFIG['some_service.port']   # => 8000
```

#### Nested Definition

```YAML
'production.some_service':
  'host': 'prod.someservice.com'
  'port': 8000
```
```ruby
APP_CONFIG['some_service.host']   # => prod.someservice.com
APP_CONFIG['some_service.port']   # => 8000
```

#### Namespacing with Domain

You may use `domain` to group your configuration. For example, you can provide different configuration when running in different regions.

```YAML
# app config in YAML file
'production.us.some_service.host': 'prod.someservice.com'
'production.hk.some_service.host': 'prod.someservice.com.hk'
```
```ruby
# Rails initialization
AppConfigLoader.configure do |config|
  config.env = 'production'
  config.use_domain = true
  config.domain     = 'us'
end

# after AppConfigLoader is initialized
APP_CONFIG['some_service.host']   # => prod.someservice.com
```
```ruby
# Rails initialization
AppConfigLoader.configure do |config|
  config.env = 'production'
  config.use_domain = true
  config.domain     = 'hk'
end

# after AppConfigLoader is initialized
APP_CONFIG['some_service.host']   # => prod.someservice.com.hk
```

#### Using Wildcard Env and Domain

You may use the wildcard `*` in place of the env and the domain. This allows you to specify app config entry that is applicable in any env or domain. An app config entry with a specific env or domain always takes precedence over ones with wildcard of the same key.

```YAML
# app config in YAML file
'*.some_service.host': 'dev.someservice.com'
'production.some_service.host': 'prod.someservice.com'
```
```ruby
# Rails initialization
AppConfigLoader.configure do |config|
  config.env = 'test'
end

# after AppConfigLoader is initialized
APP_CONFIG['some_service.host']   # => dev.someservice.com
```
```ruby
# Rails initialization
AppConfigLoader.configure do |config|
  config.env = 'production'
end

# after AppConfigLoader is initialized
APP_CONFIG['some_service.host']   # => prod.someservice.com
```

### Specificity

When there a multiple app config entries for the same key, the final value is resolved based upon the specificity of the entry. The entry with the highest specificity take precedence over all other entries. In the case when more than one entries have the same specificity, the entry that is last read will take precedence.

```YAML
'production.us.some_service.host': 'prod.someservice.com'     # highest specificity
'*.us.some_service.host': 'prod.someservice.com'
'production.*.some_service.host': 'prod.someservice.com'
'*.*.some_service.host': 'prod.someservice.com'               # lowest specificity
```

### Key Conflict

In most cases, entries belonging to or falling under the same key can be resolved by specificity. However, there are cases when the entries' values
conflict with each other and a `ConfigKeyConflict` error will be raises. 

* Assigning value to key with children

  ```YAML
  *.key_with_children.child_1: 'child1'
  *.key_with_children.child_2: 'child2'
  production.key_with_children: 'some value'

  ```
  The config above will raise `ConfigKeyConflict` error, regardless of the different in specificity. 
  
* Assigning children to key with value

  ```YAML
  production.key_with_value: 'some value'
  *.key_with_value.child_1: 'child1'

  ```
  The config above will raise `ConfigKeyConflict` error, regardless of the different in specificity. 
  

## Local Overrides File

The local overrides file provides a quick way to override any entries defined in regular app config files. Entries within this file are resolved according to the specificity rule. Once resolved, the resolved entries will override any existing entries regardless of specificity. This is meant for development or testing purposes. Typically, you would not want to check this file into your source repository.

## Manual Load

Apart from initializing the module using `AppConfigLoader.init`, you may also manually parse and load app config. 

```ruby
config = AppConfigLoader::Config.new
config.use_domain = true
config.env = 'development'
config.config_paths << '/path/to/app_config.yml'

app_config = AppConfigLoader::load(config)
app_config['some_config.key']   #=> config value for the 'some_config.key' key

```

## Contributors

Bug reports and pull requests are welcome on GitHub at https://github.com/lscspirit/app_config_loader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2016 Derrick Yeung, released under the MIT license.
See [MIT License](http://opensource.org/licenses/MIT) for details.