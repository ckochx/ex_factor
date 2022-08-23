defmodule ExFactor.CLITest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    File.mkdir_p("test/tmp")

    on_exit(fn ->
      File.rm_rf("test/tmp")
    end)
  end

  test "missing required options exit != 0" do
    opts = [
      module: "ExFactorSampleModule",
      function: "pub1",
      arity: 1
    ]

    argv = OptionParser.to_argv(opts)

    capture_io(fn ->
      {_, exit_status} = System.cmd("mix", ["ex_factor" | argv])
      refute exit_status == 0
    end)
  end

  test "with dry run" do
    opts = [
      module: "ExFactor.Formatter",
      target: "ExFactor.ExampleModule",
      function: :format,
      arity: 2,
      dryrun: true
    ]

    argv = OptionParser.to_argv(opts)

    {cli_output, exit_status} = System.cmd("mix", ["ex_factor" | argv])
    assert exit_status == 0

    assert cli_output =~ "Message: --dry_run changes to make"
  end

  test "with --no-format" do
    opts = [
      module: "ExFactor.Support.ExampleSeven",
      sourcepath: "test/support/example_seven.ex",
      targetpath: "test/support/example_six.ex",
      target: "ExFactor.Modified.ExampleSix",
      function: :all_funcs,
      arity: 1,
      dryrun: true,
      format: false
    ]

    argv = OptionParser.to_argv(opts)

    {cli_output, exit_status} = System.cmd("mix", ["ex_factor" | argv])
    assert exit_status == 0

    assert cli_output =~ "Message: --dry_run changes to make"
  end

  test "with --moduleonly" do
    opts = [
      module: "ExFactor.Formatter",
      target: "ExFactor.Modified.MyNewFormatter",
      dryrun: true,
      moduleonly: true
    ]

    argv = OptionParser.to_argv(opts)

    {_cli_output, exit_status} = System.cmd("mix", ["ex_factor" | argv])
    assert exit_status == 0
  end
end
