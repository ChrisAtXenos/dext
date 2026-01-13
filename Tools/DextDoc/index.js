const fs = require('fs');
const path = require('path');
const { parseXmlFile } = require('./parser');

async function main() {
    const args = process.argv.slice(2);
    if (args.length < 2) {
        console.log('Usage: node index.js <xmlDir> <outputDir>');
        process.exit(1);
    }

    const xmlDir = path.resolve(args[0]);
    const outputDir = path.resolve(args[1]);

    console.log(`Scanning XMLs in ${xmlDir}...`);

    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    const units = [];
    const files = getAllFiles(xmlDir, '.xml');

    for (const file of files) {
        try {
            const unit = parseXmlFile(file);
            if (unit) {
                units.push(unit);
                console.log(`Parsed ${unit.name}`);
            }
        } catch (err) {
            console.error(`Error parsing ${file}: ${err.message}`);
        }
    }



    // Deduplicate units by name
    const uniqueUnits = [];
    const unitNames = new Set();

    for (const unit of units) {
        if (!unitNames.has(unit.name)) {
            unitNames.add(unit.name);
            uniqueUnits.push(unit);
        }
    }

    // Sort units alphabetically
    uniqueUnits.sort((a, b) => a.name.localeCompare(b.name));

    console.log(`Total units parsed: ${units.length}`);
    console.log(`Unique units: ${uniqueUnits.length}`);

    const { renderPortal } = require('./renderer');
    const { renderMarkdown } = require('./markdown-renderer');

    console.log('Rendering HTML portal...');
    renderPortal(uniqueUnits, outputDir);

    console.log('Rendering Markdown reference...');
    renderMarkdown(uniqueUnits, path.resolve(outputDir, '..'));

    console.log(`Success! Docs generated in ${outputDir}`);
}

function getAllFiles(dirPath, ext, arrayOfFiles) {
    const files = fs.readdirSync(dirPath);
    arrayOfFiles = arrayOfFiles || [];

    files.forEach(function (file) {
        if (fs.statSync(dirPath + "/" + file).isDirectory()) {
            arrayOfFiles = getAllFiles(dirPath + "/" + file, ext, arrayOfFiles);
        } else {
            if (file.endsWith(ext)) {
                arrayOfFiles.push(path.join(dirPath, "/", file));
            }
        }
    });

    return arrayOfFiles;
}

main().catch(err => console.error(err));
