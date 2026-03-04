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

      res = Faraday.new(url).post("?#{params}", expand_template(query, range_from: range_from, range_to: range_to)) do |req|
        req.headers["Authorization"] = "Bearer #{@jwt_token}"
        req.headers["Content-Type"]  = "text/plain"
      end

      raise "Chart fetch failed: HTTP #{res.status}" unless res.success?

      rows = parse_rows(res.body)
      { rows: rows, range_to: range_to }
    end

    private

    def expand_template(query, range_from:, range_to:)
      source_ref = "remote(t#{@team_id}_#{@table_name}_metrics)"

      sql = query.dup
      sql.gsub!(/\[\[.*?\]\]/m, "")
      sql.gsub!(/\{\{time\}\}/,                        "toStartOfInterval(dt, INTERVAL '60 second')")
      sql.gsub!(/\{\{source(?:_with_all_services)?\}\}/, source_ref)
      sql.gsub!(/\{\{start_time\}\}/,                  clickhouse_time(range_from))
      sql.gsub!(/\{\{end_time\}\}/,                    clickhouse_time(range_to))
      sql.rstrip + "\nFORMAT JSONEachRowWithProgress\nSETTINGS max_result_rows = 500000\n"
    end

    def clickhouse_time(epoch_us)
      t      = Time.at(epoch_us / 1_000_000.0).utc
      micros = (epoch_us % 1_000_000).to_s.rjust(6, "0")
      "toDateTime64('#{t.strftime('%Y-%m-%d %H:%M:%S')}.#{micros}', 6)"
    end

    def parse_rows(body)
      rows = []
      body.each_line do |line|
        line = line.strip
        next if line.empty?
        obj = JSON.parse(line)
        rows << obj["row"] if obj.key?("row")
      rescue JSON::ParserError
        # skip malformed lines
      end
      rows
    end
  end
end
