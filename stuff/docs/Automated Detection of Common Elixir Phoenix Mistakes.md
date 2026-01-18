# Automated Detection Plan
## Problem Statement
We need to create automated detection for common mistakes in Elixir Phoenix projects. Each check should target a single potential issue and be executable as part of the standard Credo workflow.
## Current State
We have documented 30+ common mistakes in `docs/typical-elixir-phoenix-mistakes.md`. The Oeditus codebase uses:
* Ecto for database operations
* Phoenix LiveView for real-time UIs
* PubSub for broadcasting
* Oban for background jobs
* Docker for isolated execution
* Standard Elixir patterns (contexts, changesets, etc.)
Some patterns in the current codebase:
* Proper preloading in `get_audit_with_findings!/1` (lib/oeditus/audits.ex:36-40)
* PubSub broadcasting in `update_audit_progress/2` (lib/oeditus/audits.ex:78-82)
* PubSub subscription in LiveView mount (lib/oeditus_web/live/audit_live/show.ex:11-13)
* Filtering in Elixir after Repo.all in `list_audit_findings/1` (potential optimization target)
## Implementation Status
We have implemented 20 custom Credo checks as an Elixir library (`oeditus_credo`) that integrates with the standard Credo workflow.
### Check Organization
Implemented as custom Credo checks in `lib/credo/check/warning/`:

#### Error Handling (3 checks)
* `missing_error_handling.ex` - Detects `{:ok, x} =` without error handling
* `silent_error_case.ex` - Detects case statements missing error branches
* `swallowing_exception.ex` - Detects try/rescue without logging or re-raising

#### Database & Performance (3 checks)
* `inefficient_filter.ex` - Detects Repo.all followed by Enum filtering
* `n_plus_one_query.ex` - Detects potential N+1 queries (Enum.map with Repo calls)
* `missing_preload.ex` - Detects Ecto queries without proper preloading

#### LiveView & Concurrency (5 checks)
* `unmanaged_task.ex` - Detects unsupervised Task.async calls
* `sync_over_async.ex` - Detects blocking operations in LiveView/GenServer
* `missing_handle_async.ex` - Detects blocking in handle_event without async pattern
* `missing_throttle.ex` - Detects form inputs without phx-debounce/throttle
* `inline_javascript.ex` - Detects inline JS handlers instead of phx-* bindings

#### Code Quality (4 checks)
* `hardcoded_value.ex` - Detects hardcoded URLs, IPs, and secrets
* `direct_struct_update.ex` - Detects direct struct updates instead of changesets
* `callback_hell.ex` - Detects deeply nested case statements
* `blocking_in_plug.ex` - Detects blocking operations in Plug functions

#### Telemetry & Observability (5 checks)
* `missing_telemetry_in_oban_worker.ex` - Detects Oban workers without telemetry
* `missing_telemetry_in_live_view_mount.ex` - Detects LiveView mount/3 without telemetry
* `telemetry_in_recursive_function.ex` - Detects telemetry in recursive functions (anti-pattern)
* `missing_telemetry_in_auth_plug.ex` - Detects auth plugs without telemetry
* `missing_telemetry_for_external_http.ex` - Detects HTTP calls without telemetry wrapper
### Implementation Approach
#### Implemented as Credo Checks (20 checks)
All checks use Elixir's AST (Abstract Syntax Tree) analysis via Credo's framework:

1. **N+1 queries** - Analyzes `Enum.map` or `Enum.each` containing `Repo.get` or association access
2. **Missing preload** - Analyzes query pipelines for missing `preload` before `Repo.all`/`Repo.one`
3. **Sync-over-async** - Detects blocking operations in `handle_event`, `handle_call`, `handle_info`
4. **Unmanaged tasks** - Finds `Task.async` not under supervision
5. **Missing error handling** - Detects `{:ok, x} =` pattern without error handling
6. **Hardcoded values** - Pattern matches string literals containing URLs, IPs, secrets
7. **Direct struct updates** - Detects `%Struct{x | field: value}` patterns on schemas
8. **Inefficient filter** - Detects `Repo.all()` followed by `Enum.filter`/`reject`/`find`
9. **Missing throttle/debounce** - Parses HEEx for `phx-change`/`phx-keyup` without throttling
10. **Inline JavaScript** - Detects `onclick=`, `onchange=`, etc. in templates
11. **Silent error case** - Detects case statements without error/failure branches
12. **Swallowing exceptions** - Detects try/rescue without logging or re-raising
13. **Missing handle_async** - Detects blocking in `handle_event` without async wrapper
14. **Callback hell** - Detects deeply nested case statements (configurable depth)
15. **Blocking in Plug** - Detects expensive operations in `call/2` and `init/1`
16-20. **Telemetry checks** - Comprehensive telemetry instrumentation detection

#### Not Implemented Yet
* Missing indexes (requires schema + migration analysis)
* Cartesian product joins (requires query semantic analysis)
* Channel memory leaks (requires subscription tracking)
* GenServer state bloat (requires runtime analysis)
* Excessive re-renders (requires LiveView semantics understanding)
* Memory leaks in streams (requires stream usage pattern analysis)
* God contexts (requires architectural analysis)
* Timeout misconfigurations (requires config + actual timing data)
* Test database issues (requires test execution analysis)
### Usage
Install the library and add checks to `.credo.exs`:

```elixir
defp deps do
  [
    {:oeditus_credo, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

Configure in `.credo.exs`:

```elixir
%{
  configs: [
    %{
      name: "default",
      checks: %{
        enabled: [
          {OeditusCredo.Check.Warning.MissingErrorHandling, []},
          {OeditusCredo.Check.Warning.NPlusOneQuery, []},
          # ... all 20 checks ...
        ]
      }
    }
  ]
}
```

Run with:
```bash
mix credo
```

### Output Format
Standard Credo output with file path, line number, and issue description:

```
┃ [W] → Potential optimization: Repo.all followed by filtering in Elixir
┃       lib/oeditus/audits.ex:115:5 (OeditusCredo.Check.Warning.InefficientFilter)
┃ [W] → Consider using phx-debounce for this form input
┃       lib/oeditus_web/live/audit_live/show.ex:27:3 (OeditusCredo.Check.Warning.MissingThrottle)
```

### Test Coverage
58 comprehensive tests covering all 20 checks with positive and negative cases.
