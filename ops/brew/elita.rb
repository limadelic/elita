class Elita < Formula
  desc "Agentic platform with el CLI"
  homepage "https://github.com/limadelic/elita"
  url "https://github.com/limadelic/elita/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "28338aa23f1dd299b6488d32e9785dff9440e8f7a575c6ff9ba5857b7a5ccf5d"
  license "MIT"

  depends_on "elixir"

  def install
    compile
    libexec.install "apps/el/el"
    pkgshare.install "apps/elita/agents"
    bin.install "ops/brew/el-node"
    wrap
  end

  service do
    run opt_bin / "el-node"
    environment_variables PATH: std_service_path_env
    keep_alive true
    log_path var / "log/elita.log"
    error_log_path var / "log/elita.log"
  end

  test do
    system bin / "el", "help"
  end

  private

  def compile
    ENV["MIX_ENV"] = "prod"
    ENV["MIX_HOME"] = buildpath / ".mix"
    ENV["HEX_HOME"] = buildpath / ".hex"
    system "mix", "local.hex", "--force"
    system "mix", "local.rebar", "--force"
    system "mix", "deps.get"
    system "mix", "build"
  end

  def wrap
    (bin / "el").write <<~SH
      #!/bin/bash
      export ELITA_HOME="#{pkgshare}"
      exec "#{libexec}/el" "$@"
    SH
    (bin / "el").chmod 0755
  end
end
