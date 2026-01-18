defmodule OeditusCredo.Check.Warning.CallbackHellTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.CallbackHell

  test "it should NOT report issue for single case" do
    """
    defmodule MyModule do
      def example do
        case get_user() do
          {:ok, user} -> user
          _ -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CallbackHell)
    |> refute_issues()
  end

  test "it should report issue for deeply nested cases" do
    """
    defmodule MyModule do
      def example do
        case get_user() do
          {:ok, user} ->
            case get_account(user) do
              {:ok, account} ->
                case process(account) do
                  {:ok, result} -> result
                end
            end
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CallbackHell)
    |> assert_issue()
  end

  test "it should NOT report issue for with statement" do
    """
    defmodule MyModule do
      def example do
        with {:ok, user} <- get_user(),
             {:ok, account} <- get_account(user) do
          account
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(CallbackHell)
    |> refute_issues()
  end
end
