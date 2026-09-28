#!/usr/bin/env ruby

require 'fileutils'
require 'tmpdir'

module Merge
  def self.run
    artifact_id = artifact_id_to_merge
    return if artifact_id.to_s.empty?

    download_and_merge(artifact_id)
  end

  def self.artifact_id_to_merge
    repo = ENV['GITHUB_REPOSITORY']
    cmd = artifact_query(repo)
    output = `#{cmd}`.chomp rescue ''
    skip_error_response(output)
  end

  def self.skip_error_response(output)
    output.start_with?('{') ? '' : output
  end

  def self.artifact_query(repo)
    base = "gh api \"repos/#{repo}/actions/artifacts"
    query = "?name=github-pages&per_page=100\" --jq"
    select = "'.artifacts | map(select(.expired | not))"
    "#{base}#{query} #{select} | max_by(.created_at) | .id // empty'"
  end

  def self.download_and_merge(artifact_id)
    temp_dir = Dir.mktmpdir
    download_artifact(artifact_id, temp_dir)
    merge_artifact(temp_dir)
    FileUtils.rm_rf(temp_dir)
  end

  def self.download_artifact(artifact_id, temp_dir)
    repo = ENV['GITHUB_REPOSITORY']
    url = "repos/#{repo}/actions/artifacts/#{artifact_id}/zip"
    cmd = "gh api #{url} > #{temp_dir}/artifact.zip"
    system(cmd) || abort('merge download failed')
    unzip_artifact(temp_dir)
  end

  def self.unzip_artifact(temp_dir)
    cmd = "cd #{temp_dir} && unzip -q artifact.zip"
    system(cmd) || abort('merge unzip failed')
  end

  def self.merge_artifact(temp_dir)
    tar_file = "#{temp_dir}/artifact.tar"
    abort('merge found no artifact.tar') unless File.exist?(tar_file)
    extract_tar(tar_file, temp_dir)
    copy_artifact_dir(temp_dir)
  end

  def self.extract_tar(tar_file, temp_dir)
    tree_dir = "#{temp_dir}/tree"
    FileUtils.mkdir_p(tree_dir)
    cmd = "tar xf #{tar_file} -C #{tree_dir}"
    system(cmd) || abort('merge extract failed')
  end

  def self.copy_artifact_dir(temp_dir)
    source = "#{temp_dir}/tree"
    abort('merge copy failed') unless Dir.exist?(source)
    copy_tree(source)
    puts 'Base merged from previous deploy'
  end

  def self.copy_tree(source)
    dest = "#{ENV['GITHUB_WORKSPACE']}/site/"
    system("cp -R #{source}/. #{dest}") || abort('merge copy failed')
  end
end

Merge.run if __FILE__ == $PROGRAM_NAME
