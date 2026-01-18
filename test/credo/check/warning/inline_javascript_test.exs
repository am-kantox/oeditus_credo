defmodule OeditusCredo.Check.Warning.InlineJavascriptTest do
  use Credo.Test.Case

  alias OeditusCredo.Check.Warning.InlineJavascript

  test "it should report issue for onclick handler" do
    ~S"""
    defmodule TestLive do
      def render(assigns) do
        ~H"<button onclick=\"alert('hi')\">Click</button>"
      end
    end
    """
    |> to_source_file("test.heex")
    |> run_check(InlineJavascript)
    |> assert_issue()
  end

  test "it should NOT report issue when using phx-click" do
    ~S"""
    defmodule TestLive do
      def render(assigns) do
        ~H"<button phx-click=\"show_alert\">Click</button>"
      end
    end
    """
    |> to_source_file("test.heex")
    |> run_check(InlineJavascript)
    |> refute_issues()
  end

  test "it should NOT report issue for non-heex files" do
    """
    def foo do
      "onclick"
    end
    """
    |> to_source_file("test.ex")
    |> run_check(InlineJavascript)
    |> refute_issues()
  end
end
