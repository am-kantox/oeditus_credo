defmodule OeditusCredo.Check.Warning.MissingErrorHandlingTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.MissingErrorHandling

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
    |> run_check(MissingErrorHandling)
    |> refute_issues()
  end

  test "it should NOT report issue for with statement" do
    """
    defmodule MyModule do
      def example do
        with {:ok, user} <- Accounts.get_user(1) do
          user
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingErrorHandling)
    |> refute_issues()
  end

  test "it should report issue for direct pattern match on :ok tuple" do
    """
    defmodule MyModule do
      def example do
        {:ok, user} = Accounts.get_user(1)
        user
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingErrorHandling)
    |> assert_issue()
  end

  test "it should report issue for two-element :ok tuple pattern match" do
    """
    defmodule MyModule do
      def example(id) do
        {:ok, result} = fetch_data(id)
        result
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingErrorHandling)
    |> assert_issue()
  end

  test "it should NOT report issue for pattern match in function head" do
    """
    defmodule MyModule do
      def example({:ok, value}) do
        value
      end

      def example({:error, _reason}) do
        nil
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingErrorHandling)
    |> refute_issues()
  end

  test "it should NOT report issue for non-ok tuple pattern match" do
    """
    defmodule MyModule do
      def example do
        {:some, :tuple} = get_data()
        :tuple
      end
    end
    """
    |> to_source_file()
    |> run_check(MissingErrorHandling)
    |> refute_issues()
  end
end
