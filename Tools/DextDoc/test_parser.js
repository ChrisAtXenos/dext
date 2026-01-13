const parser = require('./parser');
const fs = require('fs');
const path = require('path');

const xmlPath = path.resolve('C:/dev/Dext/DextRepository/Docs/API/xml/Dext.Core.SmartTypes.xml');
console.log(`Parsing ${xmlPath}...`);

const unit = parser.parseXmlFile(xmlPath);

// Check Interface IPropInfo
const iPropInfo = unit.interfaces.find(i => i.name === 'IPropInfo');
console.log('IPropInfo:', iPropInfo ? 'Found' : 'Not Found');
if (iPropInfo) {
    console.log('Docs:', iPropInfo.description || 'None');
}

// Check BooleanExpression (record)
const boolExpr = unit.records.find(r => r.name === 'BooleanExpression');
console.log('BooleanExpression:', boolExpr ? 'Found' : 'Not Found');
if (boolExpr) {
    console.log('Docs:', boolExpr.description || 'None');
}
