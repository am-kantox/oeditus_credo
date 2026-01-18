defmodule OeditusCredo.Check.Warning.BlockingInPlugTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.BlockingInPlug

  test "it should report issue for Repo call in plug function" do
    """
    defmodule MyPlug do
      def load_user(conn, _opts) do
        user = Repo.get!(User, conn.assigns.user_id)
        assign(conn, :user, user)
      end
    end
    """
    |> to_source_file()
    |> run_check(BlockingInPlug)
    |> assert_issue()
  end

  test "it should NOT report issue for plug without blocking calls" do
    """
    defmodule MyPlug do
      def assign_default(conn, _opts) do
        assign(conn, :default, true)
      end
    end
    """
    |> to_source_file()
    |> run_check(BlockingInPlug)
    |> refute_issues()
  end
end
