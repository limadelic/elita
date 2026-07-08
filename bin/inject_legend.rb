#!/usr/bin/env ruby

require 'rexml/document'

# Legend definition
LEGEND_CSS = <<~CSS
  <style>
    .legend-container {
      position: fixed;
      bottom: 1.5em;
      right: 1.5em;
      background: var(--cucumber-panel-background-color, oklch(96.8% 0.007 247.896deg));
      border: 1px solid var(--cucumber-panel-accent-color, oklch(92.9% 0.013 255.508deg));
      border-radius: 6px;
      padding: 0.75em;
      color: var(--cucumber-panel-text-color, oklch(27.9% 0.041 260.031deg));
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      font-size: 0.85em;
      z-index: 10000;
      width: auto;
      max-width: 200px;
    }
    .legend-items {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.75em 1em;
    }
    .legend-item {
      display: flex;
      gap: 0.4em;
      align-items: center;
      white-space: nowrap;
    }
    .legend-label {
      font-size: 1.1em;
      flex-shrink: 0;
    }
    .legend-meaning {
      font-size: 0.8em;
      opacity: 0.8;
      line-height: 1.2;
    }
  </style>
CSS

LEGEND_HTML = <<~HTML
  <div class="legend-container">
    <div class="legend-items">
      <div class="legend-item">
        <span class="legend-label">🤔</span>
        <span class="legend-meaning">Ask</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">📢</span>
        <span class="legend-meaning">Tell</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">✨</span>
        <span class="legend-meaning">Reply</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">👀</span>
        <span class="legend-meaning">Get</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">✏️</span>
        <span class="legend-meaning">Set</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">🚀</span>
        <span class="legend-meaning">Spawn</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">🧪</span>
        <span class="legend-meaning">Spec</span>
      </div>
      <div class="legend-item">
        <span class="legend-label">🎭</span>
        <span class="legend-meaning">Become</span>
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
