import Config

# :render — in-process markdown-to-ANSI rendering (default; works everywhere)
# :stdout — raw model bytes to fd 1; labels on fd 2 (for piping to external renderers)
# :silent — buffer then print once (no live typing)
config :elita, stream: :render

if Mix.env() == :test do
  config :elita, stream: :silent
end
