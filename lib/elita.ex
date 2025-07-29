defmodule Elita do
  use GenServer
  
  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 3]
  import Llm, only: [llm: 2]
  import Tools, only: [memory_tools: 0, execute: 2]
  import String, only: [split: 3, trim: 1]

  def start_link name do
    GenServer.start_link __MODULE__, name, name: {:global, name}
  end

  def act msg, pid do
    GenServer.call pid, {:act, msg}
  end

  def init name do
    create_memory name
    {:ok, %{name: name, config: config(name), history: []}}
  end

  def handle_call {:act, msg}, _from, %{name: name, config: config, history: history} = state do
    history = [msg | history]
    
    tools = if(has_tools?(config), do: memory_tools(), else: [])
    include_tools = tools == []
    resp = llm prompt(config, history, include_tools), tools
    final = done? resp, name, config, history
    
    {:reply, final, %{state | history: [final | history]}}
  end

  defp create_memory name do
    :ets.new table(name), [:set, :public, :named_table]
  end

  defp table name do
    :"memory_#{name}"
  end

  defp has_tools? config do
    case parse(config) do
      {%{"tools" => _}, _} -> true
      _ -> false
    end
  end

  defp parse config do
    case split config, "---", parts: 3 do
      ["", yaml_text, content] ->
        case YamlElixir.read_from_string yaml_text do
          {:ok, frontmatter} -> {frontmatter, trim content}
          _ -> {%{}, config}
        end
      _ -> {%{}, config}
    end
  end

  defp done?({:text, text}, _name, _config, _history), do: text
  
  defp done?({:tool_call, call}, name, config, history) do
    result = execute call, name
    continue result, config, history, name
  end
  
  defp done?({:error, error}, _name, _config, _history), do: error


  defp continue result, _config, _history, _name do
    "Tool executed: #{result["result"]}"
  end

end