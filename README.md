# ExFactor

ExFactor is a refactoring helper. Given a module, function name, and arity, it will locate all uses of
that function, change the callers to a new module and/or function name, and move the function from the original location
to a new file/module. At this time, ExFactor cannot change the function arity.

## BETA Warning

ExFactor is still in active development and the API can and may change frequently!

Use at your peril, _for now._

### Example
```elixir
 mix ex_factor --module TestModule.Here --function my_func --arity 1 --target NewModule.There
```

## Roadmap TODONE
  - [X] Write a mix task to invoke the Refactorer
  - [X] dry-run option
  - [X] CLI output, list files changed and created.
  - [X] format changes
  - [X] github actions, run test suite
  - [X] Add Mix.Task tests
  - [X] Add CLI tests
  - [X] Support opt-out of format-ing
  - [X] Option to only change the module name throughout the project
  - [X] update code to rely on compilation tracers, instead of XREF
  - [X] With module-only option, ensure we remove changed aliases
  - [] defdelegate

## Roadmap TODO

  - [] find private functions references in refactored fn bodies.
  - [] Add and configure CHANGELOG tracking.
  - [] Add test for one file containing more than one `defmodule`
  - [] Add test for nested defmodules.
  - [] update test file refs by CLI option
  - [] find dead functions
  - [] find module attrs and also move them?
  - [] find types referenced in the moved specs
  - [] git stage all changes?
  - [] How does this work with macro code? Does that even make sense as a case to handle?
  - [] Write tests to ensure we can find modules across umbrella apps.
  - [] Add configuration hooks?
  - [] ElixirLS integration for VSCode?
  - [] Write the module code to rename usages of the refactored function

## Updates

  See [CHANGELOG.md](https://github.com/ckochx/ex_factor/blob/main/CHANGELOG.md)

  Updating the changelog. (Uses `auto-changelog`)
  https://github.com/cookpete/auto-changelog

  `auto-changelog --breaking-pattern "BREAKING CHANGE"`

## Installation

[Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_factor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_factor, "~> 0.3", only: [:dev]}
  ]
end
```

Documentation is published on [HexDocs](https://hexdocs.pm). The docs can
be found at [https://hexdocs.pm/ex_factor](https://hexdocs.pm/ex_factor).

Alternate name:
  REFACTORY, just in case.

## License

  See [LICENSE](https://github.com/ckochx/ex_factor/blob/main/LICENSE)

## Miscellaneous resources

  - https://dorgan.netlify.app/posts/2021/04/the_elixir_ast/
  - https://www.educative.io/courses/metaprogramming-elixir/7DXEpKlj3Rr
  - https://elixirforum.com/t/is-there-a-complete-elixir-ast-reference/38923/3
  - https://www.botsquad.com/2019/04/11/the-ast-explained/
  - https://elixirforum.com/t/getting-each-stage-of-elixirs-compilation-all-the-way-to-the-beam-bytecode/1873/8
  - http://gomoripeti.github.io/beam_by_example/
  - https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)
