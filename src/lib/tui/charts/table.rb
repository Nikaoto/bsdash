require "tty-table"
require "tty-screen"
require "pastel"
require "strings"

module TUI
  module Charts
    class Table
      BAR_WIDTH = 10
      LINK_RE   = /\[([^\]]+)\]\(([^)]+)\)/

      def initialize
        @pastel = colors_enabled? ? Pastel.new : nil
      end

      def render(rows, max_height:, settings: {})
        return "  No data." if rows.nil? || rows.empty?

        column_units = settings["column_units"] || {}
        pct_columns  = settings["percentage_highlight_columns"] || []
        columns      = rows.first.keys

        col_maxes = {}
        pct_columns.each do |col|
          col_maxes[col] = rows.filter_map { |r| r[col]&.to_f }.max.to_f
        end

        data = rows.map do |r|
          columns.map { |col| format_cell(r[col], column_units[col]) }
        end

        pct_max_widths = {}
        pct_columns.each do |col|
          idx = columns.index(col)
          next unless idx
          pct_max_widths[col] = data.map { |row| visible_length(row[idx].to_s) }.max.to_i
        end

        data = data.each_with_index.map do |row, ri|
          columns.each_with_index.map do |col, ci|
            cell = row[ci]
            if pct_columns.include?(col) && col_maxes[col].to_f > 0
              pad  = pct_max_widths[col] - visible_length(cell)
              cell = "#{cell}#{' ' * pad} #{render_bar(rows[ri][col].to_f / col_maxes[col])}"
            end
            cell
          end
        end

        max_rows = [max_height - 3, 1].max
        data     = data.first(max_rows)

        # Pre-truncate first column with ANSI-aware truncation so tty-table's
        # internal truncation never clips an escape sequence and bleeds color.
        first_w = first_col_width(columns, data)
        data = data.map do |row|
          first = row[0].to_s
          cell  = visible_length(first) > first_w ? Strings.truncate(first, first_w) : first
          [cell] + row[1..]
        end

        table = TTY::Table.new(header: columns, rows: data)
        table.render(:unicode, width: TTY::Screen.width, resize: true) rescue table.render(:basic)
      end

      private

      # Available width for column 0 = terminal width minus borders minus natural
      # widths of all other columns. Minimum 3 chars so it never disappears.
      # Border overhead for n columns in unicode tty-table: 3n + 1
      def first_col_width(columns, data)
        n              = columns.size
        available      = TTY::Screen.width - (3 * n + 1)
        others_natural = columns[1..].each_with_index.sum do |col, i|
          w = visible_length(col)
          data.each { |row| w = [w, visible_length(row[i + 1].to_s)].max }
          w
        end
        [available - others_natural, 3].max
      end

      def visible_length(str)
        str.gsub(/\e\[[0-9;]*[mK]/, "").length
      end

      def colors_enabled?
        return false unless $stdout.isatty
        term = ENV["TERM"].to_s
        term.include?("color") || term.include?("256") || ENV["COLORTERM"].to_s != ""
      end

      def format_cell(value, unit_info)
        if unit_info && unit_info["unit"] == "B_iec"
          format_bytes_iec(value)
        else
          colorize_links(value.to_s)
        end
      end

      def colorize_links(str)
        return str unless @pastel
        str.gsub(LINK_RE) do
          name = Regexp.last_match(1)
          url  = Regexp.last_match(2)
          @pastel.cyan.bold("[#{name}]") + @pastel.dim("(#{url})")
        end
      end

      def render_bar(pct)
        pct    = pct.clamp(0.0, 1.0)
        filled = (pct * BAR_WIDTH).round
        empty  = BAR_WIDTH - filled
        if @pastel
          @pastel.green("█" * filled) + @pastel.dim("░" * empty)
        else
          "█" * filled + "░" * empty
        end
      end

      def format_bytes_iec(bytes)
        return "-" if bytes.nil?
        b = bytes.to_f
        if b >= 1024 ** 3
          "%.2f GiB" % (b / 1024.0 ** 3)
        elsif b >= 1024 ** 2
          "%.2f MiB" % (b / 1024.0 ** 2)
        elsif b >= 1024
          "%.2f KiB" % (b / 1024.0)
        else
          "%.0f B" % b
        end
      end
    end
  end
end
