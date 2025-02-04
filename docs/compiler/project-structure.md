# Project structure of compiler-core

This file provides an overview of the different modules in the `compiler-core` crate.

<!-- vscode-markdown-toc -->
* [Parsing](#Parsing)
  * [AST](#Ast)
* [Type Checking](#Typechecking)

<!-- vscode-markdown-toc-config
  numbering=false
  autoSave=true
  /vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->

## <a name='Parsing'></a>Parsing

The `parse` module is responsible for parsing a Gleam source file and turning it into an [Abstract Syntax Tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree) (AST). The entrypoint is the `parse_module` function, which takes Gleam source code as a string and outputs the parsed AST, or an error if one was encountered.

The `parse::lexer` module contains the lexer. The lexer turns source code into a stream of tokens. A token is a single syntactical element, such as a keyword, number literal, or operator. A full list of tokens which appear in the Gleam programming language can be found in the `parser::token` module. [[Read more](https://en.wikipedia.org/wiki/Lexical_analysis)]

The parser uses a [recursive descent](https://en.wikipedia.org/wiki/Recursive_descent_parser) parsing algorithm to parse the stream of tokens from the lexer into an AST which can then be type-checked.

All errors which can occur during parsing/lexing can be found in the `parse::error` module.

### <a name='Ast'></a>AST

The AST defines the shape of a parsed Gleam program.

./ast/visit.rs
./ast/untyped.rs
./ast/constant.rs
./ast/typed.rs
./ast.rs

## <a name='Typechecking'></a>Type Checking

./type_/error.rs
./type_/expression.rs
./type_/pattern.rs
./type_/environment.rs
./type_/hydrator.rs
./type_/pretty.rs
./type_/pipe.rs
./type_/printer.rs
./type_/fields.rs
./type_/prelude.rs
./analyse.rs
./analyse/name.rs
./analyse/imports.rs

./error.rs
./package_interface.rs
./build/elixir_libraries.rs
./build/telemetry.rs
./build/native_file_copier.rs
./build/package_compiler.rs
./build/package_loader.rs
./build/module_loader.rs
./build/project_compiler.rs
./ast_folder.rs
./io.rs
./line_numbers.rs
./call_graph.rs

./language_server.rs
./exhaustiveness.rs
./docs/source_links.rs
./codegen.rs
./docs.rs
./fix.rs
./metadata.rs
./paths.rs
./dep_tree.rs
./metadata/module_decoder.rs
./metadata/module_encoder.rs
./hex.rs
./uid.rs
./lib.rs
./erlang/pattern.rs
./javascript/expression.rs
./javascript/pattern.rs
./javascript/import.rs
./javascript/endianness.rs
./javascript/typescript.rs
./format.rs
./exhaustiveness/pattern.rs
./exhaustiveness/printer.rs
./exhaustiveness/missing_patterns.rs
./diagnostic.rs
./strings.rs
./pretty.rs

./version.rs
./erlang.rs
./type_.rs
./config.rs
./build.rs
./requirement.rs
./language_server/compiler.rs
./language_server/engine.rs
./language_server/files.rs
./language_server/edits.rs
./language_server/completer.rs
./language_server/router.rs
./language_server/feedback.rs
./language_server/progress.rs
./language_server/server.rs
./language_server/messages.rs
./language_server/code_action.rs
./language_server/signature_help.rs
./javascript.rs
./manifest.rs
./graph.rs
./io/memory.rs
./warning.rs
./bit_array.rs
./dependency.rs

