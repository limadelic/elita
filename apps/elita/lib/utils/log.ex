defmodule Log do
  import IO, only: [puts: 1]
  import Path, only: [join: 2]
  import String, only: [contains?: 2, trim: 1]
  import System, only: [pid: 0, get_env: 2]
  import Utils.Yaml, only: [yaml: 1]
  import File, only: [mkdir_p!: 1, write: 3]

  @colors %{
    green: 82,
    white: 255,
    blue: 33,
    yellow: 226,
    red: 196
  }

  def log(emoji, head, neck, body, color) do
    msg = message(head, neck, yaml(body))
    emit(emoji, msg, color)
  rescue
    _ in [File.Error, ErlangError] -> :ok
  end

  defp emit(emoji, msg, color) do
    puts("\e[38;5;#{@colors[color]}m#{emoji} #{msg}\e[0m")
    dir() |> mkdir_p!() |> append("#{emoji} #{msg}")
  end

  defp message(head, neck, body) do
    "#{head}#{neck <> eol(body)}#{body}"
  end

  def write(message) do
    dir() |> mkdir_p!() |> ensure(message)
  rescue
    _ in [File.Error, ErlangError] -> :ok
  end

  defp ensure(_dir, message) do
    write(path("elita"), message, [:append])
    puts(message)
  end

  defp append(_dir, message) do
    write(path("elita"), message <> "\n", [:append])
  end

  defp eol(body) do
    body |> newline() |> char()
  end

  defp newline(body) do
    contains?(body, "\n")
  end

  defp char(true), do: "\n"
  defp char(false), do: ""

  defp path(name) do
    join(dir(), "#{name}_#{pid()}.log")
  end

  defp dir do
    join(get_env("HOME", "~"), ".elita/sessions")
  end

  def ask(sender, recipient, question) do
    write("🤔 #{sender} → #{recipient} | #{question}\n")
  end

  def answer(agent, text) when is_binary(text) do
    write("✨ #{agent} | #{trim(text)}\n")
  end

  def answer(_agent, _text), do: :ok
end
