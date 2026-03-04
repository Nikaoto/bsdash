module API
  class Dashboards
    def initialize(client)
      @client = client
    end

    # Returns { "name" => chart_name, "query" => sql_string }
    def find_chart(dashboard_name:, chart_name:)
      dash_id = find_dashboard_id(dashboard_name)
      export  = @client.get("/api/v2/dashboards/#{dash_id}/export")
      chart   = find_chart_in_export(export, chart_name)

      {
        "name"  => chart_name,
        "query" => extract_query(chart)
      }
    end

    private

    def find_dashboard_id(name)
      data = @client.get("/api/v2/dashboards")
      list = data["data"] || data

      entry = list.find do |d|
        attrs = d["attributes"] || d
        attrs["name"] == name
      end
      raise "Dashboard '#{name}' not found" unless entry

      entry["id"] || (entry["attributes"] || entry)["id"]
    end

    def find_chart_in_export(export, name)
      # Export structure varies; try common locations
      charts = export["charts"] ||
               export["data"]&.flat_map { |d| d["charts"] || [] } ||
               []

      chart = charts.find do |c|
        attrs = c["attributes"] || c
        attrs["name"] == name
      end
      raise "Chart '#{name}' not found in dashboard export" unless chart

      chart
    end

    def extract_query(chart)
      attrs = chart["attributes"] || chart
      attrs["query"] || attrs["sql"] || attrs["query_string"]
    end
  end
end
