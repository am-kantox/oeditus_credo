defmodule OeditusCredo.Check.Warning.MissingHandleAsync do
  use Credo.Check,
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      LiveView handle_event with blocking operations should use start_async and handle_async.

      This prevents blocking the LiveView process and provides better UX.

      Bad:

          def handle_event("load", _params, socket) do
            data = Repo.all(Post)
            {:noreply, assign(socket, :posts, data)}
          end

      Good:

          def handle_event("load", _params, socket) do
            {:noreply, start_async(socket, :posts, fn -> Repo.all(Post) end)}
          end

          def handle_async(:posts, {:ok, posts}, socket) do
            {:noreply, assign(socket, :posts, posts)}
          end
      """,
      params: []
    ]

  @blocking_modules [:Repo, :HTTPoison, :Req]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
  end

  defp traverse({:def, meta, [{:handle_event, _, _}, [do: body]]} = ast, issues, issue_meta) do
    issues =
      if has_blocking_calls?(body) and not has_async_call?(body) do
        [issue_for(issue_meta, meta[:line]) | issues]
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

  defp has_blocking_calls?({{:., _, [{:__aliases__, _, aliases}, _]}, _, _}) do
    List.last(aliases) in @blocking_modules
  end

  defp has_blocking_calls?({_form, _, args}) when is_list(args) do
    Enum.any?(args, &has_blocking_calls?/1)
  end

  defp has_blocking_calls?(_), do: false

  defp has_async_call?({:__block__, _, statements}) when is_list(statements) do
    Enum.any?(statements, &has_async_call?/1)
  end

  defp has_async_call?({:start_async, _, _}), do: true
  defp has_async_call?({:assign_async, _, _}), do: true

  defp has_async_call?({_form, _, args}) when is_list(args) do
    Enum.any?(args, &has_async_call?/1)
  end

  defp has_async_call?(_), do: false

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Use start_async and handle_async for blocking operations in handle_event",
      trigger: "handle_event",
      line_no: line_no
    )
  end
end
