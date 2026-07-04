defmodule Agent.Router do
  import Elita, only: [call: 2, cast: 2]

  def route(name, :ask, message) do
    case Agent.Registry.lookup(name) do
      {:ok, {pid, _folder}} ->
        Agent.Session.ask(pid, message)

      {:error, :not_found} ->
        try do
          {:ok, call(name, message)}
        rescue
          _ -> {:error, :not_found}
        end
    end
  end

  def route(name, :tell, message) do
    case Agent.Registry.lookup(name) do
      {:ok, {pid, _folder}} ->
        Agent.Session.cast(pid, message)
        :ok

      {:error, :not_found} ->
        try do
          cast(name, message)
          :ok
        rescue
          _ -> {:error, :not_found}
        end
    end
  end
end
