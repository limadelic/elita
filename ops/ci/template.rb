module Template
  CSS_RULES = <<~CSS.freeze
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font: 14px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #f8f9fa; color: #333; padding: 20px; }
    .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 6px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1); overflow: hidden; }
    .header { padding: 30px; background: linear-gradient(135deg, #f5f5f5 0%, #e8e8e8 100%);
      border-bottom: 1px solid #ddd; }
    h1 { font-size: 28px; font-weight: 600; color: #173647; margin-bottom: 20px; }
    .summary-row { display: flex; gap: 30px; flex-wrap: wrap; }
    .summary-item { flex: 1; min-width: 200px; }
    .summary-label { font-size: 12px; text-transform: uppercase; color: #666;
      letter-spacing: 0.5px; margin-bottom: 8px; }
    .summary-value { font-size: 32px; font-weight: 700; padding: 10px 15px; border-radius: 4px;
      display: inline-block; color: white; }
    .content { padding: 30px; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; padding: 12px; font-weight: 600; font-size: 12px;
      text-transform: uppercase; color: #666; border-bottom: 2px solid #ddd; background: #fafafa; }
    td { padding: 12px; border-bottom: 1px solid #eee; }
    tr:hover { background: #f9f9f9; }
    .module-name { font-weight: 500; color: #0066cc; text-decoration: none; }
    .module-name:hover { text-decoration: underline; }
    .pct-cell { width: 100px; text-align: right; font-weight: 600; color: white; font-size: 13px; }
    .bar-cell { width: 200px; }
    .bar-container { width: 100%; height: 24px; background: #e8e8e8; border-radius: 2px;
      overflow: hidden; }
    .bar-fill { height: 100%; display: flex; align-items: center; justify-content: flex-end;
      padding-right: 6px; font-size: 11px; font-weight: 600; color: white; }
    .footer { padding: 20px 30px; background: #fafafa; border-top: 1px solid #eee;
      font-size: 12px; color: #666; }
  CSS

  def self.render(modules, total, count, zeros, dropped)
    "#{build_header(total, count, zeros, dropped)}#{build_rows(modules)}#{build_footer}"
  end

  def self.build_header(total, count, zeros, dropped)
    color = color_for(total)
    total_fmt = format('%.2f', total)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Coverage Report</title>
        <style>#{CSS_RULES}</style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Coverage Report</h1>
            <div class="summary-row">
              #{summary_tiles(color, total_fmt, count, zeros, dropped)}
            </div>
          </div>
          <div class="content">
            <table>
              <thead>
                <tr>
                  <th>Module</th>
                  <th>Coverage</th>
                  <th>Visual</th>
                </tr>
              </thead>
              <tbody>
    HTML
  end

  def self.summary_tiles(color, total_fmt, count, zeros, dropped)
    <<~HTML
      <div class="summary-item">
        <div class="summary-label">Total Coverage</div>
        <div class="summary-value" style="background-color: ##{color};">#{total_fmt}%</div>
      </div>
      <div class="summary-item">
        <div class="summary-label">Modules (with pages)</div>
        <div style="font-size: 32px; font-weight: 700;">#{count}</div>
      </div>
      <div class="summary-item">
        <div class="summary-label">No Coverage</div>
        <div style="font-size: 32px; font-weight: 700; color: #e05d44;">#{zeros}</div>
      </div>
      <div class="summary-item">
        <div class="summary-label">Dropped (no pages)</div>
        <div style="font-size: 32px; font-weight: 700; color: #999;">#{dropped}</div>
      </div>
    HTML
  end

  def self.build_rows(modules)
    rows_html = modules.map { |m| build_row(m) }.join
    "#{rows_html}\n              </tbody>\n            </table>\n          </div>"
  end

  def self.build_row(data)
    name = data[:name]
    pct = data[:pct]
    color = color_for(pct)
    pct_fmt = format('%.2f', pct)
    bar_text = bar_text_for(pct)
    <<~HTML
      <tr>
        <td><a href="Elixir.#{name}.html" class="module-name">#{name}</a></td>
        <td class="pct-cell" style="background-color: ##{color}; border-radius: 4px;">#{pct_fmt}%</td>
        <td class="bar-cell">
          <div class="bar-container">
            <div class="bar-fill" style="width: #{pct}%; background-color: ##{color};">
              #{bar_text}
            </div>
          </div>
        </td>
      </tr>
    HTML
  end

  def self.bar_text_for(pct)
    pct.zero? ? '' : format('%.1f', pct)
  end

  def self.build_footer
    "</div>\n            <div class=\"footer\">\n              Coverage report generated " \
      "by mix cover\n            </div>\n          </div>\n        </body>\n        </html>\n"
  end

  def self.color_for(pct)
    pct >= 80.0 ? '23D96C' : high_or_low(pct)
  end

  def self.high_or_low(pct)
    pct >= 50.0 ? 'dfb317' : 'e05d44'
  end
end
