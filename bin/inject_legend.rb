#!/usr/bin/env ruby

require 'rexml/document'

# Legend definition
LEGEND_CSS = <<~CSS
  <style>
    .legend-container {
      background: var(--cucumber-panel-background-color, oklch(96.8% 0.007 247.896deg));
      border: 1px solid var(--cucumber-panel-accent-color, oklch(92.9% 0.013 255.508deg));
      border-radius: 4px;
      padding: 1em;
      margin: 0 1em 1.5em 1em;
      color: var(--cucumber-panel-text-color, oklch(27.9% 0.041 260.031deg));
    }
    .legend-intro {
      font-size: 0.95em;
      line-height: 1.5;
      margin-bottom: 1em;
    }
    .legend-intro code {
      background: var(--cucumber-code-background-color, oklch(98.4% 0.003 247.858deg));
      color: var(--cucumber-code-text-color, oklch(27.9% 0.041 260.031deg));
      padding: 0.1em 0.3em;
      border-radius: 2px;
      font-size: 0.95em;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    }
    .legend-items {
      display: flex;
      flex-wrap: wrap;
      gap: 1.5em;
      font-size: 0.95em;
    }
    .legend-item {
      display: flex;
      gap: 0.5em;
      align-items: baseline;
    }
    .legend-label {
      font-weight: 600;
      min-width: 2em;
      font-size: 1.1em;
    }
    .legend-meaning {
      opacity: 0.85;
    }
    @media (max-width: 768px) {
      .legend-items {
        flex-direction: column;
        gap: 0.75em;
      }
    }
  </style>
CSS

LEGEND_HTML = <<~HTML
  <div class="legend-container">
    <div class="legend-intro">
      <code>> el &lt;agent&gt;</code> enters elita's REPL (like iex/pry) addressed at an agent; the prompt becomes <code>&lt;agent&gt;></code>. Lines read as a terminal transcript. <code>&amp;</code> fires commands without waiting.
    </div>
    <div class="legend-items">
      <div class="legend-item">
        <span class="legend-label">🤔</span>
        <span class="legend-meaning">Ask: question to agent</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">📢</span>
        <span class="legend-meaning">Tell: delegation</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">✨</span>
        <span class="legend-meaning">Agent reply</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">👀</span>
        <span class="legend-meaning">Get: retrieve data</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">✏️</span>
        <span class="legend-meaning">Set: store data</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">🚀</span>
        <span class="legend-meaning">Spawn: create agent</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">🧪</span>
        <span class="legend-meaning">Spec: read config</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">🎭</span>
        <span class="legend-meaning">Become: switch role</span>
      </div>
    </div>
  </div>
HTML

def inject_legend(html_path)
  content = File.read(html_path)

  # Find the opening <body> tag and inject after it
  if content.include?('<body>')
    # Insert legend right after <body>
    content.sub!('<body>', "<body>#{LEGEND_CSS}#{LEGEND_HTML}")
    File.write(html_path, content)
    puts "Legend injected successfully into #{html_path}"
  else
    puts "ERROR: Could not find <body> tag in #{html_path}"
    exit 1
  end
end

# Main
html_file = ARGV[0] || 'reports/cucumber.html'

unless File.exist?(html_file)
  puts "ERROR: File not found: #{html_file}"
  exit 1
end

inject_legend(html_file)
