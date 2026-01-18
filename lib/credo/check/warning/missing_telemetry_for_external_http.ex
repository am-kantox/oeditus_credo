defmodule OeditusCredo.Check.Warning.MissingTelemetryForExternalHttp do
  use Credo.Check,
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      External HTTP requests should be wrapped with telemetry for observability.

      Instrumenting HTTP client calls helps track external API latency, failure rates,
      and can help identify third-party service issues.

      Bad:

          def fetch_user_data(user_id) do
            Req.get!("https://api.example.com/users/\#{user_id}")
          end

      Good:

          def fetch_user_data(user_id) do
            url = "https://api.example.com/users/\#{user_id}"
            :telemetry.span(
              [:http, :request],
              %{method: :get, url: url},
              fn ->
                result = Req.get!(url)
                {result, %{status: result.status}}
              end
            )
          end

      This check detects calls to common HTTP clients: Req, HTTPoison, Finch, Tesla, :httpc
      """,
      params: []
    ]

  @http_clients [
    # Req
    {[:Req],
     [
       :get,
       :get!,
       :post,
       :post!,
       :put,
       :put!,
       :patch,
       :patch!,
       :delete,
       :delete!,
       :head,
       :head!,
       :request,
       :request!
     ]},
    # HTTPoison
    {[:HTTPoison],
     [
       :get,
       :get!,
       :post,
       :post!,
       :put,
       :put!,
       :patch,
       :patch!,
       :delete,
       :delete!,
       :head,
       :head!,
       :request,
       :request!
     ]},
    # Finch
    {[:Finch], [:request, :request!, :stream, :stream!]},
    # Tesla
    {[:Tesla],
     [
       :get,
       :get!,
       :post,
       :post!,
       :put,
       :put!,
       :patch,
       :patch!,
       :delete,
       :delete!,
       :head,
       :head!,
       :request,
       :request!
     ]},
    # :httpc (erlang)
    {:httpc, [:request]}
  ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {:def, _, [{func_name, _, _}, [do: body]]} = ast,
         issues,
         issue_meta
       ) do
    issues = check_function_body(body, issues, issue_meta, func_name)
    {ast, issues}
  end

  defp traverse(
         {:def, _, [{func_name, _, _}, body_kwlist]} = ast,
         issues,
         issue_meta
       )
       when is_list(body_kwlist) do
    body = Keyword.get(body_kwlist, :do)
    issues = check_function_body(body, issues, issue_meta, func_name)
    {ast, issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp check_function_body(body, issues, issue_meta, func_name) do
    # Check if function has HTTP calls but no telemetry wrapper
    if has_http_call?(body) and not has_telemetry_wrapper?(body) do
      # Find line number of first HTTP call
      case find_http_call_line(body) do
        {:ok, line_no, client, method} ->
          [issue_for(issue_meta, line_no, client, method, func_name) | issues]

        :not_found ->
          issues
      end
    else
      issues
    end
  end

  defp has_http_call?(body) do
    {_ast, found} =
      Macro.prewalk(body, false, fn
        {{:., _, [{:__aliases__, _, client}, method]}, _, _} = ast, acc ->
          if http_client_call?(client, method) do
            {ast, true}
          else
            {ast, acc}
          end

        {{:., _, [client, method]}, _, _} = ast, acc when is_atom(client) ->
          if http_client_call?(client, method) do
            {ast, true}
          else
            {ast, acc}
          end

        ast, acc ->
          {ast, acc}
      end)

    found
  end

  defp has_telemetry_wrapper?(body) do
    {_ast, found} =
      Macro.prewalk(body, false, fn
        {{:., _, [:telemetry, func]}, _, _} = ast, _acc when func in [:execute, :span] ->
          {ast, true}

        {{:., _, [{:__aliases__, _, [:telemetry]}, func]}, _, _} = ast, _acc
        when func in [:execute, :span] ->
          {ast, true}

        ast, acc ->
          {ast, acc}
      end)

    found
  end

  defp find_http_call_line(body) do
    {_ast, result} =
      Macro.prewalk(body, :not_found, fn
        {{:., meta, [{:__aliases__, _, client}, method]}, _, _} = ast, :not_found ->
          if http_client_call?(client, method) do
            {ast, {:ok, meta[:line], Enum.join(client, "."), method}}
          else
            {ast, :not_found}
          end

        {{:., meta, [client, method]}, _, _} = ast, :not_found when is_atom(client) ->
          if http_client_call?(client, method) do
            {ast, {:ok, meta[:line], client, method}}
          else
            {ast, :not_found}
          end

        ast, acc ->
          {ast, acc}
      end)

    result
  end

  defp http_client_call?(client, method) when is_list(client) do
    Enum.any?(@http_clients, fn {client_name, methods} ->
      client_name == client and method in methods
    end)
  end

  defp http_client_call?(client, method) when is_atom(client) do
    Enum.any?(@http_clients, fn {client_name, methods} ->
      client_name == client and method in methods
    end)
  end

  defp issue_for(issue_meta, line_no, client, method, func_name) do
    format_issue(
      issue_meta,
      message:
        "HTTP request #{client}.#{method} in #{func_name}/_ should be wrapped with telemetry for observability",
      trigger: "#{client}.#{method}",
      line_no: line_no
    )
  end
end
