defmodule DoctorTest do
  use Tester

  @moduletag :xunit

  setup do
    System.put_env("CASSETTE", "doctor_xunit")

    on_exit(fn ->
      System.delete_env("CASSETTE")
    end)

    spawn(:doctor)
    spawn(:patient, :actor)
    spawn(:judge)
    :ok
  end

  test "doctor diagnoses appendicitis" do

    ask(:patient, """
    you are a patient with appendicitis
    - sharp right abdominal pain, nausea, fever.
    Improvise realistic details.
    """)

    diagnosis = ask(:doctor, "diagnose patient")
    judge(diagnosis, "appendicitis is identified as the likely diagnosis")
  end

end
