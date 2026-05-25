# New target system

This is a prototype implementation for a new target system, which both replaces
`@target` and fixes some other issues that have come up with the current system.

Since we didn't come to a consensus on how exactly this should work, I've just
put together an implementation based on my interpretation and opinions of
[the discussion](https://github.com/gleam-lang/gleam/discussions/5192), in the
hope that a working, tangible prototype will make it easier to reason about and
discuss. This document details the changes made, so it's easier to understand the
new behaviour.

**Nothing in this prototype is set in stone**. The syntax, the behaviour,
everything is open to change. The changes are based mostly on what people have
suggested, but since there was some disagreement I have chosen which options I
think are best, with the hope that through testing and discussion we can come to
and agreement on what the best way forward is.

## Changes

- **Function can now have different pure-gleam implementations per target**. The
  same syntax is used for functions that support a single target, and ones that
  have several target-specific implementations. A fallback implementation can also
  be provided that runs if the target does not match any other implementation
  (similar to Gleam fallbacks for externals). The syntax is the following:

  ```gleam
  pub fn greet() {
    @on(javascript) {
      io.println("Hello from JavaScript!")
    }

    @on(erlang) {
      io.println("Hello from Erlang!")
    }

    @on(gleam) {
      io.println("Hello from a new target?")
    }
  }
  ```

- **Packages are no longer required to fully support either target**. Any package
  is now allowed to have some public functions that are Erlang-only and some that
  are JavaScript-only. The only limitation now is that if you want to use `gleam run`,
  your selected `main` function must support the target you want to run on.

  ```gleam
  //// This modules is now valid.

  pub fn promise_api() -> Promise(a) {
    @on(javascript) {
      // This does some JavaScript-specific stuff with promises
    }
  }

  pub fn otp_api() -> Subject(a) {
    @on(erlang) {
      // This does some Erlang-specific stuff with OTP
    }
  }
  ```

- **Type-checking is now (mostly) independent of target**. With the exception of
  some of the warnings like surpassing the safe integer limit on JavaScript, and
  purity checking (discussed below), all implementations of a function are always
  type-checked, even if that implementation does not match the current compilation
  target (of course `@target` still breaks this, as it has not been touched).

  ```gleam
  @target(javascript)
  pub fn wibble() {
    // No error since this definition is ignored
    1 + 1.0
  }

  pub fn wobble() {
    @on(javascript) {
      // Still errors, even though we are compiling to Erlang
      1 + 1.0
    }
  }
  ```

## Open questions

A few parts of the implementation I wasn't so sure about. All of it is subject to
change, but these bits I'm specifically iffy on.

- **The syntax**. The currently implemented one works fine, but I'm not attached
  to it.

- **Target support for pure-gleam fallback**. I was a little unsure on exactly
  how this should work. The core question focuses on whether the following code
  should be valid:
  ```gleam
  pub fn main() {
    @on(gleam) {
      some_function_that_only_supports_javascript()
    }

    @on(javascript) {
      // ...
    }

    @on(erlang) {
      // ...
    }
  }
  ```

  Here, the fallback Gleam implementation can only run on the JavaScript target.
  My initial thought was that this didn't make sense, and that Gleam fallbacks
  should need to be implemented in pure Gleam. But then this code is invalid:

  ```gleam
  pub fn main() {
    @on(gleam) {
      some_function_that_uses_externals_on_both_erlang_and_js()
    }

    // ...
  }
  ```

  Since, while the called function is defined on both targets, it is not pure
  Gleam. We could instead say that a Gleam fallback is valid if it supports all
  targets, but that mostly defeats the point because the main reason to use a
  Gleam fallback is in case of a future added target, and adding a new target
  would cause existing code to fail to compile because a function defined using
  externals would not support the new target until changed.

  This implementation goes with the first option, which is consistent with how
  we currently treat Gleam fallbacks for externals, but I'm not sure if there's
  a better solution here.

- **Purity checking**. The new target system exacerbates the problem with purity
  that has been observed with `lustre_dev_tools`, where Erlang-only external
  functions are considered pure when compiling to the JavaScript target. Since
  partial support for each target is now allowed within a package, it's much
  easier to run into this warning with the new system. For now I've put in a
  one-line fix which treats any function without a body as impure, even if it
  doesn't have an implementation for the current target. This fixes the crux of
  the issue, but there's still some complexity where an external is defined
  with a side-effect-less Gleam fallback implementation, or when different
  per-target implementations are defined.

  There's also a question of whether we even want to warn differently per target.
  Consider this function for example:

  ```gleam
  pub fn assert_erlang() -> Nil {
    @on(erlang) {
      Nil
    }

    @on(javascript) {
      panic as "Not running on Erlang"
    }
  }
  ```

  Now this is not an idiomatic Gleam function, but the question is: Do we want to
  warn if this is called on the Erlang target? It doesn't have side-effects on
  Erlang, but it does on JavaScript.

## Still left to do

Since this implementation is just a prototype and likely to change somewhat before
being released, I haven't bothered with some of the features which we will want
before merging this into the compiler.

- **Proper errors and warnings**. I've put in some error messages for stuff that
  isn't allowed, like calling an Erlang-only function from a JavaScript-specific
  implementation, but there are several cases where we'll want a warning/error
  that I haven't bothered with yet, as they aren't necessary for the core
  functionality of the feature (e.g. an error for multiple implementations for
  the same target).

- **Detailed error message for calling an unsupported function**. As
  [Louis mentioned](https://github.com/gleam-lang/gleam/discussions/5192#discussioncomment-15745640)
  in the discussion, target support can be difficult to determine by simply
  looking at a function's body. If a pure-Gleam function calls another pure-Gleam
  function, which calls another, ..., and eventually calls an Erlang-only function,
  the first function is Erlang-only, but that's not immediately obvious. Making
  the error message for cases like this clearer is something that would be nice
  for the release of this feature, but not necessary for trying it out.

- **Tests and code cleanup**. Since the code is likely to change somewhat before
  being merged, I haven't spent too much time making it tidy and well commented,
  and haven't added tests yet for behaviour that may change. Looking at the source
  code may not help that much until I've cleaned it up a bit.

- **Dead-code elimination**. Any value that is imported, or pure-Gleam function
  or constant that is only used by implementations for the target other the one
  being compiled to should not be generated, just as we don't generate completely
  unused values currently. Since this doesn't materially effect the running of
  the program, it isn't needed for the initial prototype.

- **Documentation**. We've discussed this before, but with the new target system
  it seems like it may be a good idea to expose the target support for each
  function in the generated documentation.
  [Hayleigh also proposed](https://github.com/gleam-lang/gleam/discussions/5192#discussioncomment-15757026)
  that we support adding doc comments to individual implementations, which we
  should consider whether we want to allow and how that would work if so.
