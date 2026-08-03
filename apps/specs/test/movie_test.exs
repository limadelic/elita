defmodule MovieTest do
  use SpecHelper

  test "flushed movie survives in cassette" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    cassette_name = "movie_test"
    cassette_path = Path.join(cassette_dir, "#{cassette_name}.json")

    File.rm(cassette_path)

    System.put_env("TAPE", "rec")
    System.put_env("CASSETTE", cassette_name)
    System.put_env("CASSETTE_DIR", cassette_dir)

    rec_pid = Matrix.Movie.Record.start(nil, "test_movie")

    Matrix.Movie.Record.record(rec_pid, "chunk1_data")
    Matrix.Movie.Record.record(rec_pid, "chunk2_data")

    Matrix.Movie.Record.done(rec_pid)

    assert File.exists?(cassette_path)

    data = cassette_path |> File.read!() |> Jason.decode!()

    assert Map.has_key?(data, "movies")

    movies = data["movies"]
    assert Map.has_key?(movies, "test_movie")

    chunks = movies["test_movie"]
    assert is_list(chunks)
    assert length(chunks) == 2

    Enum.each(chunks, &assert(is_binary(&1)))

    System.put_env("TAPE", "replay")
    File.rm(cassette_path)
  end

  test "rec mode off does not flush" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    cassette_name = "movie_test_no_rec"
    cassette_path = Path.join(cassette_dir, "#{cassette_name}.json")

    File.rm(cassette_path)

    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", cassette_name)
    System.put_env("CASSETTE_DIR", cassette_dir)

    refute Matrix.Movie.Record.active?()
  end

  test "loaded movie returns decoded chunks" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    System.put_env("CASSETTE", "claude")
    System.put_env("CASSETTE_DIR", cassette_dir)

    chunks = Matrix.Movie.Load.run("film")
    assert is_list(chunks)
    assert Enum.at(chunks, 0) == "action!\n"
  end

  test "play opens movie and sends chunks then closes" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    System.put_env("CASSETTE", "claude")
    System.put_env("CASSETTE_DIR", cassette_dir)

    handle = Matrix.Movie.Play.open("film", recipient: self())

    assert_receive {^handle, {:data, chunk1}}, 1000
    assert chunk1 == "action!\n"

    assert_receive {^handle, {:data, _chunk2}}, 1000

    assert_receive {^handle, :closed}, 1000
  end

  test "pty boots with movie port and taps receive film output" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    System.put_env("CASSETTE", "claude")
    System.put_env("CASSETTE_DIR", cassette_dir)

    pid =
      Matrix.Pty.launch(:movie_pty,
        port: Matrix.Movie.Play,
        taps: [self()],
        get_size: fn -> {24, 80} end
      )

    assert_receive {:output, chunk1}, 1000
    assert chunk1 == "action!\n"

    assert_receive {:output, _chunk2}, 1000

    GenServer.stop(pid)
  end

  test "pty auto-selects movie in replay when no port given" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "claude")
    System.put_env("CASSETTE_DIR", cassette_dir)

    pid =
      Matrix.Pty.launch(:film,
        name: :film,
        taps: [self()],
        get_size: fn -> {24, 80} end
      )

    assert_receive {:output, chunk1}, 1000
    assert chunk1 == "action!\n"

    GenServer.stop(pid)
  end
end
