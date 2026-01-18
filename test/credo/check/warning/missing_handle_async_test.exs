defmodule OeditusCredo.Check.Warning.MissingHandleAsyncTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.MissingHandleAsync

  test "it should report issue for blocking call in handle_event" do
    """
    defmodule MyLive do
      def handle_event("load", _params, socket) do
        data = Repo.all(Post)
        {:noreply, assign(socket, :posts, data)}
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingHandleAsync)
    |> assert_issue()
  end

  test "it should NOT report issue when using start_async" do
    """
    defmodule MyLive do
      def handle_event("load", _params, socket) do
        {:noreply, start_async(socket, :posts, fn -> Repo.all(Post) end)}
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingHandleAsync)
    |> refute_issues()
  end
end
