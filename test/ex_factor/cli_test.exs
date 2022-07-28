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

    capture_io fn ->
      {_, exit_status} = System.cmd("mix", ["ex_factor" | argv])
      refute exit_status == 0
    end
  end

  test "with dry run" do
    content = """
    defmodule ExFactorSampleModule do
      @somedoc "This is somedoc"
      # a comment and no aliases
      _docp = "here's an arbitrary module underscore"
      @spec pub1(term()) :: term()
      def pub1(arg1) do
        :pub1_ok
      end
    end
    """

    File.write("test/tmp/source_module.ex", content)
    target_path = "test/tmp/target_module.ex"

    opts = [
      target_path: target_path,
      target: "ExFactor.NewMod",
      module: "ExFactorSampleModule",
      source_path: "test/tmp/source_module.ex",
      function: :pub1,
      arity: 1,
      dryrun: true
    ]

    argv = OptionParser.to_argv(opts)

    {cli_output, exit_status} = System.cmd("mix", ["ex_factor" | argv])
    assert exit_status == 0

    assert cli_output =~ "Message: --dry_run changes to make"

    # no new file gets written
    assert {:error, :enoent} = File.read(target_path)
  end

  test "with --no-format" do
    content = """
    defmodule ExFactorSampleModule do
      @somedoc "This is somedoc"
      # a comment and no aliases
      _docp = "here's an arbitrary module underscore"
      @spec pub1(term()) :: term()
      def pub1(arg1) do
        :pub1_ok
      end
    end
    """

    File.write("test/tmp/source_module.ex", content)
    target_path = "test/tmp/target_module.ex"

    opts = [
      target_path: target_path,
      target: "ExFactor.NewMod",
      module: "ExFactorSampleModule",
      source_path: "test/tmp/source_module.ex",
      function: :pub1,
      arity: 1,
      format: false
    ]

    argv = OptionParser.to_argv(opts)
    |> IO.inspect(label: "")

    {_cli_output, exit_status} = System.cmd("mix", ["ex_factor" | argv])
    assert exit_status == 0
    file = File.read!(target_path) |> IO.inspect(label: "")
    assert file =~ "\n@spec pub1(term()) :: term()\ndef pub1(arg1) do\n  :pub1_ok\nend\nend"
  end
end
