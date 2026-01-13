const fs = require('fs');
const { XMLParser } = require('fast-xml-parser');

const options = {
    ignoreAttributes: false,
    attributeNamePrefix: ""
};

const parser = new XMLParser(options);

function parseXmlFile(filePath) {
    const xmlData = fs.readFileSync(filePath, 'utf8');
    const jsonObj = parser.parse(xmlData);
    return normalizeUnit(jsonObj.UNIT);
}

function extractComments(node) {
    if (!node || !node.SLASHESCOMMENT) return null;

    let comments = [];
    if (Array.isArray(node.SLASHESCOMMENT)) {
        comments = node.SLASHESCOMMENT.map(c => c.value);
    } else {
        comments = [node.SLASHESCOMMENT.value];
    }

    // Clean comments: remove "/ " prefix and <summary> tags
    return comments
        .map(c => c.replace(/^\/\s*/, '')) // Remove leading "/ "
        .map(c => c.replace(/<\/?summary>/g, '')) // Remove <summary> tags
        .map(c => c.trim())
        .filter(c => c.length > 0)
        .join(' ');
}

function normalizeUnit(unit) {
    if (!unit) return null;

    const data = {
        name: unit.name,
        uses: [],
        classes: [],
        interfaces: [],
        records: [],
        types: []
    };

    if (unit.INTERFACE && unit.INTERFACE.USES && unit.INTERFACE.USES.UNIT) {
        processSection(unit.INTERFACE.USES.UNIT, (u) => {
            data.uses.push(u.name);
        });
    }

    if (unit.INTERFACE && unit.INTERFACE.TYPESECTION) {
        processSection(unit.INTERFACE.TYPESECTION.TYPEDECL, (decl) => {
            const typeNode = decl.TYPE;
            if (!typeNode) return;

            const kind = typeNode.type;
            const name = decl.name;
            const description = extractComments(decl);

            if (kind === 'class') {
                data.classes.push(parseComplexType(name, typeNode, description));
            } else if (kind === 'interface') {
                data.interfaces.push(parseComplexType(name, typeNode, description));
            } else if (kind === 'record') {
                data.records.push(parseComplexType(name, typeNode, description));
            } else {
                data.types.push({ name, kind, description });
            }
        });
    }

    return data;
}

function processSection(nodes, callback) {
    if (!nodes) return;
    if (Array.isArray(nodes)) {
        nodes.forEach(callback);
    } else {
        callback(nodes);
    }
}

function parseComplexType(name, node, description) {
    const result = {
        name: name,
        description: description,
        ancestor: node.ancestor,
        guid: node.GUID ? node.GUID.LITERAL.value : null,
        methods: [],
        properties: [],
        fields: []
    };

    // Parse members directly in the type node (e.g. for interfaces)
    extractMembers(node, result);

    // Parse visibility blocks (for classes/records)
    const visibilities = ['PUBLIC', 'PUBLISHED', 'PROTECTED', 'PRIVATE'];
    visibilities.forEach(vis => {
        if (node[vis]) {
            extractMembers(node[vis], result, vis);
        }
    });

    return result;
}

function extractMembers(container, target, visibility = '') {
    // Methods
    processSection(container.METHOD, (m) => {
        target.methods.push({
            name: m.name,
            kind: m.kind,
            visibility: visibility,
            description: extractComments(m),
            parameters: parseParameters(m.PARAMETERS),
            returnType: m.RETURNTYPE ? (m.RETURNTYPE.TYPE ? m.RETURNTYPE.TYPE.name : null) : null
        });
    });

    // Properties
    processSection(container.PROPERTY, (p) => {
        target.properties.push({
            name: p.name,
            type: p.TYPE ? p.TYPE.name : 'Unknown',
            visibility: visibility,
            description: extractComments(p)
        });
    });
}

function parseParameters(paramsNode) {
    const results = [];
    if (paramsNode && paramsNode.PARAMETER) {
        processSection(paramsNode.PARAMETER, (p) => {
            results.push({
                name: p.NAME ? p.NAME.value : p.name,
                type: p.TYPE ? p.TYPE.name : (p.param_type || 'Unknown'),
                kind: p.kind || 'val'
            });
        });
    }
    return results;
}

module.exports = {
    parseXmlFile
};
