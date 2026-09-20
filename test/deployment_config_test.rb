require "test_helper"
require "yaml"

class DeploymentConfigTest < ActiveSupport::TestCase
  test "deploy.yml uses the current HOSTED_DB_* env family" do
    config = YAML.load_file(Rails.root.join("config/deploy.yml"))
    clear = config.dig("env", "clear")

    assert clear["HOSTED_DB_HOST"], "the HOSTED_DB_* env family must be present"
    assert clear["HOSTED_DB_USERNAME"], "the HOSTED_DB_* env family must be present"
    assert clear["HOSTED_DB_NAME"], "the HOSTED_DB_* env family must be present"
    assert_not_includes File.read(Rails.root.join("config/deploy.yml")), "HOSTEDGPT_",
      "config/deploy.yml must not reference the deprecated HOSTEDGPT_* env family"
  end

  test "deploy.yml accessory publishes no database port by any mechanism" do
    config = YAML.load_file(Rails.root.join("config/deploy.yml"))
    accessory = config.dig("accessories", "db")

    assert accessory, "the db accessory must be declared"
    assert_nil accessory["port"], "the Postgres accessory must not publish a host port"
    assert_nil accessory["ports"], "the Postgres accessory must not publish host ports"
    assert_not accessory["options"].to_s.match?(/publish|ports/),
      "the Postgres accessory must not publish ports via docker options either"
  end

  test "deploy.yml accessory hostname matches Kamal's container-name rule" do
    config = YAML.load_file(Rails.root.join("config/deploy.yml"))
    service = config["service"]
    assert config.key?("accessories"), "the db accessory must be declared for HOSTED_DB_HOST to resolve"

    # Kamal sets no network aliases: an accessory resolves by its container
    # name, which is "<service>-<accessory name>".
    config["accessories"].each do |name, _|
      assert_equal "#{service}-#{name}", config.dig("env", "clear", "HOSTED_DB_HOST"),
        "HOSTED_DB_HOST must be the accessory's container name (Kamal sets no network aliases)"
    end
  end

  test "app port agrees across deploy.yml and the Dockerfile stage" do
    config = YAML.load_file(Rails.root.join("config/deploy.yml"))
    app_port = config.dig("proxy", "app_port")

    assert_equal app_port, config.dig("env", "clear", "PORT"),
      "the app container's PORT must match proxy.app_port or the healthcheck fails"
    dockerfile_env_port = File.read(Rails.root.join("Dockerfile"))
      .lines.grep(/^ENV PORT=/).first
    assert_equal "PORT=#{app_port}", dockerfile_env_port&.strip&.delete_prefix("ENV "),
      "the kamal-production stage's ENV PORT must match proxy.app_port"
  end

  test "builder target names a real Dockerfile stage, with kamal-production after fly-production and render-production last" do
    config = YAML.load_file(Rails.root.join("config/deploy.yml"))
    stages = File.read(Rails.root.join("Dockerfile"))
      .lines.grep(/^FROM /)
    stage_names = stages.map { |line| line.split(/ as /i).last.strip }
    parents = stages.to_h { |line|
      _, parent, name = line.match(/^FROM\s+(\S+)\s+AS\s+(\S+)/).to_a
      [name, parent]
    }.compact

    target = config.dig("builder", "target")
    assert_includes stage_names, target,
      "builder.target must name a Dockerfile stage that exists"
    assert_equal "fly-production", parents["kamal-production"],
      "kamal-production must be a child of fly-production or it loses the built gems, app code, user, and ENTRYPOINT"
    assert stage_names.index("kamal-production") > stage_names.index("fly-production"),
      "kamal-production must come after fly-production"
    assert_equal "render-production", stage_names.last,
      "render-production must remain the final Dockerfile stage (Render builds the last stage)"
  end

  test "docker-entrypoint uses a POSIX-compatible equality test for the server branch" do
    content = File.read(Rails.root.join("bin/docker-entrypoint"))
    assert_match(/\[\s+"\$\{2\}"\s+=\s+"server"\s+\]/, content,
      "the server-arg test must use `=` (dash, the production base image's /bin/sh, rejects `==`, which silently skips db:prepare)")
    assert_not content.match?(/==\s+"server"/),
      "no branch may test the server arg with == (dash rejects it)"
  end

  test "dockerignore excludes the kamal secrets directory" do
    active_lines = File.read(Rails.root.join(".dockerignore"))
      .lines.map(&:strip).reject { |line| line.empty? || line.start_with?("#") }

    assert_includes active_lines, "/.kamal",
      ".kamal/secrets must never enter a Docker build context"
  end

  test "production keeps force_ssl with the /up health-check redirect exemption" do
    active_lines = File.read(Rails.root.join("config/environments/production.rb"))
      .lines.map(&:strip).reject { |line| line.empty? || line.start_with?("#") }

    assert_includes active_lines, "config.force_ssl = true"
    assert_includes active_lines,
      'config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }',
      "the /up exemption must be active (uncommented) so kamal-proxy's healthcheck succeeds over HTTP"
  end

  test "kamal secrets file is not tracked" do
    tracked = `git ls-files .kamal`.strip
    assert_empty tracked, ".kamal/secrets holds deployment secrets and must never be committed"
  end
end
