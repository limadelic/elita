defmodule DoctorTest do
  use Tester

  @moduletag :xunit

  setup do
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
    verify("appendicitis", diagnosis)
  end
end
