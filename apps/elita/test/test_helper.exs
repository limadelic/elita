Code.require_file("support/tester.exs", __DIR__)
Application.ensure_all_started(:tape)

scratch_home = Path.join(System.tmp_dir!(), "elita-test-#{System.pid()}")
File.mkdir_p!(scratch_home)
System.put_env("HOME", scratch_home)

System.put_env(
  "PLAYWRIGHT_BROWSERS_PATH",
  Path.join(System.user_home!(), "Library/Caches/ms-playwright")
)

ExUnit.start(exclude: [:integration])
