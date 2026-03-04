require "json"
require "fileutils"

class Cache
  PATH = File.expand_path("~/.config/bsdash/cache.json")

  def initialize
    @data = load_data
  end

  def source
    @data["source"]
  end

  def source=(val)
    @data["source"] = val
    save
  end

  def chart
    @data["chart"]
  end

  def chart=(val)
    @data["chart"] = val
    save
  end

  private

  def load_data
    return {} unless File.exist?(PATH)
    JSON.parse(File.read(PATH))
  rescue JSON::ParserError
    {}
  end

  def save
    FileUtils.mkdir_p(File.dirname(PATH))
    File.write(PATH, JSON.pretty_generate(@data))
  end
end
