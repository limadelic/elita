defmodule DoctorTest do
  use ExUnit.Case
  import ElitaTester

  setup do
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
