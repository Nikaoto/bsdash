require "json"
require "fileutils"

class Config
  PATH = File.expand_path("~/.config/bsdash/config.json")

  DEFAULTS = {
    "refresh_interval" => 10
  }.freeze

  def initialize
    @data = load_data
  end

  def [](key)
    @data[key.to_s]
  end

  def []=(key, value)
    @data[key.to_s] = value
    save
  end

  private

  def load_data
    return DEFAULTS.dup unless File.exist?(PATH)
    DEFAULTS.merge(JSON.parse(File.read(PATH)))
  rescue JSON::ParserError
    DEFAULTS.dup
  end

  def save
    FileUtils.mkdir_p(File.dirname(PATH))
    File.write(PATH, JSON.pretty_generate(@data))
  end
end
