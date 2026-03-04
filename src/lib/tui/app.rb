require "tty-screen"
require "tty-cursor"
require "io/console"

require_relative "status_bar"
require_relative "charts/table"

module TUI
  class App
    POLL_INTERVAL = 0.05  # seconds between input polls

    def initialize(config:, source:, chart:)
      @config  = config
      @source  = source
      @chart   = chart
      @cursor  = TTY::Cursor

      @mutex        = Mutex.new
      @rows         = nil
      @range_to     = nil
      @last_refresh = nil
      @fetching     = false
      @error        = nil
      @redraw       = true
      @running      = true

      @status_bar = TUI::StatusBar.new
      @table      = TUI::Charts::Table.new
    end

    def run
      setup_terminal
      trigger_fetch
      main_loop
    ensure
      restore_terminal
    end

    private

    # Terminal setup / teardown

    def setup_terminal
      @raw_io = $stdin
      @raw_io.raw!
      print @cursor.hide
      print @cursor.clear_screen
    end

    def restore_terminal
      print @cursor.show
      print @cursor.clear_screen
      print @cursor.move_to(0, 0)
      $stdin.cooked!
    rescue IOError
      # stdin may already be closed
    end

    # Main loop

    def main_loop
      trap("WINCH") { @redraw = true }
      last_auto_refresh = Time.now

      while @running
        handle_input

        # Auto-refresh
        interval = (@config["refresh_interval"] || 30).to_i
        if Time.now - last_auto_refresh >= interval
          last_auto_refresh = Time.now
          trigger_fetch
        end

        if @redraw
          redraw
          @redraw = false
        end

        sleep POLL_INTERVAL
      end
    end

    def handle_input
      return unless IO.select([@raw_io], nil, nil, 0)
      key = @raw_io.getc
      case key
      when "q", "\x03" then @running = false  # q or Ctrl-C
      when "r"         then trigger_fetch
      end
    end

    # Fetch

    def trigger_fetch
      return if @fetching
      @mutex.synchronize { @fetching = true }
      @redraw = true

      Thread.new do
        fetch_data
      rescue => e
        @mutex.synchronize { @error = e.message }
      ensure
        @mutex.synchronize { @fetching = false }
        @redraw = true
      end
    end

    def fetch_data
      jwt = fetch_jwt

      api = API::Charts.new(
        data_region: @source["data_region"],
        team_id:     @source["team_id"],
        table_name:  @source["table_name"],
        jwt_token:   jwt
      )

      result = api.fetch(
        query:      @chart["query"],
        range_to:   nil  # always fetch up to now
        # range_from defaults to now-3h inside API::Charts
      )

      @mutex.synchronize do
        @rows         = result[:rows]
        @range_to     = result[:range_to]
        @last_refresh = Time.now
        @error        = nil
      end
    end

    def fetch_jwt
      API::Auth.new(
        session_cookie: @config["session_cookie"],
        team_id:        @source["team_id"]
      ).fetch_jwt
    end

    # ── Rendering ─────────────────────────────────────────────────────────────

    def redraw
      rows, last_refresh, fetching, error = @mutex.synchronize do
        [@rows, @last_refresh, @fetching, @error]
      end

      height = TTY::Screen.height
      output = String.new

      # Move to top-left without clearing (avoids flicker)
      output << @cursor.move_to(0, 0)

      # Status bar (line 1)
      output << @status_bar.render(
        chart_name:   @chart["name"],
        last_refresh: last_refresh,
        fetching:     fetching
      )
      output << "\r\n"

      # Content area
      if error
        output << " Error: #{error}"
      elsif rows.nil?
        output << " Loading..."
      else
        output << @table.render(rows, max_height: height - 1)
      end

      # Clear from cursor to end of screen (removes stale content on resize)
      output << "\e[J"

      print output
      $stdout.flush
    end
  end
end
