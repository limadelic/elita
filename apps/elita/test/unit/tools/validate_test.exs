defmodule Tools.User.ValidateUnitTest do
  use ExUnit.Case
  @moduletag :main
  @moduletag :spec

  describe "validate tool params at load" do
    test "tool with undeclared variable in snippet fails with clear message" do
      tool = %{
        name: "bad_tool",
        body: "A tool that uses undeclared vars",
        params: "x",
        code: ["x + y"]
      }

      assert_raise RuntimeError, ~r/bad_tool.*undefined variable.*y/, fn ->
        Tools.User.Validate.check(tool)
      end
    end

    test "tool with all variables declared loads fine" do
      tool = %{
        name: "good_tool",
        body: "A tool that declares all vars",
        params: "x, y",
        code: ["x + y"]
      }

      result = Tools.User.Validate.check(tool)
      assert result == tool
    end

    test "tool with no params and no code loads fine" do
      tool = %{
        name: "simple_tool",
        body: "A simple tool",
        code: ["123"]
      }

      result = Tools.User.Validate.check(tool)
      assert result == tool
    end

    test "tool with empty params field loads fine" do
      tool = %{
        name: "empty_params_tool",
        body: "A tool",
        params: "",
        code: ["123"]
      }

      result = Tools.User.Validate.check(tool)
      assert result == tool
    end

    test "tool with nil params loads fine" do
      tool = %{
        name: "nil_params_tool",
        body: "A tool",
        params: nil,
        code: ["123"]
      }

      result = Tools.User.Validate.check(tool)
      assert result == tool
    end

    test "tool with empty code list loads fine" do
      tool = %{
        name: "no_code_tool",
        body: "A tool",
        params: "x",
        code: []
      }

      result = Tools.User.Validate.check(tool)
      assert result == tool
    end

    test "snippet with side effects does not execute" do
      tool = %{
        name: "side_effect_tool",
        body: "A tool that would send a message",
        params: "name",
        code: ["send(self(), :boom); name"]
      }

      result = Tools.User.Validate.check(tool)
      assert result == tool
      refute_received :boom
    end
  end
end
