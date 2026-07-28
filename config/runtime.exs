import Config

config :matrix, :trace, System.get_env("EL_TRACE")
config :elita, :mlm_host, System.get_env("MLM_HOST", "localhost")
config :elita, :mlm_model, System.get_env("MLM_MODEL", "qwen3-fast")
config :elita, :llm, System.get_env("LLM", "lite")
config :el, :claude, System.get_env("CLAUDE")
