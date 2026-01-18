defmodule OeditusCredo.Check.Warning.MissingPreloadTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.MissingPreload

  test "it should NOT report issue when preload is used" do
    """
    defmodule MyModule do
      def get_users do
        User |> preload(:posts) |> Repo.all()
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingPreload)
    |> refute_issues()
  end

  test "it should report issue for Repo.all without preload" do
    """
    defmodule MyModule do
      def get_users do
        User |> where([u], u.active) |> Repo.all()
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingPreload)
    |> assert_issue()
  end

  test "it should NOT report issue for direct Repo.all call" do
    """
    defmodule MyModule do
      def get_users do
        Repo.all(User)
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingPreload)
    |> refute_issues()
  end

  test "it should NOT report issue when preload is earlier in chain" do
    """
    defmodule MyModule do
      def get_users do
        User |> preload(:posts) |> where([u], u.active) |> Repo.all()
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingPreload)
    |> refute_issues()
  end
end
