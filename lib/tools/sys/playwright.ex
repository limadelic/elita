defmodule Tools.Sys.Playwright do
  import Log, only: [log: 5]
  import Map, only: [drop: 2]

  def def(name, _state) do
    %{
      name: name,
      description: "Control browser using Playwright",
      parameters: %{
        type: "object",
        properties: %{
          action: %{type: "string", description: "navigate, content, click, type, press, screenshot, close"},
          url: %{type: "string", description: "URL for navigate"},
          selector: %{type: "string", description: "CSS selector for click/type"},
          text: %{type: "string", description: "Text for type or contains check"},
          key: %{type: "string", description: "Key for press (e.g., Enter, Escape)"},
          wait: %{type: "number", description: "Milliseconds to wait after action"}
        },
        required: ["action"]
      }
    }
  end

  def exec(_, %{"action" => action} = args, state) do
    action_atom = String.to_atom(action)
    params = drop(args, ["action"])

    log("🎭", "playwright", " #{action}", " #{inspect(params)}", :magenta)
    result = Silkd.weave(action_atom, params)

    {result, state}
  end
end
