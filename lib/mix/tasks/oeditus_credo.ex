defmodule Mix.Tasks.OeditusCredo do
  @moduledoc """
  Runs Credo with all OeditusCredo checks enabled.

  ## Usage

      mix oeditus_credo [OPTIONS]

  All options are passed through to Credo. Examples:

      mix oeditus_credo --strict
      mix oeditus_credo --all
      mix oeditus_credo lib/my_app
      mix oeditus_credo --format=json
  """

  use Mix.Task

  @shortdoc "Runs Credo with all OeditusCredo checks"

  @impl Mix.Task
  def run(args) do
    config = OeditusCredo.CLI.default_config()

    # Write temporary .credo.exs with all checks enabled
    temp_config_path =
      Path.join(System.tmp_dir!(), "oeditus_credo_#{System.unique_integer([:positive])}.exs")

    File.write!(temp_config_path, config)

    try do
      # Run Credo with our config
      Mix.Task.run("credo", ["--config-file", temp_config_path | args])
    after
      File.rm(temp_config_path)
    end
  end
end
