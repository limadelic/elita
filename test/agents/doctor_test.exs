defmodule DoctorTest do
  use ExUnit.Case
  import ElitaTester

  test "doctor diagnoses appendicitis" do
    start(:doctor)
    start(:actor, :patient)

    tell(:patient, """
    play a patient with appendicitis
    - sharp right abdominal pain, nausea, fever.
    Improvise realistic details.
    """)

    verify(:doctor, "appendicitis", "diagnose patient")
  end

end
