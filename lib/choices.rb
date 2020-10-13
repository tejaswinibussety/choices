require 'hashie/mash'
require 'erb'
require 'yaml'

module Choices
  extend self

  def load_settings(filename, env)
    byebug
    if filename.is_a? Array
      mash = Hashie::Mash.new()
      filename.each do |file_name|        
        with_settings(file_name) do |patch|
          mash.update patch
        end
      end
    else
      mash = Hashie::Mash.new(load_settings_hash(filename))
      with_local_settings(filename, '.local') do |local|
        mash.update local
      end
    end

    mash.fetch(env) do
      raise IndexError, %{Missing key for "#{env}" in `#{filename}'}
    end
  end

  def load_settings_hash(filename)
    yaml_content = ERB.new(IO.read(filename)).result
    yaml_load(yaml_content)
  end

  def with_local_settings(filename, suffix)
    local_filename = filename.sub(/(\.\w+)?$/, "#{suffix}\\1")
    with_settings(local_filename) do |local|
      yield local if local
    end
  end

  def with_settings(filename)
    if File.exist? filename
      load_settings_hash(filename)
    end
  end

  def yaml_load(content)
    if defined?(YAML::ENGINE) && defined?(Syck)
      # avoid using broken Psych in 1.9.2
      old_yamler = YAML::ENGINE.yamler
      YAML::ENGINE.yamler = 'syck'
    end
    begin
      YAML::load(content)
    ensure
      YAML::ENGINE.yamler = old_yamler if defined?(YAML::ENGINE) && defined?(Syck)
    end
  end
end

if defined? Rails
  require 'choices/rails'
end
