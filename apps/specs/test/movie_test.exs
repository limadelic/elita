defmodule MovieTest do
  use SpecHelper

  test "flushed movie survives in cassette" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    cassette_name = "movie_test"
    cassette_path = Path.join(cassette_dir, "#{cassette_name}.json")

    # Clean up any existing test cassette
    File.rm(cassette_path)

    # Set rec mode
    System.put_env("TAPE", "rec")
    System.put_env("CASSETTE", cassette_name)
    System.put_env("CASSETTE_DIR", cassette_dir)

    # Create a recorder
    rec_pid = Matrix.Movie.Record.start(nil, "test_movie")

    # Record some chunks
    Matrix.Movie.Record.record(rec_pid, "chunk1_data")
    Matrix.Movie.Record.record(rec_pid, "chunk2_data")

    # Done should flush to cassette
    Matrix.Movie.Record.done(rec_pid)

    # Verify the cassette file exists and contains the movie
    assert File.exists?(cassette_path)

    data = cassette_path |> File.read!() |> Jason.decode!()

    # Should have a movies key
    assert Map.has_key?(data, "movies")

    # Movie should be in the movies map
    movies = data["movies"]
    assert Map.has_key?(movies, "test_movie")

    # Chunks should be Base64 encoded list
    chunks = movies["test_movie"]
    assert is_list(chunks)
    assert length(chunks) == 2

    # Each chunk should be a string (Base64)
    Enum.each(chunks, &assert(is_binary(&1)))

    # Clean up
    System.put_env("TAPE", "replay")
    File.rm(cassette_path)
  end

  test "rec mode off does not flush" do
    cassette_dir = Path.expand("../../../features/cassettes", __DIR__)
    cassette_name = "movie_test_no_rec"
    cassette_path = Path.join(cassette_dir, "#{cassette_name}.json")

    # Clean up any existing test cassette
    File.rm(cassette_path)

    # Set replay mode
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", cassette_name)
    System.put_env("CASSETTE_DIR", cassette_dir)

    # active? should be false
    refute Matrix.Movie.Record.active?()

    # Recorder shouldn't be active anyway, but if it were, done should not flush
    # This is just to ensure the replays don't try to write
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

    # Receive first chunk
    assert_receive {^handle, {:data, chunk1}}, 1000
    assert chunk1 == "action!\n"

    # Receive second chunk
    assert_receive {^handle, {:data, chunk2}}, 1000

    # Receive close message
    assert_receive {^handle, :closed}, 1000
  end
end
