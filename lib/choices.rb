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
        mash1 = Hashie::Mash.new(load_settings_hash(file_name))
        mash.merge!(mash1)
        puts("*****************************")
        puts(file_name)
        puts(mash1)
        puts(mash)
        puts("*****************************")
      end
    else
      mash = Hashie::Mash.new(load_settings_hash(filename))
    end
    puts("\n ########################### \n")
    puts(mash)
    puts("\n ########################### \n")
    with_local_settings(filename, '.local') do |local|
      mash.update local
    end
    puts("\n ########################### \n")
    puts(mash)
    puts("\n ########################### \n")

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
    puts(local_filename)
    if File.exist? local_filename
      hash = load_settings_hash(local_filename)
      yield hash if hash
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
