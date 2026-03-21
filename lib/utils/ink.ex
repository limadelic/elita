defmodule Ink do
  @moduledoc false

  import IO, only: [write: 2]
  import MDEx, only: [parse_document!: 2]

  @bold "\e[1m"
  @dim "\e[2m"
  @italic "\e[3m"
  @underline "\e[4m"
  @strike "\e[9m"
  @reset "\e[0m"
  @cyan "\e[36m"
  @green "\e[32m"
  @yellow "\e[33m"
  @magenta "\e[35m"
  @white "\e[38;5;255m"
  @gray "\e[38;5;245m"
  @blue "\e[34m"

  @opts [extension: [table: true, strikethrough: true, tasklist: true]]

  def new, do: %{buf: "", fence: false}

  def feed(state, chunk) do
    raw = state.buf <> chunk
    {blocks, rest, fence} = split_blocks(raw, state.fence)

    for block <- blocks do
      write_md(block)
    end

    %{buf: rest, fence: fence}
  end

  def flush(%{buf: buf}) do
    if String.trim(buf) != "" do
      write_md(buf)
    end

    write(:stderr, @reset)
  end

  defp write_md(block) do
    try do
      write(:stderr, block |> parse() |> ansi())
    rescue
      e ->
        msg = Exception.message(e) |> to_string() |> String.slice(0, 120)

        write(
          :stderr,
          @dim <> @gray <> "[unrenderable markdown] " <> msg <> @reset <> "\n"
        )
    end
  end

  defp parse(md), do: parse_document!(md, @opts)

  # Split raw markdown into complete blocks (ready to render) and a leftover buffer.
  # A "block" is separated by blank lines (\n\n), except inside fenced code blocks.
  defp split_blocks(raw, fence) do
    split_blocks(raw, fence, [])
  end

  defp split_blocks("", fence, acc), do: {Enum.reverse(acc), "", fence}

  defp split_blocks(raw, true = _in_fence, acc) do
    case find_fence_close(raw) do
      {:ok, block, rest} ->
        split_blocks(rest, false, [block | acc])

      :none ->
        {Enum.reverse(acc), raw, true}
    end
  end

  defp split_blocks(raw, false, acc) do
    if fence_open?(raw) do
      split_blocks(raw, true, acc)
    else
      case split_at_blank(raw) do
        {:ok, block, rest} ->
          split_blocks(rest, false, [block | acc])

        :none ->
          {Enum.reverse(acc), raw, false}
      end
    end
  end

  defp fence_open?(raw), do: String.starts_with?(raw, "```")

  defp find_fence_close(raw) do
    case String.split(raw, "\n", parts: 2) do
      [first_line, rest] ->
        do_find_close(first_line <> "\n", rest)

      [_only] ->
        :none
    end
  end

  defp do_find_close(prefix, rest) do
    lines = String.split(rest, "\n")
    find_close_in(lines, prefix, [])
  end

  defp find_close_in([], _prefix, _acc), do: :none

  defp find_close_in([line | tail], prefix, acc) do
    if String.starts_with?(String.trim_leading(line), "```") do
      block = prefix <> Enum.join(Enum.reverse(acc), "\n") <> "\n" <> line <> "\n"
      rest = Enum.join(tail, "\n")
      {:ok, block, rest}
    else
      find_close_in(tail, prefix, [line | acc])
    end
  end

  defp split_at_blank(raw) do
    case :binary.match(raw, "\n\n") do
      {pos, 2} ->
        block = binary_part(raw, 0, pos + 1)
        rest = binary_part(raw, pos + 2, byte_size(raw) - pos - 2)
        {:ok, block, rest}

      :nomatch ->
        :none
    end
  end

  # --- AST to ANSI ---

  defp ansi(%MDEx.Document{nodes: ns}), do: nodes(ns)

  defp nodes(list), do: list |> Enum.map(&render/1) |> Enum.join()

  defp render(%MDEx.Heading{level: l, nodes: ch}) do
    @bold <> hcolor(l) <> nodes(ch) <> @reset <> "\n"
  end

  defp render(%MDEx.Paragraph{nodes: ch}) do
    @white <> nodes(ch) <> @reset <> "\n"
  end

  defp render(%MDEx.Strong{nodes: ch}), do: @bold <> nodes(ch) <> @reset <> @white
  defp render(%MDEx.Emph{nodes: ch}), do: @italic <> nodes(ch) <> @reset <> @white
  defp render(%MDEx.Strikethrough{nodes: ch}), do: @strike <> nodes(ch) <> @reset <> @white
  defp render(%MDEx.Code{literal: lit}), do: @cyan <> lit <> @reset <> @white

  defp render(%MDEx.CodeBlock{literal: lit, info: info}) do
    label = if info != "", do: " #{info}", else: ""
    body = lit |> String.trim_trailing("\n") |> indent_code()
    "\n" <> @dim <> @cyan <> "┌──" <> label <> @reset <> "\n" <>
      body <> "\n" <> @dim <> @cyan <> "└──" <> @reset <> "\n"
  end

  defp render(%MDEx.List{list_type: t, nodes: items, start: s}) do
    items
    |> Enum.with_index(s)
    |> Enum.map(fn {item, i} -> list_item(item, t, i) end)
    |> Enum.join()
  end

  defp render(%MDEx.ListItem{nodes: ch}), do: nodes(ch)

  defp render(%MDEx.BlockQuote{nodes: ch}) do
    body = nodes(ch) |> String.trim_trailing("\n")
    body
    |> String.split("\n")
    |> Enum.map_join("\n", &(@gray <> "│ " <> @white <> &1))
    |> Kernel.<>(@reset <> "\n")
  end

  defp render(%MDEx.ThematicBreak{}) do
    @dim <> @gray <> String.duplicate("─", 40) <> @reset <> "\n"
  end

  defp render(%MDEx.Table{nodes: rows}) do
    rendered = Enum.map(rows, &table_row/1)
    widths = col_widths(rendered)

    lines =
      rendered
      |> Enum.with_index()
      |> Enum.map(fn {cells, i} ->
        row =
          cells
          |> Enum.zip(widths)
          |> Enum.map_join(@gray <> " │ " <> @white, fn {c, w} ->
            vpad(c, w)
          end)

        line = @gray <> "│ " <> @white <> row <> @gray <> " │" <> @reset

        if i == 0 do
          sep = widths |> Enum.map_join("─┼─", &String.duplicate("─", &1))
          line <> "\n" <> @gray <> "├─" <> sep <> "─┤" <> @reset
        else
          line
        end
      end)

    top = widths |> Enum.map_join("─┬─", &String.duplicate("─", &1))
    bot = widths |> Enum.map_join("─┴─", &String.duplicate("─", &1))

    @gray <> "┌─" <> top <> "─┐" <> @reset <> "\n" <>
      Enum.join(lines, "\n") <> "\n" <>
      @gray <> "└─" <> bot <> "─┘" <> @reset <> "\n"
  end

  defp render(%MDEx.TableRow{nodes: cells}), do: Enum.map(cells, &render/1)
  defp render(%MDEx.TableCell{nodes: ch}), do: nodes(ch)

  defp render(%MDEx.Link{url: url, nodes: ch}) do
    @underline <> @blue <> nodes(ch) <> @reset <> @gray <> " (" <> url <> ")" <> @reset <> @white
  end

  defp render(%MDEx.Image{url: url, nodes: ch}) do
    @dim <> "[img: " <> nodes(ch) <> " " <> url <> "]" <> @reset
  end

  defp render(%MDEx.Text{literal: lit}), do: lit
  defp render(%MDEx.SoftBreak{}), do: "\n"
  defp render(%MDEx.LineBreak{}), do: "\n"
  defp render(%MDEx.HtmlInline{literal: lit}), do: lit

  defp render(%MDEx.HtmlBlock{literal: lit}) do
    if String.contains?(lit, "<!-- end list -->"), do: "", else: lit
  end

  defp render(%MDEx.ShortCode{emoji: e}) when e != "", do: e
  defp render(%MDEx.ShortCode{code: c}), do: ":#{c}:"
  defp render(_), do: ""

  # --- helpers ---

  defp hcolor(1), do: @magenta
  defp hcolor(2), do: @cyan
  defp hcolor(_), do: @yellow

  defp list_item(%MDEx.ListItem{nodes: ch}, :bullet, _) do
    body = nodes(ch) |> String.trim_trailing("\n")
    @green <> "  • " <> @white <> body <> @reset <> "\n"
  end

  defp list_item(%MDEx.ListItem{nodes: ch}, :ordered, i) do
    body = nodes(ch) |> String.trim_trailing("\n")
    @green <> "  #{i}. " <> @white <> body <> @reset <> "\n"
  end

  defp indent_code(code) do
    code
    |> String.split("\n")
    |> Enum.map_join("\n", &(@gray <> "│ " <> @yellow <> &1))
  end

  defp table_row(%MDEx.TableRow{nodes: cells}) do
    Enum.map(cells, fn %MDEx.TableCell{nodes: ch} -> nodes(ch) end)
  end

  defp col_widths(rows) do
    rows
    |> Enum.reduce([], fn cells, acc ->
      cells
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {cell, i}, a ->
        w = vlen(cell)
        if i < length(a), do: List.replace_at(a, i, max(Enum.at(a, i), w)), else: a ++ [w]
      end)
    end)
    |> Enum.map(&max(&1, 3))
  end

  @ansi_re ~r/\e\[[0-9;]*m/

  defp strip(s), do: Regex.replace(@ansi_re, s, "")

  defp vlen(s) do
    s |> strip() |> String.to_charlist() |> Enum.reduce(0, &(&2 + cwidth(&1)))
  end

  defp vpad(s, target) do
    gap = max(target - vlen(s), 0)
    s <> String.duplicate(" ", gap)
  end

  defp cwidth(cp) when cp >= 0x1F300 and cp <= 0x1FAFF, do: 2
  defp cwidth(cp) when cp >= 0x2600 and cp <= 0x27BF, do: 2
  defp cwidth(cp) when cp >= 0x1F600 and cp <= 0x1F64F, do: 2
  defp cwidth(cp) when cp >= 0x1F680 and cp <= 0x1F6FF, do: 2
  defp cwidth(cp) when cp >= 0x1F900 and cp <= 0x1F9FF, do: 2
  defp cwidth(cp) when cp >= 0x231A and cp <= 0x23F3, do: 2
  defp cwidth(cp) when cp >= 0x2300 and cp <= 0x23FF, do: 2
  defp cwidth(cp) when cp >= 0x2B50 and cp <= 0x2B55, do: 2
  defp cwidth(cp) when cp >= 0xFE00 and cp <= 0xFE0F, do: 0
  defp cwidth(cp) when cp >= 0x200D and cp <= 0x200D, do: 0
  defp cwidth(_), do: 1
end
