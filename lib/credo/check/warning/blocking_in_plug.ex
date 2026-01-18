defmodule OeditusCredo.Check.Warning.BlockingInPlug do
  use Credo.Check,
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Expensive blocking operations in Plug functions slow down request processing.

      Move expensive operations to background jobs or async tasks.

      Bad:

          plug :load_user_data

          def load_user_data(conn, _opts) do
            user = Repo.get!(User, conn.assigns.user_id)
            assign(conn, :user, user)
          end

      Good:

          # Load user data in the controller action instead
          def show(conn, params) do
            user = Repo.get!(User, params["id"])
            render(conn, "show.html", user: user)
          end
      """,
      params: []
    ]

  @blocking_modules [:Repo, :HTTPoison, :Req, :File]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
  end

  # Check functions that might be used as plugs (accept conn as first arg)
  defp traverse(
         {:def, meta, [{func_name, _, [{:conn, _, _} | _rest]}, [do: body]]} = ast,
         issues,
         issue_meta
       ) do
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

  defp has_blocking_calls?({{:., _, [{:__aliases__, _, aliases}, _func]}, _, _}) do
    List.last(aliases) in @blocking_modules
  end

  defp has_blocking_calls?({_form, _, args}) when is_list(args) do
    Enum.any?(args, &has_blocking_calls?/1)
  end

  defp has_blocking_calls?(_), do: false

  defp issue_for(issue_meta, line_no, func_name) do
    format_issue(
      issue_meta,
      message: "Blocking operation in plug function #{func_name} - consider moving to controller",
      trigger: "#{func_name}",
      line_no: line_no
    )
  end
end
