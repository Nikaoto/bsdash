module API
  class Sources
    def initialize(client)
      @client = client
    end

    # Returns { "team_id" => ..., "table_name" => ..., "data_region" => ... }
    def find(name)
      res = @client.get("/api/v1/sources")
      list = res["data"]

      entry = list.find do |s|
        attrs = s["attributes"]
        attrs["name"] == name
      end
      raise "Source '#{name}' not found" unless entry

      attrs = entry["attributes"]
      {
        "team_id"     => attrs["team_id"],
        "table_name"  => attrs["table_name"],
        "data_region" => attrs["data_region"]
      }
    end
  end
end
