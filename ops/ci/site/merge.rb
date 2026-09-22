#!/usr/bin/env ruby

require 'fileutils'
require 'tmpdir'

module Merge
  def self.run
    artifact_id = artifact_id_to_merge
    return unless artifact_id

    download_and_merge(artifact_id)
  end

  def self.artifact_id_to_merge
    repo = ENV['GITHUB_REPOSITORY']
    cmd = artifact_query(repo)
    exec_gh(cmd)
  end

  def self.artifact_query(repo)
    "gh api repos/#{repo}/actions/artifacts --paginate --jq " \
    "'.artifacts[] | select(.name == \"github-pages\") | .id' | head -1"
  end

  def self.exec_gh(cmd)
    `#{cmd}`.chomp rescue nil
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
    cmd = "gh api #{url} -H \"Accept: application/zip\" > #{temp_dir}/artifact.zip"
    system(cmd)
    system("cd #{temp_dir} && unzip -q artifact.zip")
  end

  def self.merge_artifact(temp_dir)
    tar_file = "#{temp_dir}/artifact.tar"
    return unless File.exist?(tar_file)

    extract_tar(tar_file)
    copy_artifact_dir
  end

  def self.extract_tar(tar_file)
    system("tar xf #{tar_file} -C /tmp")
  end

  def self.copy_artifact_dir
    artifact_dir = '/tmp/artifact'
    return unless Dir.exist?(artifact_dir)

    dest = "#{ENV['GITHUB_WORKSPACE']}/site/"
    system("cp -r #{artifact_dir}/* #{dest} 2>/dev/null || true")
    puts 'Base merged from previous deploy'
  end
end

Merge.run if __FILE__ == $PROGRAM_NAME
