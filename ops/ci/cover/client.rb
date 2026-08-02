module Client
  def self.app_script
    <<~SCRIPT
      const app = {
        tree: null,
        currentPath: [],

        init() {
          this.tree = JSON.parse(document.getElementById('tree-data').textContent);
          window.addEventListener('hashchange', () => this.navigate());
          this.setupDelegatedListeners();
          this.navigate();
        },

        navigate() {
          const hash = window.location.hash.slice(1);
          this.currentPath = hash ? hash.split('/').filter(Boolean) : [];
          this.render();
        },

        root() {
          window.location.hash = '';
        },

        navigateTo(path) {
          window.location.hash = path.join('/');
        },

        getCurrentNode() {
          let node = this.tree;
          for (const segment of this.currentPath) {
            if (node.children && node.children[segment]) {
              node = node.children[segment];
            } else {
              return null;
            }
          }
          return node;
        },

        setupDelegatedListeners() {
          const browser = document.getElementById('browser');
          if (!browser) return;

          browser.addEventListener('click', (e) => {
            const folderRow = e.target.closest('[data-path]');
            if (folderRow) {
              const path = folderRow.dataset.path.split('/');
              this.navigateTo(path);
              return;
            }

            const moduleRow = e.target.closest('[data-module]');
            if (moduleRow) {
              const moduleName = moduleRow.dataset.module;
              window.location = 'Elixir.' + moduleName + '.html';
              return;
            }
          });
        },

        render() {
          const node = this.getCurrentNode();
          if (!node) {
            document.getElementById('browser').innerHTML = '<p>Not found</p>';
            document.getElementById('breadcrumb').innerHTML = '';
            return;
          }

          this.renderBreadcrumb();
          this.renderContents(node);
        },

        renderBreadcrumb() {
          const parts = ['root', ...this.currentPath];
          let html = '<span class="breadcrumb-item">Coverage</span>';
          for (let i = 1; i < parts.length; i++) {
            const path = parts.slice(1, i + 1);
            html += ` / <span class="breadcrumb-item" data-breadcrumb="${path.join('/')}">${parts[i]}</span>`;
          }
          document.getElementById('breadcrumb').innerHTML = html;

          document.querySelectorAll('[data-breadcrumb]').forEach(el => {
            el.style.cursor = 'pointer';
            el.addEventListener('click', () => {
              const path = el.dataset.breadcrumb.split('/');
              this.navigateTo(path);
            });
          });
        },

        renderContents(node) {
          const children = Object.entries(node.children || {}).map(([key, child]) => ({
            type: 'folder',
            name: key,
            pct: child.pct,
            displayName: child.name,
            path: [...this.currentPath, key]
          }));

          const modules = (node.modules || []).map(m => ({
            type: 'module',
            name: m.name,
            pct: m.pct,
            displayName: m.name
          }));

          const rows = children.concat(modules);
          let html = '<table class="browser-table"><tbody>';

          rows.forEach(row => {
            const color = colorFor(row.pct);
            const pctFmt = row.pct.toFixed(2);
            const barText = row.pct === 0 ? '' : pctFmt;

            if (row.type === 'folder') {
              const pathStr = row.path.join('/');
              html += `<tr class="browser-row folder" data-path="${pathStr}" style="cursor: pointer;">
                <td class="row-icon">📁</td>
                <td class="row-name">${row.displayName}</td>
                <td class="pct-cell" style="background-color: #${color};">${pctFmt}%</td>
                <td class="bar-cell">
                  <div class="bar-container">
                    <div class="bar-fill" style="width: ${row.pct}%; background-color: #${color};">
                      ${barText}
                    </div>
                  </div>
                </td>
              </tr>`;
            } else {
              html += `<tr class="browser-row module" data-module="${row.name}" style="cursor: pointer;">
                <td class="row-icon">📄</td>
                <td class="row-name">${row.displayName}</td>
                <td class="pct-cell" style="background-color: #${color};">${pctFmt}%</td>
                <td class="bar-cell">
                  <div class="bar-container">
                    <div class="bar-fill" style="width: ${row.pct}%; background-color: #${color};">
                      ${barText}
                    </div>
                  </div>
                </td>
              </tr>`;
            }
          });

          html += '</tbody></table>';
          document.getElementById('browser').innerHTML = html;
        }
      };

      function colorFor(pct) {
        if (pct >= 80.0) return '23D96C';
        if (pct >= 50.0) return 'dfb317';
        return 'e05d44';
      }

      app.init();
    SCRIPT
  end
end
