Code.require_file("../../elita/test/support/tester.exs", __DIR__)
Application.ensure_all_started(:tape)

scratch_home = Path.join(System.tmp_dir!(), "freeq-test-#{System.pid()}")
File.mkdir_p!(scratch_home)
System.put_env("HOME", scratch_home)

ExUnit.start(exclude: [:freeq])
