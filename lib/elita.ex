defmodule Elita do
  use GenServer
  
  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]
  import Tools, only: [execute: 2, create_memory: 1]

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
    
    resp = llm prompt(config, history)
    final = done? resp, name, config, history
    
    {:reply, final, %{state | history: [final | history]}}
  end


  defp done?({:error, error}, _name, _config, _history), do: error

  defp done?({:tool_call, call}, name, config, history) do
    result = execute call, name
    continue result, config, history, name
  end

  defp done?({:text, text}, name, config, history) do
    case parse_tool_call(text) do
      {:tool_call, call} -> done?({:tool_call, call}, name, config, history)
      _ -> text
    end
  end
  
  defp parse_tool_call(text) do
    case Regex.run(~r/```tool_code\n(\w+)\('?([^']*)'?\)\n```/, text) do
      [_, func_name, args] -> 
        {:tool_call, %{"name" => func_name, "args" => %{"key" => args}}}
      _ -> 
        case Regex.run(~r/```tool_code\n(\w+)\('?([^']*)'?,\s*'?([^']*)'?\)\n```/, text) do
          [_, func_name, key, value] -> 
            {:tool_call, %{"name" => func_name, "args" => %{"key" => key, "value" => value}}}
          _ -> nil
        end
    end
  end


  defp continue result, _config, _history, _name do
    "Tool executed: #{result["result"]}"
  end

end