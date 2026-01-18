defmodule OeditusCredo.Check.Warning.InefficientFilterTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.InefficientFilter

  test "it should NOT report issue for query with where clause" do
    """
    defmodule MyModule do
      import Ecto.Query
      def get_active_users do
        User |> where([u], u.active == true) |> Repo.all()
      end
    end
    """
    |> to_source_file()
    |> run_check(InefficientFilter)
    |> refute_issues()
  end

  test "it should report issue for Repo.all followed by Enum.filter" do
    """
    defmodule MyModule do
      def get_active_users do
        users = Repo.all(User)
        Enum.filter(users, & &1.active)
      end
    end
    """
    |> to_source_file()
    |> run_check(InefficientFilter)
    |> assert_issue()
  end
end
