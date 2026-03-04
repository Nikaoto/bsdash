require "tty-table"
require "tty-screen"

module TUI
  module Charts
    class Table
      def render(rows, max_height:)
        return "  No data." if rows.nil? || rows.empty?

        columns = rows.first.keys
        data    = rows.map { |r| columns.map { |c| r[c].to_s } }

        # Clamp to available height: header + separator + data rows + border rows = data.length + 3
        max_rows   = [max_height - 3, 1].max
        data       = data.first(max_rows)

        table = TTY::Table.new(header: columns, rows: data)
        table.render(:unicode, width: TTY::Screen.width, resize: true) rescue table.render(:basic)
      end
    end
  end
end
