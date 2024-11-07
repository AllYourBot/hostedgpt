class Fly < SDK
  def change_db_swap(app:, swap:)
    app_name = app+"-db"
    unless swap.is_a?(Integer) || swap.to_i.to_s == swap.to_s
      puts "Expected an integer for swap such as 512 but it was '#{swap}'. Aborting."
      return
    end
    swap = swap.to_i

    apps = get_apps
    app_id = apps.find { |m| m.name == app_name }&.id
    if app_id.nil?
      puts "Could not find the app named #{app_name}. Aborting."
      puts "These are all the app names on your Fly account: #{apps.map(&:name).join(", ")}"
      return
    end

    machines = get_machines(app_name)
    if machines.length > 1
      puts "Expected only a single database machine under #{app_name} but found #{machines.length}. Aborting."
      return
    end

    machine = machines.first
    config = machine.config.to_h
    config[:init] ||= {}
    config[:init][:swap_size_mb] = swap

    updated_config = patch_machine(app_name, machine.id, config)

    puts "Updated machine id #{machine.id} on #{app_name} to #{swap}mb. It make take a minute for the machine to finish booting."
  end

  def get_apps
    get("https://api.machines.dev/v1/apps").param(org_slug: "personal").apps
  end

  def get_machines(app_name)
    get("https://api.machines.dev/v1/apps/#{app_name}/machines").no_params
  end

  def patch_machine(app_name, id, config)
    post("https://api.machines.dev/v1/apps/#{app_name}/machines/#{id}").param(config: config)
  end

  private

  def bearer_token
    @bearer_token ||= `fly auth token`.chop.split.last
  end

  def header
    { content_type: "application/json" }
  end
end
