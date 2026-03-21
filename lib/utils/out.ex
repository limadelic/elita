defmodule Out do
  @moduledoc false

  import IO, only: [write: 2]

  @key :elita_assist

  def assist(data) do
    bin = IO.chardata_to_string(data)

    case mode() do
      {:fd, f} ->
        :file.write(f, bin)

      :stdio ->
        write(:stdio, bin)
    end
  end

  def flush do
    case :persistent_term.get(@key, :unset) do
      :unset ->
        :ok

      {:fd, f} ->
        :file.sync(f)

      :stdio ->
        :ok
    end
  end

  defp mode do
    case :persistent_term.get(@key, :unset) do
      :unset ->
        m = open()
        :persistent_term.put(@key, m)
        m

      m ->
        m
    end
  end

  defp open do
    ["/dev/fd/1", "/dev/stdout"]
    |> Enum.find_value(fn path ->
      case :file.open(path, [:write, :binary, :raw]) do
        {:ok, f} -> {:fd, f}
        _ -> nil
      end
    end) || :stdio
  end
end
