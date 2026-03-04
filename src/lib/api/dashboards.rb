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
        "name"     => chart_name,
        "query"    => extract_query(chart),
        "settings" => chart["settings"] || {}
      }
    end

    private

    def find_dashboard_id(name)
      data = @client.get("/api/v2/dashboards")
      list = data["data"]

      entry = list.find { |d| d["attributes"]["name"] == name }
      raise "Dashboard '#{name}' not found" unless entry

      entry["id"]
    end

    def find_chart_in_export(export, name)
      charts = export.dig("data", "charts") || []

      chart = charts.find { |c| c["name"] == name }
      raise "Chart '#{name}' not found in dashboard export" unless chart

      chart
    end

    def extract_query(chart)
      chart.dig("chart_queries", 0, "sql_query")
    end
  end
end
