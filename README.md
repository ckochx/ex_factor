# ExFactor

ExFactor is a refactoring helper. Given a module, function name, and arity, it will locate all uses of
that function, change the callers to a new module and/or function name, and move the function from the original location
to a new file/module. At this time, ExFactor cannot change the function arity.

## BETA Warning

ExFactor is still in active development and the API can and will change frequently!

Use at your peril, _for now._

### Example
```elixir
 mix ex_factor.refactor --module TestModule.Here --function my_func --arity 1 --target NewModule.Test
```

## Roadmap TODO

  - [] Update .exs files too?
  - [] Write tests to ensure we can find modules within and across umbrella apps.
  - [] Add configuration hooks?
  - [] find dead functions
  - [] find module attrs and also move them?
  - [] find types referenced in the moved specs
  - [] find private functions references in refactored fn bodies.
  - [] update test file refs by CLI option
  - [] format changes
  - [] ElixirLS integration for VSCode?
  - [] Write the module code to rename usages of the refactored function
  - [] guthub actions, run test suite

## Roadmap TODONE
  - [X] Write a mix task to invoke the Refactorer
  - [X] dry-run option
  - [X] CLI output, list files changed and created.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_factor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_factor, "~> 0.1.0", only: [:dev]}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_factor](https://hexdocs.pm/ex_factor).

REFACTORY, just in case.