defmodule OeditusCredo.Check.Warning.SilentErrorCaseTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.SilentErrorCase

  test "it should NOT report issue for case with error handling" do
    """
    defmodule MyModule do
      def example do
        case Accounts.get_user(1) do
          {:ok, user} -> user
          {:error, _} -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SilentErrorCase)
    |> refute_issues()
  end

  test "it should NOT report issue for case with catch-all" do
    """
    defmodule MyModule do
      def example do
        case Accounts.get_user(1) do
          {:ok, user} -> user
          _ -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SilentErrorCase)
    |> refute_issues()
  end

  test "it should report issue for case with only :ok clause" do
    """
    defmodule MyModule do
      def example do
        case Accounts.get_user(1) do
          {:ok, user} -> user
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SilentErrorCase)
    |> assert_issue()
  end

  test "it should NOT report issue for non-ok pattern case" do
    """
    defmodule MyModule do
      def example do
        case get_status() do
          :active -> :ok
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SilentErrorCase)
    |> refute_issues()
  end

  test "it should NOT report issue for case with multiple clauses including error" do
    """
    defmodule MyModule do
      def example do
        case fetch_data() do
          {:ok, data} -> process(data)
          {:error, :not_found} -> create_default()
          {:error, reason} -> log_error(reason)
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SilentErrorCase)
    |> refute_issues()
  end
end
