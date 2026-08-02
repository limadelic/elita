module Styles
  RULES = <<~CSS.freeze
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font: 14px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #f8f9fa; color: #333; padding: 20px; }
    .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 6px;
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
    .breadcrumb { margin-bottom: 16px; font-size: 13px; }
    .breadcrumb-item { cursor: pointer; color: #0066cc; }
    .breadcrumb-item:hover { text-decoration: underline; }
    .controls { margin-bottom: 20px; display: flex; gap: 10px; }
    .controls button { padding: 8px 16px; font-size: 13px; font-weight: 600;
      border: 1px solid #ddd; background: white; border-radius: 4px; cursor: pointer;
      color: #333; transition: background 0.2s; }
    .controls button:hover { background: #f0f0f0; }
    .browser { }
    .browser-table { width: 100%; border-collapse: collapse; }
    .browser-row { cursor: pointer; }
    .browser-row:hover { background: #f6f8fa; }
    .row-icon { padding: 12px 16px; width: 40px; text-align: center; }
    .row-name { padding: 12px 0; font-weight: 500; color: #0066cc; flex: 1; }
    .browser-row.module .row-name { color: #24292e; }
    .pct-cell { width: 100px; text-align: center; font-weight: 600; color: white; font-size: 13px;
      padding: 12px 8px; border-radius: 4px; }
    .bar-cell { width: 200px; padding: 12px 8px; }
    .bar-container { width: 100%; height: 20px; background: #e8e8e8; border-radius: 2px;
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
      .breadcrumb { color: #8f8fa3; }
      .breadcrumb-item { color: #6cb6ff; }
      .breadcrumb-item:hover { color: #79c0ff; }
      .controls button { background: #3a3d4d; border-color: #4a4d5d; color: #c9c9d1; }
      .controls button:hover { background: #4a4d5d; }
      .browser-row:hover { background: #323543; }
      .row-name { color: #6cb6ff; }
      .browser-row.module .row-name { color: #c9c9d1; }
      .bar-container { background: #3a3d4d; }
      .footer { background: #1d1d26; border-top: 1px solid #3a3d4d; color: #8f8fa3; }
    }
  CSS
end
