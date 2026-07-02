defmodule DoctorUnitTest do
  use Tester
  @moduletag :main
  @moduletag :spec

  setup do
    System.put_env("TAPE", "replay")
    System.put_env("CASSETTE", "doctor")

    on_exit(fn ->
      System.delete_env("TAPE")
      System.delete_env("CASSETTE")
    end)

    spawn(:doctor)
    spawn(:patient, :actor)
    :ok
  end

  test "doctor diagnoses appendicitis" do
    ask(:patient, """
    you are a patient with appendicitis
    - sharp right abdominal pain, nausea, fever.
    Improvise realistic details.
    """)

    verify(:doctor, "appendicitis", "diagnose patient")
  end
end
