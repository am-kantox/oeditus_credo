defmodule OeditusCredo.Check.Warning.HardcodedValue do
  use Credo.Check,
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Hardcoded URLs, IP addresses, and secrets should be moved to configuration.

      Hardcoding values makes the code less flexible and can expose sensitive information.

      Bad:

          api_url = "https://api.example.com"
          db_host = "192.168.1.100"

      Good:

          api_url = Application.get_env(:my_app, :api_url)
          db_host = System.get_env("DB_HOST")
      """,
      params: [
        exclude_test_files: "Set to false to check test files"
      ]
    ]

  @url_pattern ~r/https?:\/\/[^\s"']+/
  @ip_pattern ~r/\b(?:\d{1,3}\.){3}\d{1,3}\b/

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    exclude_test = Params.get(params, :exclude_test_files, __MODULE__)

    if exclude_test and test_file?(source_file.filename) do
      []
    else
      source_file
      |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
    end
  end

  @doc false
  @impl true
  def param_defaults do
    [exclude_test_files: true]
  end

  defp traverse({:<<>>, meta, [string]} = ast, issues, issue_meta) when is_binary(string) do
    issues =
      cond do
        Regex.match?(@url_pattern, string) and not localhost?(string) ->
          [issue_for(issue_meta, meta[:line], "hardcoded URL") | issues]

        Regex.match?(@ip_pattern, string) and not local_ip?(string) ->
          [issue_for(issue_meta, meta[:line], "hardcoded IP address") | issues]

        true ->
          issues
      end

    {ast, issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp test_file?(filename) do
    String.ends_with?(filename, "_test.exs") or String.contains?(filename, "/test/")
  end

  defp localhost?(url) do
    String.contains?(url, "localhost") or String.contains?(url, "127.0.0.1")
  end

  defp local_ip?(ip) do
    String.starts_with?(ip, "127.") or String.starts_with?(ip, "192.168.") or
      String.starts_with?(ip, "10.") or ip == "0.0.0.0"
  end

  defp issue_for(issue_meta, line_no, type) do
    format_issue(
      issue_meta,
      message: "Avoid #{type} in code, use configuration instead",
      trigger: type,
      line_no: line_no || 1
    )
  end
end
