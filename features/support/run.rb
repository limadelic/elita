module Run
  def elita_run(instance_run = nil)
    [instance_run, ENV["ELITA_RUN"], "cukes"].find { |r| r.to_s != "" }
  end
end
