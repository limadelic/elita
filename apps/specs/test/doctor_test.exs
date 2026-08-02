defmodule DoctorTest do
  use SpecHelper

  test "doctor diagnoses appendicitis" do
    spawn(:doctor)
    spawn(:patient, :actor)

    ask(:patient, """
    you are a patient with appendicitis
    - sharp right abdominal pain, nausea, fever.
    Improvise realistic details.
    """)

    diagnosis = ask(:doctor, "diagnose patient")
    verify("appendicitis", diagnosis)
  end
end
