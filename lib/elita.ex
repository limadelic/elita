defmodule Elita do
  use GenServer
  
  import AgentConfig, only: [config: 1]
  import Prompt, only: [prompt: 2]
  import Llm, only: [llm: 1]
  import Regex, only: [scan: 2]

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

    resp = llm prompt config, history
    final_resp = process_response resp, name
    
    {:reply, final_resp, %{state | history: [final_resp | history]}}
  end

  defp create_memory_table name do
    :ets.new table_name(name), [:set, :public, :named_table]
  end

  defp table_name name do
    :"memory_#{name}"
  end

  defp process_response resp, name do
    case parse_tool_calls resp do
      [] -> resp
      tool_calls ->
        results = execute_tool_calls tool_calls, name
        generate_response_with_results results, name
    end
  end

  defp parse_tool_calls resp do
    set_calls = scan ~r/set\((\w+),\s*"([^"]+)"\)/, resp
    get_calls = scan ~r/get\((\w+)\)/, resp
    
    set_ops = Enum.map set_calls, fn [_, key, value] -> {:set, key, value} end
    get_ops = Enum.map get_calls, fn [_, key] -> {:get, key} end
    
    set_ops ++ get_ops
  end

  defp execute_tool_calls tool_calls, name do
    table = table_name name
    Enum.map tool_calls, fn call -> execute_tool_call call, table end
  end

  defp execute_tool_call {:set, key, value}, table do
    :ets.insert table, {key, value}
    {:set, key, "stored"}
  end

  defp execute_tool_call {:get, key}, table do
    case :ets.lookup table, key do
      [{^key, value}] -> {:get, key, value}
      [] -> {:get, key, "not found"}
    end
  end

  defp generate_response_with_results results, name do
    tool_results = format_tool_results results
    config = config name
    history = ["Tool results: #{tool_results}"]
    
    llm prompt config, history
  end

  defp format_tool_results results do
    results
    |> Enum.map(&format_tool_result/1)
    |> Enum.join(", ")
  end

  defp format_tool_result({:set, key, "stored"}), do: "#{key} stored"
  defp format_tool_result({:get, key, value}), do: "#{key}: #{value}"

end