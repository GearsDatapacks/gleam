# Changelog

## Unreleased

### Compiler

### Build tool

### Language server

- The language server now allows renaming of functions and constants across modules.
  For example:

  ```gleam
  // wibble.gleam
  pub fn wibble() {
    wibble()
  //^ Trigger rename
  }
  // wobble.gleam
  import wibble

  pub fn main() {
    wibble.wibble()
  }
  ```

  Becomes:

  ```gleam
  // wibble.gleam
  pub fn wobble() {
    wobble()
  }
  // wobble.gleam
  import wibble

  pub fn main() {
    wibble.wobble()
  }
  ```

  ([Surya Rose](https://github.com/GearsDatapacks))

### Formatter

### Bug fixes
