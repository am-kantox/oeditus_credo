defmodule OeditusCredo.Check.Warning.SyncOverAsyncTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.SyncOverAsync

  test "it should report issue for Repo call in handle_event" do
    """
    defmodule MyLive do
      def handle_event("save", params, socket) do
        user = Repo.get!(User, params["id"])
        {:noreply, assign(socket, :user, user)}
      end
    end
    """
    |> to_source_file()
    |> run_check(SyncOverAsync)
    |> assert_issue()
  end

  test "it should NOT report issue for async operation" do
    """
    defmodule MyLive do
      def handle_event("save", params, socket) do
        socket = assign_async(socket, :user, fn ->
          {:ok, %{user: Repo.get!(User, params["id"])}}
        end)
        {:noreply, socket}
      end
    end
    """
    |> to_source_file()
    |> run_check(SyncOverAsync)
    |> refute_issues()
  end

  test "it should report issue for HTTP call in handle_call" do
    """
    defmodule MyServer do
      def handle_call(:fetch, _from, state) do
        response = HTTPoison.get("https://api.example.com")
        {:reply, response, state}
      end
    end
    """
    |> to_source_file()
    |> run_check(SyncOverAsync)
    |> assert_issue()
  end

  test "it should NOT report issue for non-callback functions" do
    """
    defmodule MyModule do
      def my_function do
        Repo.all(User)
      end
    end
    """
    |> to_source_file()
    |> run_check(SyncOverAsync)
    |> refute_issues()
  end
end
