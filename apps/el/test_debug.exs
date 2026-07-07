base = File.cwd!() <> "/tmp_test"
File.mkdir_p!(base)

bare_folder = Path.expand(Path.join(base, "agent1"))
sub_folder = Path.expand(Path.join(base, "sub"))
File.mkdir_p!(bare_folder)
File.mkdir_p!(sub_folder)

File.cd!(base)

registrations = "agent1:#{bare_folder},agent3:#{sub_folder}"
System.put_env("AGENT_REGISTRATIONS", registrations)

result = capture_io(fn -> El.Commands.Ask.execute("*@/**", "msg") end)
IO.puts("Result for *@/**:")
IO.inspect(result)

File.rm_rf!(base)
