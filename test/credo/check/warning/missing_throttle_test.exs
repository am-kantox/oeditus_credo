defmodule OeditusCredo.Check.Warning.MissingThrottleTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.MissingThrottle

  test "it should report issue for phx-change without throttle" do
    ~S"""
    defmodule TestLive do
      def render(assigns) do
        ~H"<input type=\"text\" phx-change=\"search\" />"
      end
    end
    """
    |> to_source_file("test.heex")
    |> run_check(MissingThrottle)
    |> assert_issue()
  end

  test "it should NOT report issue when using phx-debounce" do
    ~S"""
    defmodule TestLive do
      def render(assigns) do
        ~H"<input type=\"text\" phx-change=\"search\" phx-debounce=\"300\" />"
      end
    end
    """
    |> to_source_file("test.heex")
    |> run_check(MissingThrottle)
    |> refute_issues()
  end

  test "it should NOT report issue for non-heex files" do
    """
    def foo do
      "phx-change"
    end
    """
    |> to_source_file("test.ex")
    |> run_check(MissingThrottle)
    |> refute_issues()
  end
end
