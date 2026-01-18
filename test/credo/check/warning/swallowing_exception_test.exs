defmodule OeditusCredo.Check.Warning.SwallowingExceptionTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.SwallowingException

  test "it should report issue for rescue without logging" do
    """
    defmodule MyModule do
      def risky do
        try do
          dangerous_operation()
        rescue
          _ -> :error
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SwallowingException)
    |> assert_issue()
  end

  test "it should NOT report issue for rescue with Logger" do
    """
    defmodule MyModule do
      def risky do
        try do
          dangerous_operation()
        rescue
          e ->
            Logger.error("Failed", error: inspect(e))
            :error
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SwallowingException)
    |> refute_issues()
  end

  test "it should NOT report issue for rescue with reraise" do
    """
    defmodule MyModule do
      def risky do
        try do
          dangerous_operation()
        rescue
          e ->
            cleanup()
            reraise e, __STACKTRACE__
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(SwallowingException)
    |> refute_issues()
  end
end
