class Fly < SDK
  def change_db_swap(app:, swap:)
    app_name = app+"-db"
    if !swap.is_a?(Integer)
      puts "Expected an integer for swap such as 512 but it was '#{swap}'. Aborting."
      return
    end

    app_id = get_apps.select { |m| m.name == app_name }&.id
    if app_id.nil?
      puts "Could not find the app named #{app_name}. Aborting."
      return
    end

    machines = get_machines(app_name)
    if machines.length > 1
      puts "Expected only a single database machine under #{app_name} but found #{machines.length}. Aborting."
      return
    end

    machine = machines.first
    config = machine.config

    updated_config = patch_matchine(app_name, machine.id, config)
    config.init.swap_size_mb = swap

    puts "Updated machine id #{machine.id} on #{app_name} to #{swap}mb. It make take a minute for the machine to finish booting."
  end

  def get_apps
    get("https://api.machines.dev/v1/apps?org_slug=personal").apps
  end

  def get_machines(app_name)
    get("https://api.machines.dev/v1/apps/#{app_name}/machines")
  end

  def patch_machine(app_name, id, config)
    patch("https://api.machines.dev/v1/apps/#{app_name}/machines/#{id}").param(config: config)
  end

  private

  def bearer_token
    `fly auth token`
  end
end
