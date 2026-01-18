defmodule OeditusCredo.Check.Warning.SyncOverAsync do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Blocking operations in LiveView event handlers or GenServer callbacks cause performance issues.

      Offload expensive operations to async tasks or background jobs.

      Bad:

          def handle_event("save", params, socket) do
            user = Repo.get!(User, params["id"])
            {:noreply, assign(socket, :user, user)}
          end

      Good:

          def handle_event("save", params, socket) do
            socket = assign_async(socket, :user, fn ->
              {:ok, %{user: Repo.get!(User, params["id"])}}
            end)
            {:noreply, socket}
          end
      """,
      params: []
    ]

  @blocking_modules [:Repo, :HTTPoison, :Req, :File, :System]
  @callback_functions [:handle_event, :handle_call, :handle_info, :handle_cast, :handle_continue]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
  end

  # Match callback functions
  defp traverse(
         {:def, meta, [{func_name, _, _args} = _head, [do: body]]} = ast,
         issues,
         issue_meta
       )
       when func_name in @callback_functions do
    issues =
      if has_blocking_calls?(body) do
        [issue_for(issue_meta, meta[:line], func_name) | issues]
      else
        issues
      end

    {ast, issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp has_blocking_calls?({:__block__, _, statements}) when is_list(statements) do
    Enum.any?(statements, &has_blocking_calls?/1)
  end

  # Check for blocking module calls
  defp has_blocking_calls?({{:., _, [{:__aliases__, _, aliases}, _func]}, _, _}) do
    List.last(aliases) in @blocking_modules
  end

  # Recursively check nested structures
  defp has_blocking_calls?({_form, _, args}) when is_list(args) do
    Enum.any?(args, &has_blocking_calls?/1)
  end

  defp has_blocking_calls?(_), do: false

  defp issue_for(issue_meta, line_no, func_name) do
    format_issue(
      issue_meta,
      message: "Blocking operation in #{func_name} - consider using async tasks",
      trigger: "#{func_name}",
      line_no: line_no
    )
  end
end
