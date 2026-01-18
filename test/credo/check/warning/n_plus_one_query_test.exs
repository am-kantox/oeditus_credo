defmodule OeditusCredo.Check.Warning.NPlusOneQueryTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.NPlusOneQuery

  test "it should NOT report issue for preloaded associations" do
    """
    defmodule MyModule do
      def get_users_with_posts do
        User |> preload(:posts) |> Repo.all()
      end
    end
    """
    |> to_source_file()
    |> run_check(NPlusOneQuery)
    |> refute_issues()
  end

  test "it should report issue for Enum.map with Repo.get" do
    """
    defmodule MyModule do
      def get_posts_for_users(users) do
        Enum.map(users, fn user ->
          Repo.get_by(Post, user_id: user.id)
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(NPlusOneQuery)
    |> assert_issue()
  end

  test "it should report issue for Enum.each with Repo call" do
    """
    defmodule MyModule do
      def process_users(users) do
        Enum.each(users, fn user ->
          posts = Repo.all(from p in Post, where: p.user_id == ^user.id)
          process(posts)
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(NPlusOneQuery)
    |> assert_issue()
  end

  test "it should NOT report issue for Enum.map without Repo calls" do
    """
    defmodule MyModule do
      def format_users(users) do
        Enum.map(users, fn user -> user.name end)
      end
    end
    """
    |> to_source_file()
    |> run_check(NPlusOneQuery)
    |> refute_issues()
  end
end
