const parser = require('./parser');
const fs = require('fs');
const path = require('path');

const xmlPath = path.resolve('C:/dev/Dext/DextRepository/Docs/API/xml/Dext.Core.SmartTypes.xml');
console.log(`Parsing ${xmlPath}...`);

const unit = parser.parseXmlFile(xmlPath);

console.log('Uses Clause:', unit.uses.length > 0 ? unit.uses.join(', ') : 'None');

// Verify correct parsing of System.Generics.Collections
if (unit.uses.includes('System.Generics.Collections')) {
    console.log('SUCCESS: Found System.Generics.Collections');
} else {
    console.log('FAILURE: Missing System.Generics.Collections');
}
