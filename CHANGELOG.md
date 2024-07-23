# Changelog

## Unreleased

### Build tool

### Compiler

- The compiler now gives a hint to import a module when accessing modules that
  aren't imported. It only suggests a module if it exports a type/value with
  the same name as what the user was trying to access:

  ```gleam
  pub fn main() {
    io.println("Hello, world!")
  }
  ```

  Produces the following error:

  ```
  error: Unknown module
    ┌─ /src/file.gleam:2:3
    │
  2 │   io.println("Hello, world!")
    │   ^^

  No module has been found with the name `io`.
  Hint: Did you mean to import `gleam/io`?
  ```

  This code, however, produces no hint:

  ```gleam
  pub fn main() {
    io.non_existent()
  }
  ```

  ([Surya Rose](https://github.com/gearsdatapacks))

### Formatter

### Language Server

- The language server can now suggest a code action to import modules
  for existing code which references unimported modules:

  ```gleam
  pub fn main() {
    io.println("Hello, world!")
  }
  ```

  Becomes:

  ```gleam
  import gleam/io

  pub fn main() {
    io.println("Hello, world!")
  }
  ```

  ([Surya Rose](https://github.com/gearsdatapacks))

### Bug Fixes

- Fixed a bug which caused the language server and compiler to crash when
  two constructors of the same name were created.
  ([Surya Rose](https://github.com/GearsDatapacks))

- Fixed a bug where jumping to the definition of an unqualified function would
  produce the correct location, but remain in the same file.
  ([Surya Rose](https://github.com/gearsdatapacks))

## v1.4.1 - 2024-08-04

### Bug Fixes

- Fix a bug that caused record accessors for private types to not be completed
  by the LSP, even when in the same module.
  ([Ameen Radwan](https://github.com/Acepie))
