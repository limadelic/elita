module Styles
  RULES = <<~CSS.freeze
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
    .summary-count { font-size: 32px; font-weight: 700; }
    .content { padding: 30px; }
    .controls { margin-bottom: 20px; display: flex; gap: 10px; }
    .controls button { padding: 8px 16px; font-size: 13px; font-weight: 600;
      border: 1px solid #ddd; background: white; border-radius: 4px; cursor: pointer;
      color: #333; transition: background 0.2s; }
    .controls button:hover { background: #f0f0f0; }
    .groups { display: flex; flex-direction: column; gap: 10px; }
    details { border: 1px solid #eee; border-radius: 4px; background: white; }
    details[open] { background: white; }
    summary { padding: 12px; cursor: pointer; display: grid; grid-template-columns: 1fr 100px 200px;
      gap: 12px; align-items: center; font-weight: 600; color: #333; user-select: none; }
    summary::-webkit-details-marker { margin-right: 8px; }
    summary::marker { content: '▶ '; }
    details[open] summary::marker { content: '▼ '; }
    summary:hover { background: #f9f9f9; }
    .group-folder { font-weight: 600; }
    .group-info { display: grid; grid-template-columns: 1fr 100px 200px; gap: 12px;
      align-items: center; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; padding: 12px; font-weight: 600; font-size: 12px;
      text-transform: uppercase; color: #666; border-bottom: 1px solid #eee; background: transparent; }
    td { padding: 12px; border-bottom: 1px solid #eee; }
    tr:hover { background: #f9f9f9; }
    .modules-table { margin: 0; border-top: 1px solid #eee; }
    .modules-table tbody tr:first-child td { border-top: none; }
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
    @media (prefers-color-scheme: dark) {
      body { background: #1d1d26; color: #c9c9d1; }
      .container { background: #282a36; box-shadow: 0 1px 3px rgba(0,0,0,0.3); }
      .header { background: linear-gradient(135deg, #3a3d4d 0%, #2c2e3a 100%);
        border-bottom: 1px solid #3a3d4d; }
      h1 { color: #c9c9d1; }
      .summary-label { color: #8f8fa3; }
      .summary-count { color: #c9c9d1; }
      .content { background: #282a36; }
      .controls button { background: #3a3d4d; border-color: #4a4d5d; color: #c9c9d1; }
      .controls button:hover { background: #4a4d5d; }
      details { background: #282a36; border-color: #3a3d4d; }
      summary { color: #c9c9d1; }
      summary:hover { background: #323543; }
      table { background: #282a36; }
      th { color: #8f8fa3; background: transparent; border-bottom: 1px solid #3a3d4d; }
      td { border-bottom: 1px solid #3a3d4d; }
      tr:hover { background: #323543; }
      .group-folder { color: #c9c9d1; }
      .module-name { color: #6cb6ff; }
      .bar-container { background: #3a3d4d; }
      .footer { background: #1d1d26; border-top: 1px solid #3a3d4d; color: #8f8fa3; }
    }
  CSS
end
