# DextASTParser

Console application that parses Delphi source files using [DelphiAST](https://github.com/RomanYankovsky/DelphiAST) (Stefan Glienke's fork) and generates XML output.

## Purpose

Generate Abstract Syntax Tree (AST) XML files for all Dext Framework units. This is the first step toward creating automated API documentation that supports modern Delphi generics.

## Requirements

- Delphi 12 (or compatible version)
- DelphiAST fork at `C:\dev\Dext\Libs\DelphiAST-sglienke`

## Usage

1. Open `DextASTParser.dproj` in Delphi
2. Build the project (`Ctrl+F9`)
3. Run from the command line:

```cmd
DextASTParser.exe <input_dir> <output_dir> [-i include_path1;include_path2]
```

### Example

```cmd
DextASTParser.exe C:\dev\Dext\Sources C:\dev\Dext\Docs\API\xml -i C:\dev\Dext\Sources\Core
```

## Output

- XML files are generated in the `<output_dir>` preserving the input directory structure.
- Each `.pas` file produces a corresponding `.xml` file with the AST.

## Example Output

```xml
<?xml version="1.0"?>
<UNIT line="1" col="1" name="Dext.Core.SmartTypes">
  <INTERFACE begin_line="3" begin_col="1" end_line="100" end_col="1">
    <USES>...</USES>
    <TYPE>
      <NAME value="Prop"/>
      <TYPEPARAMS>...</TYPEPARAMS>
    </TYPE>
  </INTERFACE>
</UNIT>
```

## Why This Tool?

Standard Delphi documentation tools (PasDoc, GenDocCLI) fail with StackOverflow errors when parsing Dext's complex generics. DelphiAST (Stefan's fork) handles them correctly.

## Next Steps

1. Parse all units and verify success
2. Create HTML generator from XML output
3. Integrate with build pipeline
