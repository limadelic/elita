defmodule Elita do
  use GenServer
  
  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 3]
  import Llm, only: [llm: 2, memory_tools: 0]

  def start_link name do
    GenServer.start_link __MODULE__, name, name: {:global, name}
  end

  def act msg, pid do
    GenServer.call pid, {:act, msg}
  end

  def init name do
    create_memory_table name
    {:ok, %{name: name, config: config(name), history: []}}
  end

  def handle_call {:act, msg}, _from, %{name: name, config: config, history: history} = state do
    history = [msg | history]
    
    tools = if has_tools?(config), do: memory_tools(), else: []
    include_tool_instructions = tools == []
    resp = llm prompt(config, history, include_tool_instructions), tools
    final_resp = process_response resp, name, config, history
    
    {:reply, final_resp, %{state | history: [final_resp | history]}}
  end

  defp create_memory_table name do
    :ets.new table_name(name), [:set, :public, :named_table]
  end

  defp table_name name do
    :"memory_#{name}"
  end

  defp has_tools?(config) do
    case parse_config(config) do
      {%{"tools" => _}, _} -> true
      _ -> false
    end
  end

  defp parse_config(config) do
    case String.split(config, "---", parts: 3) do
      ["", yaml_text, content] ->
        case YamlElixir.read_from_string(yaml_text) do
          {:ok, frontmatter} -> {frontmatter, String.trim(content)}
          _ -> {%{}, config}
        end
      _ -> {%{}, config}
    end
  end

  defp process_response({:text, text}, _name, _config, _history), do: text
  
  defp process_response({:tool_call, function_call}, name, config, history) do
    result = execute_tool_call(function_call, name)
    continue_with_tool_result(result, config, history, name)
  end
  
  defp process_response({:error, error}, _name, _config, _history), do: error

  defp execute_tool_call(%{"name" => "set", "args" => %{"key" => key, "value" => value}}, name) do
    table = table_name(name)
    :ets.insert(table, {key, value})
    %{"key" => key, "result" => "stored"}
  end

  defp execute_tool_call(%{"name" => "get", "args" => %{"key" => key}}, name) do
    table = table_name(name)
    case :ets.lookup(table, key) do
      [{^key, value}] -> %{"key" => key, "result" => value}
      [] -> %{"key" => key, "result" => "not found"}
    end
  end

  defp continue_with_tool_result(result, _config, _history, _name) do
    # For now, just return a simple confirmation
    # Later we can send the result back to the LLM
    "Tool executed: #{result["result"]}"
  end

end