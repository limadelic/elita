defmodule El.Pty.Dsr do
  def scan(data, rows, cols, buffer \\ "") do
    chunk = buffer <> data
    {response, remaining} = extract_query(chunk, rows, cols)
    {response, remaining}
  end

  defp extract_query(chunk, rows, cols) do
    case extract_dsr(chunk, rows, cols) do
      {response, remaining} when response != "" ->
        {response, remaining}

      _ ->
        extract_da(chunk, rows, cols)
    end
  end

  defp extract_dsr(chunk, rows, cols) do
    case String.split(chunk, "\e[6n", parts: 2) do
      [before, rest] ->
        response = "\e[#{rows};#{cols}R"
        {response, before <> rest}

      _ ->
        {"", chunk}
    end
  end

  defp extract_da(chunk, _rows, _cols) do
    case String.split(chunk, "\e[c", parts: 2) do
      [before, rest] ->
        response = "\e[?6c"
        {response, before <> rest}

      _ ->
        {"", chunk}
    end
  end
end
