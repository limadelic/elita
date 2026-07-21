module Home
  def setup_scratch_home
    root = File.expand_path("../../..", __FILE__)
    el_dir = File.join(root, "apps/el")
    system("cd #{el_dir} && mix escript.build") || raise("Failed to build el escript")

    tmp_dir = File.expand_path('../../tmp', __dir__)
    FileUtils.mkdir_p(tmp_dir)
    @scratch_home = Dir.mktmpdir('home', tmp_dir)
    ENV["HOME"] = @scratch_home
  end

  def setup_malko_scratch
    tmp_dir = File.expand_path('../../tmp', __dir__)
    FileUtils.mkdir_p(tmp_dir)
    @scratch = Dir.mktmpdir('scratch', tmp_dir)
    bin_dir = File.join(@scratch, 'bin')
    Dir.mkdir(bin_dir) unless Dir.exist?(bin_dir)
    copy_el_escript(bin_dir)
  end

  def copy_el_escript(bin_dir)
    el_link = File.join(bin_dir, 'el')
    return if File.exist?(el_link)

    el_escript = File.expand_path('../../apps/el/el', __dir__)
    raise "el escript not found at #{el_escript}" unless File.exist?(el_escript)

    FileUtils.cp(el_escript, el_link)
    File.chmod(0755, el_link)
  end

  def clean_malko_scratch
    FileUtils.rm_rf(@scratch) if @scratch && File.exist?(@scratch)
  end
end
