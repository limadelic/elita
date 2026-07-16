defmodule DoctorTest do
  use Tester
  @moduletag :xunit

  test "doctor diagnoses appendicitis" do
    spawn(:doctor)
    spawn(:patient, :actor)

    ask(:patient, """
    you are a patient with appendicitis
    - sharp right abdominal pain, nausea, fever.
    Improvise realistic details.
    """)

    verify("appendicitis", ask(:doctor, "diagnose patient"))
  end
end
