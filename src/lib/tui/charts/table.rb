require "tty-table"
require "tty-screen"

module TUI
  module Charts
    class Table
      def render(rows, max_height:, settings: {})
        return "  No data." if rows.nil? || rows.empty?

        column_units = settings["column_units"] || {}
        columns      = rows.first.keys
        data         = rows.map do |r|
          columns.map { |c| format_cell(r[c], column_units[c]) }
        end

        max_rows = [max_height - 3, 1].max
        data     = data.first(max_rows)

        table = TTY::Table.new(header: columns, rows: data)
        table.render(:unicode, width: TTY::Screen.width, resize: true) rescue table.render(:basic)
      end

      private

      def format_cell(value, unit_info)
        if unit_info && unit_info["unit"] == "B_iec"
          format_bytes_iec(value)
        else
          value.to_s
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
