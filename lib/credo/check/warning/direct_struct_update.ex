defmodule OeditusCredo.Check.Warning.DirectStructUpdate do
  use Credo.Check,
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Use changesets instead of direct struct updates for data validation.

      Direct struct updates bypass validation and can lead to invalid data in the database.

      Bad:

          user = %User{user | email: new_email}
          Map.put(user, :email, new_email)

      Good:

          user
          |> User.changeset(%{email: new_email})
          |> Repo.update()
      """,
      params: []
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
  end

  # Match struct update syntax: %User{user | field: value}
  defp traverse(
         {:%, meta, [_module, {:%{}, _, [{:|, _, [_struct, _updates]}]}]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta[:line], "struct update") | issues]}
  end

  # Match Map.put on what looks like a struct
  defp traverse(
         {{:., meta, [{:__aliases__, _, [:Map]}, :put]}, _, [struct_var | _]} = ast,
         issues,
         issue_meta
       ) do
    if looks_like_struct?(struct_var) do
      {ast, [issue_for(issue_meta, meta[:line], "Map.put") | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  # Check if variable name suggests it's a struct (capitalized or ends with common struct suffixes)
  defp looks_like_struct?({name, _, _}) when is_atom(name) do
    name_str = Atom.to_string(name)
    String.match?(name_str, ~r/(user|post|comment|account|record|entity|model)$/)
  end

  defp looks_like_struct?(_), do: false

  defp issue_for(issue_meta, line_no, type) do
    format_issue(
      issue_meta,
      message: "Use Ecto changesets instead of direct #{type} for data validation",
      trigger: type,
      line_no: line_no
    )
  end
end
