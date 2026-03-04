module API
  class Sources
    def initialize(client)
      @client = client
    end

    # Returns { "team_id" => ..., "table_name" => ..., "data_region" => ... }
    def find(name)
      data = @client.get("/api/v2/sources")
      list = data["data"] || data

      entry = list.find do |s|
        attrs = s["attributes"] || s
        attrs["name"] == name
      end
      raise "Source '#{name}' not found" unless entry

      attrs = entry["attributes"] || entry
      {
        "team_id"     => attrs["team_id"],
        "table_name"  => attrs["table_name"],
        "data_region" => attrs["data_region"]
      }
    end
  end
end
