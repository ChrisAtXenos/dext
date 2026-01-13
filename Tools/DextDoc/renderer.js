const fs = require('fs');
const path = require('path');

const CSS = `
:root {
    /* Default Dark Theme */
    --bg-color: #0f172a;
    --panel-bg: rgba(30, 41, 59, 0.7);
    --text-primary: #f8fafc;
    --text-secondary: #94a3b8;
    --accent-color: #38bdf8;
    --border-color: rgba(255, 255, 255, 0.1);
    --hover-bg: rgba(56, 189, 248, 0.1);
    --glass-blur: 12px;
    --code-bg: rgba(0,0,0,0.2);
    --search-bg: rgba(0, 0, 0, 0.2);
}

[data-theme="light"] {
    /* Light Theme (Flutter-inspired) */
    --bg-color: #f8fafc;
    --panel-bg: rgba(255, 255, 255, 0.8);
    --text-primary: #1e293b;
    --text-secondary: #64748b;
    --accent-color: #0284c7;
    --border-color: rgba(226, 232, 240, 0.8);
    --hover-bg: rgba(2, 132, 199, 0.1);
    --glass-blur: 12px;
    --code-bg: rgba(241, 245, 249, 1);
    --search-bg: rgba(255, 255, 255, 0.5);
}

* { box-sizing: border-box; transition: background-color 0.3s, color 0.3s; }

body {
    margin: 0;
    font-family: 'Inter', -apple-system, sans-serif;
    background-color: var(--bg-color);
    color: var(--text-primary);
    display: flex;
    height: 100vh;
    overflow: hidden;
}

/* Sidebar */
.sidebar {
    width: 300px;
    background: var(--panel-bg);
    backdrop-filter: blur(var(--glass-blur));
    border-right: 1px solid var(--border-color);
    display: flex;
    flex-direction: column;
}

.sidebar-header {
    padding: 24px;
    border-bottom: 1px solid var(--border-color);
}

.sidebar-header h1 {
    font-size: 1.25rem;
    margin: 0;
    color: var(--accent-color);
}

.search-container {
    padding: 12px 24px;
    border-bottom: 1px solid var(--border-color);
}

#unitSearch {
    width: 100%;
    width: 100%;
    background: var(--search-bg);
    border: 1px solid var(--border-color);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    padding: 8px 12px;
    color: var(--text-primary);
    font-size: 0.85rem;
    outline: none;
    transition: border-color 0.2s;
}

#unitSearch:focus {
    border-color: var(--accent-color);
}

.unit-list {
    flex: 1;
    overflow-y: auto;
    padding: 12px;
}

.unit-item {
    padding: 8px 12px;
    margin-bottom: 4px;
    border-radius: 6px;
    cursor: pointer;
    font-size: 0.9rem;
    color: var(--text-secondary);
    text-decoration: none;
    display: block;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.unit-item:hover {
    background: var(--hover-bg);
    color: var(--text-primary);
}

/* Main Content */
.content {
    flex: 1;
    overflow-y: auto;
    padding: 40px;
}

h2 { color: var(--accent-color); border-bottom: 1px solid var(--border-color); padding-bottom: 10px; }
h3 { margin-top: 40px; color: var(--text-primary); }
h4 { color: var(--text-primary); margin-bottom: 15px; }

.section {
    background: var(--panel-bg);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 24px;
    margin-bottom: 24px;
    backdrop-filter: blur(var(--glass-blur));
}

.api-item {
    border-left: 2px solid var(--accent-color);
    padding-left: 15px;
    margin: 15px 0;
}

.api-signature {
    font-family: 'Fira Code', monospace;
    color: var(--accent-color);
    color: var(--accent-color);
    background: var(--code-bg);
    padding: 8px 12px;
    padding: 8px 12px;
    border-radius: 6px;
    font-size: 0.9rem;
}

.visibility {
    font-size: 0.75rem;
    text-transform: uppercase;
    color: var(--text-secondary);
    margin-bottom: 4px;
}


.theme-toggle {
    position: fixed;
    top: 24px;
    right: 24px;
    background: var(--panel-bg);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 8px;
    border-radius: 50%;
    cursor: pointer;
    backdrop-filter: blur(var(--glass-blur));
    z-index: 1000;
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.2rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.theme-toggle:hover {
    background: var(--hover-bg);
    color: var(--accent-color);
}

::-webkit-scrollbar { width: 8px; }
::-webkit-scrollbar-thumb { background: var(--border-color); border-radius: 10px; }
`;

