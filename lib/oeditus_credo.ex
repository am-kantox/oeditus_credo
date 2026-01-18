defmodule OeditusCredo do
  @moduledoc """
  OeditusCredo provides custom Credo checks for detecting common Elixir/Phoenix anti-patterns.

  ## Usage

  Add to your `.credo.exs`:

      %{
        configs: [
          %{
            name: "default",
            checks: %{
              enabled: [
                {OeditusCredo.Check.Warning.MissingErrorHandling, []},
                {OeditusCredo.Check.Warning.SilentErrorCase, []},
                {OeditusCredo.Check.Warning.InefficientFilter, []},
                # ... other checks
              ]
            }
          }
        ]
      }

  ## Available Checks

  ### Error Handling
  - `OeditusCredo.Check.Warning.MissingErrorHandling` - Detects `{:ok, x} =` without error handling
  - `OeditusCredo.Check.Warning.SilentErrorCase` - Detects case statements missing error branches
  - `OeditusCredo.Check.Warning.SwallowingException` - Detects try/rescue without re-raising or logging

  ### Query & Data Access
  - `OeditusCredo.Check.Warning.NPlusOneQuery` - Detects N+1 query patterns
  - `OeditusCredo.Check.Warning.InefficientFilter` - Detects Repo.all followed by Enum filtering
  - `OeditusCredo.Check.Warning.MissingPreload` - Detects Ecto queries without proper preloading

  ### Concurrency & Performance
  - `OeditusCredo.Check.Warning.UnmanagedTask` - Detects unsupervised Task.async calls
  - `OeditusCredo.Check.Warning.SyncOverAsync` - Detects blocking operations in LiveView/GenServer
  - `OeditusCredo.Check.Warning.MissingHandleAsync` - Detects blocking in handle_event without async pattern

  ### Configuration
  - `OeditusCredo.Check.Warning.HardcodedValue` - Detects hardcoded URLs, IPs, secrets

  ### Code Organization
  - `OeditusCredo.Check.Warning.DirectStructUpdate` - Detects struct updates instead of changesets
  - `OeditusCredo.Check.Warning.CallbackHell` - Detects chained case statements
  - `OeditusCredo.Check.Warning.BlockingInPlug` - Detects blocking operations in Plug functions

  ### LiveView & Templates
  - `OeditusCredo.Check.Warning.MissingThrottle` - Detects form inputs without phx-debounce/throttle
  - `OeditusCredo.Check.Warning.InlineJavascript` - Detects inline JS handlers instead of phx-* bindings

  ### Telemetry & Observability
  - `OeditusCredo.Check.Warning.MissingTelemetryInObanWorker` - Detects Oban workers without telemetry
  - `OeditusCredo.Check.Warning.MissingTelemetryInLiveViewMount` - Detects LiveView mount/3 without telemetry
  - `OeditusCredo.Check.Warning.TelemetryInRecursiveFunction` - Detects telemetry in recursive functions (anti-pattern)
  - `OeditusCredo.Check.Warning.MissingTelemetryInAuthPlug` - Detects auth plugs without telemetry
  - `OeditusCredo.Check.Warning.MissingTelemetryForExternalHttp` - Detects HTTP calls without telemetry
  """

  @version Mix.Project.config()[:version]

  @doc "Returns the version of OeditusCredo"
  def version, do: @version
end
