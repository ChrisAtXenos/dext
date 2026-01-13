const fs = require('fs');
const path = require('path');

function renderMarkdown(units, outputDir) {
    const mdFile = path.join(outputDir, 'REFERENCE.md');
    let md = `# Dext Framework API Reference\n\n`;
    md += `This document provides a quick reference for all units in the Dext Framework. For the full interactive documentation, visit the [HTML Documentation Portal](html/index.html).\n\n`;

    md += `## Units Overview (${units.length} total)\n\n`;

    // Sort units by name
    const sortedUnits = units.sort((a, b) => a.name.localeCompare(b.name));

    sortedUnits.forEach(unit => {
        md += `### ${unit.name}\n\n`;

        if (unit.classes.length > 0) {
            md += `**Classes:** ` + unit.classes.map(c => `[${c.name}](#${c.name.toLowerCase()})`).join(', ') + `\n\n`;
        }
        if (unit.interfaces.length > 0) {
            md += `**Interfaces:** ` + unit.interfaces.map(i => i.name).join(', ') + `\n\n`;
        }
        if (unit.records.length > 0) {
            md += `**Records:** ` + unit.records.map(r => r.name).join(', ') + `\n\n`;
        }

        md += `---\n\n`;
    });

    md += `\n*Generated automatically via DextDoc and DelphiAST.*\n`;

    fs.writeFileSync(mdFile, md);
}

module.exports = { renderMarkdown };