const SEARCH_JS = `
document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('unitSearch');
    const unitItems = document.querySelectorAll('.unit-item');

    searchInput.addEventListener('input', (e) => {
        const term = e.target.value.toLowerCase();
        unitItems.forEach(item => {
            const text = item.textContent.toLowerCase();
            if (text.includes(term)) {
                item.style.display = 'block';
            } else {
                item.style.display = 'none';
            }
        });
    });
});
`;

function renderPortal(units, outputDir) {
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });
    fs.writeFileSync(path.join(outputDir, 'style.css'), CSS);
    fs.writeFileSync(path.join(outputDir, 'search.js'), SEARCH_JS);

    const unitListHtml = units.sort((a, b) => a.name.localeCompare(b.name)).map(u =>
        `<a href="${u.name}.html" class="unit-item">${u.name}</a>`
    ).join('\n');

    const sidebarHtml = `
    <div class="sidebar">
        <div class="sidebar-header">
            <a href="index.html" style="text-decoration: none"><h1>Dext Framework</h1></a>
            <p style="font-size: 0.8rem; color: var(--text-secondary)">API Reference</p>
        </div>
        <div class="search-container">
            <input type="text" id="unitSearch" placeholder="Search units...">
        </div>
        <div class="unit-list">
            ${unitListHtml}
        </div>
    </div>
    <script src="search.js"></script>
    `;

    units.forEach(unit => {
        const html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>${unit.name} - Dext Docs</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    ${sidebarHtml}
    <div class="content">
        <button id="themeToggle" class="theme-toggle" title="Toggle Theme">🌓</button>
        <h2>Unit ${unit.name}</h2>
        
        ${renderDependencyGraph(unit)}
        
        ${renderClassDiagram(unit)}
        
        ${renderTypes('Classes', unit.classes)}
        ${renderTypes('Interfaces', unit.interfaces)}
        ${renderTypes('Records', unit.records)}
        ${unit.types.length > 0 ? `<h3>Other Types</h3><div class="section">${unit.types.map(t => `<p><b>${t.name}</b>: ${t.kind}</p>`).join('')}</div>` : ''}
    </div>
    
    <script type="module">
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
        mermaid.initialize({ startOnLoad: true, theme: 'base' });
        
        // Theme Toggle Logic
        const toggleBtn = document.getElementById('themeToggle');
        const body = document.body;
        
        // Load saved theme
        const savedTheme = localStorage.getItem('dext-doc-theme') || 'dark';
        body.setAttribute('data-theme', savedTheme);
        mermaid.initialize({ theme: savedTheme === 'dark' ? 'dark' : 'default' });

        toggleBtn.addEventListener('click', () => {
            const currentTheme = body.getAttribute('data-theme');
            const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
            
            body.setAttribute('data-theme', newTheme);
            localStorage.setItem('dext-doc-theme', newTheme);
            
            // Reload mermaid to apply theme change (optional, might need reload page for perfect switch)
             location.reload(); 
        });
    </script>
</body>
</html>
`;
        fs.writeFileSync(path.join(outputDir, `${unit.name}.html`), html);
    });

    const indexHtml = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dext API Reference</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    ${sidebarHtml}
    <div class="content">
        <h2>Welcome to Dext API Reference</h2>
        <div class="section">
            <p>Select a unit from the sidebar to explore the API of the Dext Framework.</p>
            <p>Generated via continuous integration for version 1.0-beta.</p>
            <hr style="border: 0; border-top: 1px solid var(--border-color); margin: 20px 0;">
            <p><b>Total Units:</b> ${units.length}</p>
        </div>
    </div>
</body>
</html>
`;
    fs.writeFileSync(path.join(outputDir, 'index.html'), indexHtml);
}

function renderTypes(title, items) {
    if (!items || items.length === 0) return '';
    return `
        <h3>${title}</h3>
        ${items.map(item => `
            <div class="section">
                <h4>${item.name} ${item.ancestor ? `<span style="color: var(--text-secondary); font-weight: normal;"> : ${item.ancestor}</span>` : ''}</h4>
                ${item.guid ? `<p style="font-size: 0.8rem; color: var(--text-secondary); font-family: monospace">GUID: ${item.guid}</p>` : ''}
                ${item.description ? `<p style="color: var(--text-secondary); margin-bottom: 20px;">${item.description}</p>` : ''}
                
                ${item.methods.length > 0 ? `
                    <div style="margin-top: 20px">
                        <b>Methods</b>
                        ${item.methods.map(m => `
                            <div class="api-item">
                                <div class="visibility">${m.visibility}</div>
                                <div class="api-signature">${m.kind} ${m.name}(${m.parameters.map(p => `${p.name}: ${p.type}`).join(', ')}): ${m.returnType || 'void'}</div>
                                ${m.description ? `<div style="margin-top: 8px; color: var(--text-secondary); font-size: 0.9rem;">${m.description}</div>` : ''}
                            </div>
                        `).join('')}
                    </div>
                ` : ''}

                ${item.properties.length > 0 ? `
                    <div style="margin-top: 20px">
                        <b>Properties</b>
                        ${item.properties.map(p => `
                            <div class="api-item">
                                <div class="visibility">${p.visibility}</div>
                                <div class="api-signature">${p.name}: ${p.type}</div>
                                ${p.description ? `<div style="margin-top: 8px; color: var(--text-secondary); font-size: 0.9rem;">${p.description}</div>` : ''}
                            </div>
                        `).join('')}
                    </div>
                ` : ''}
            </div>
        `).join('')}
    `;
}

function renderClassDiagram(unit) {
    // Only generate if we have classes or interfaces
    if (unit.classes.length === 0 && unit.interfaces.length === 0) return '';

    let chart = 'classDiagram\n';

    const cleanId = (n) => n.replace(/[^a-zA-Z0-9_]/g, '_');

    // Add classes and inheritance
    unit.classes.forEach(c => {
        const id = cleanId(c.name);
        chart += `class ${id}["${c.name}"]\n`;
        if (c.ancestor) {
            const ancestorId = cleanId(c.ancestor);
            chart += `${ancestorId}["${c.ancestor}"] <|-- ${id}\n`;
        }
    });

    // Add interfaces and inheritance
    unit.interfaces.forEach(i => {
        const id = cleanId(i.name);
        chart += `class ${id}["${i.name}"]\n`;
        chart += `<<interface>> ${id}\n`;

        if (i.ancestor) {
            const ancestorId = cleanId(i.ancestor);
            chart += `${ancestorId}["${i.ancestor}"] <|-- ${id}\n`;
        }
    });

    return `
        <h3>Class Diagram</h3>
        <div class="section">
            <div class="mermaid">
                ${chart}
            </div>
        </div>
    `;
}

function renderDependencyGraph(unit) {
    if (!unit.uses || unit.uses.length === 0) return '';

    let chart = 'graph TD\n';
    // Clean names for Mermaid (remove dots)
    const cleanId = (n) => n.replace(/[^a-zA-Z0-9_]/g, '_');

    const selfId = cleanId(unit.name);
    chart += `${selfId}[${unit.name}]\n`;
    chart += `style ${selfId} fill:#f9f,stroke:#333,stroke-width:2px,color:#000\n`;

    unit.uses.forEach(u => {
        const depId = cleanId(u);
        chart += `${selfId} --> ${depId}[${u}]\n`;
        chart += `click ${depId} "${u}.html" "Go to ${u}"\n`;
    });

    return `
        <h3>Dependency Graph</h3>
        <div class="section">
            <div class="mermaid">
                ${chart}
            </div>
        </div>
    `;
}

module.exports = { renderPortal };
