require 'fileutils'

class ConfigManager
  CONFIG_FILE = File.expand_path('~/.ai-commit-message.conf')

  def self.get_url = config['url']

  def self.set_url(url)
    config['url'] = url
    save_config
  end

  def self.get_model = config['model']

  def self.set_model(model)
    config['model'] = model
    save_config
  end

  private_class_method

  def self.config
    return @config if defined?(@config)

    @config ||= {}

    if File.exist?(CONFIG_FILE)
      File.each_line(CONFIG_FILE) do |line|
        key, value = line.chomp.split('=')
        @config[key.to_sym] = value
      end
    end

    @config
  end

  def self.save_config = File.write(CONFIG_FILE, config.map { |key, value| "#{key}=#{value}" }.join("\n"))
end