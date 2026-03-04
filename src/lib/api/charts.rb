require "faraday"
require "json"
require "uri"

module API
  class Charts
    def initialize(data_region:, team_id:, table_name:, jwt_token:)
      @data_region = data_region
      @team_id     = team_id
      @table_name  = table_name
      @jwt_token   = jwt_token
    end

    # Fetches chart data and returns array of row hashes.
    # range_from / range_to are epoch microseconds (Integer).
    def fetch(query:, range_from: nil, range_to: nil)
      now        = (Time.now.to_f * 1_000_000).to_i
      range_to   ||= now
      range_from ||= now - (3 * 60 * 60 * 1_000_000) # 3 hours ago

      params = URI.encode_www_form(
        "table"         => "t#{@team_id}.#{@table_name}",
        "defer-errors"  => "true",
        "range-from"    => range_from,
        "range-to"      => range_to,
        "sampling"      => "1"
      )
      url = "https://#{@data_region}-connect.betterstackdata.com/"

      response = Faraday.new(url).post("?#{params}", query) do |req|
        req.headers["Authorization"] = "Bearer #{@jwt_token}"
        req.headers["Content-Type"]  = "text/plain"
      end

      raise "Chart fetch failed: HTTP #{response.status} #{response.headers} #{response.body}" unless response.success?

      rows = parse_rows(response.body)
      { rows: rows, range_to: range_to }
    end

    private

    def parse_rows(body)
      rows = []
      body.each_line do |line|
        line = line.strip
        next if line.empty?
        obj = JSON.parse(line)
        rows << obj unless obj.key?("progress")
      rescue JSON::ParserError
        # skip malformed lines
      end
      rows
    end
  end
end
