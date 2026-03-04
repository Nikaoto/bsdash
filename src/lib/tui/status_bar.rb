require "tty-screen"

module TUI
  class StatusBar
    def render(chart_name:, last_refresh:, fetching:)
      age    = last_refresh ? age_string(Time.now - last_refresh) : "never"
      status = fetching ? "  [fetching...]" : ""
      line   = " #{chart_name} | refreshed #{age} (r to refresh)#{status}"

      # Pad or truncate to terminal width
      width = TTY::Screen.width
      line  = line.ljust(width)[0, width]
      "\e[7m#{line}\e[0m"  # reverse video for status bar
    end

    private

    def age_string(seconds)
      seconds = seconds.to_i
      if seconds < 60
        "#{seconds}s ago"
      elsif seconds < 3600
        "#{seconds / 60}m ago"
      else
        "#{seconds / 3600}h ago"
      end
    end
  end
end
