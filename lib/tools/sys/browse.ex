defmodule Tools.Sys.Browse do
  import Log, only: [log: 5]
  import Map, only: [drop: 2]

  def def(name, _state) do
    %{
      name: name,
      description: "Control browser",
      parameters: %{
        type: "object",
        properties: %{
          action: %{type: "string", description: "navigate, snapshot, click, type, press, content"},
          url: %{type: "string", description: "URL for navigate"},
          index: %{type: "number", description: "Element index from snapshot for click/type"},
          text: %{type: "string", description: "Text for type"},
          key: %{type: "string", description: "Key for press (Enter, Escape, etc)"},
          wait: %{type: "number", description: "Milliseconds to wait after action"}
        },
        required: ["action"]
      }
    }
  end

  def exec(_, %{"action" => action} = args, state) do
    action_atom = String.to_atom(action)
    params = drop(args, ["action"])

    log("🌐", "browse", " #{action}", " #{inspect(params)}", :magenta)
    result = Silkd.weave(action_atom, params)

    {result, state}
  end
end
