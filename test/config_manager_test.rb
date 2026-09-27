require_relative 'test_helper'

class ConfigManagerTest < Minitest::Test
  def setup
    @config_file = Tempfile.new('ai-commit-message-test')
    @config_file.close
    stub_constant
    reset_cache
  end

  def teardown
    restore_constant
    @config_file.unlink
  end

  def test_defaults_to_empty_config
    assert_nil ConfigManager.get_url
    assert_nil ConfigManager.get_model
  end

  def test_set_and_get_roundtrip
    ConfigManager.set_url('http://localhost:1234')
    ConfigManager.set_model('qwen3:8b')
    assert_equal 'http://localhost:1234', ConfigManager.get_url
    assert_equal 'qwen3:8b', ConfigManager.get_model
  end

  def test_persists_to_config_file
    ConfigManager.set_url('http://localhost:1234')
    ConfigManager.set_model('qwen3:8b')

    reset_cache
    assert_equal 'http://localhost:1234', ConfigManager.get_url
    assert_equal 'qwen3:8b', ConfigManager.get_model
  end

  def test_loads_existing_config_file
    File.write(@config_file.path, "url=http://localhost:8080\nmodel=gemma3:4b\n")
    reset_cache
    assert_equal 'http://localhost:8080', ConfigManager.get_url
    assert_equal 'gemma3:4b', ConfigManager.get_model
  end

  def test_config_file_is_owner_only
    ConfigManager.set_url('http://localhost:1234')
    assert_equal 0600, File.stat(@config_file.path).mode & 0777
  end

  private

  def stub_constant
    @original = ConfigManager.const_get(:CONFIG_FILE)
    ConfigManager.send(:remove_const, :CONFIG_FILE)
    ConfigManager.const_set(:CONFIG_FILE, @config_file.path)
  end

  def restore_constant
    ConfigManager.send(:remove_const, :CONFIG_FILE)
    ConfigManager.const_set(:CONFIG_FILE, @original)
  end

  def reset_cache
    ConfigManager.remove_instance_variable(:@config) if ConfigManager.instance_variable_defined?(:@config)
  end
end
