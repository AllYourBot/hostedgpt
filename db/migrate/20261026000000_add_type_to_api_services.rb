class AddTypeToAPIServices < ActiveRecord::Migration[8.1]
  def up
    add_column :api_services, :service_type, :string
    execute <<~SQL
      UPDATE api_services
      SET service_type = CASE
        WHEN url = 'https://api.search.brave.com/res/v1/' THEN 'Search'
        ELSE 'AI'
      END
    SQL
    change_column_null :api_services, :service_type, false
  end

  def down
    remove_column :api_services, :service_type
  end
end
