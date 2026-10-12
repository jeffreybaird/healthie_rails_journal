# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "yaml"

RSpec.describe "StagingCompose" do
  let(:project_name) { "healthie-compose-spec-stg" }
  let(:project_directory) { Dir.mktmpdir("staging-compose-spec") }
  let(:deployment_directory) { File.expand_path("../../deploy", __dir__) }
  let(:synthetic_environment) do
    {
      "APP_SLUG" => project_name,
      "IMAGE" => "example.invalid/healthie:test",
      "DOMAIN" => "healthie-compose-spec.invalid",
      "DATABASE_PATH" => "/data/app.db",
      "SECRET_KEY_BASE" => "synthetic-compose-test-secret"
    }
  end
  let(:compose_result) { Open3.capture3(synthetic_environment, *compose_command) }

  before do
    %w[compose.yaml compose.staging.yaml].each do |filename|
      FileUtils.cp(File.join(deployment_directory, filename), project_directory)
    end
    FileUtils.cp(File.join(deployment_directory, "litestream.staging.yml"),
                 File.join(project_directory, "litestream.yml"))
    File.write(File.join(project_directory, ".env"),
               synthetic_environment.map { |key, value| "#{key}=#{value}\n" }.join)
  end

  after { FileUtils.remove_entry(project_directory) }

  it "renders a valid staging project containing the Rails deployment services" do
    expect(configuration.fetch("services").keys).to contain_exactly(
      "app_blue", "app_green", "migrate", "db_init", "litestream"
    )
  end

  it "uses its own data volume and copied Litestream configuration" do
    expect(configuration.dig("volumes", "app_data", "name")).to eq("#{project_name}_app_data")
    %w[db_init litestream].each do |service|
      expect_local_litestream_mount(service)
    end
  end

  it "replicates staging data to a local directory without a cloud replica" do
    litestream = YAML.safe_load_file(File.join(project_directory, "litestream.yml"))

    expect(litestream.fetch("dbs").first.fetch("replicas")).to eq(
      [{ "type" => "file", "path" => "/data/staging-replica" }]
    )
  end

  def compose_command
    [
      "docker", "compose", "--project-directory", project_directory,
      "--project-name", project_name, "--env-file", File.join(project_directory, ".env"),
      "--profile", "tools", "-f", File.join(project_directory, "compose.yaml"),
      "-f", File.join(project_directory, "compose.staging.yaml"), "config", "--format", "json"
    ]
  end

  def configuration
    output, errors, result = compose_result
    expect(result).to be_success, "Docker Compose configuration failed: #{errors}"
    JSON.parse(output)
  end

  def expect_local_litestream_mount(service)
    mounts = configuration.fetch("services").fetch(service).fetch("volumes")
    expect(mounts).to include(
      a_hash_including("source" => File.join(project_directory, "litestream.yml"),
                       "target" => "/etc/litestream.yml", "read_only" => true)
    )
  end
end
