class UpdateActiveStorageBlobsModifyServiceNames < ActiveRecord::Migration[7.1]
  def change
    execute <<-SQL
      -- update command for changing the value of public.active_storage_blobs.service_name to 'database' where service_name is 'local' or 'test'
      UPDATE active_storage_blobs
      SET service_name = 'database'
      WHERE service_name = 'local' OR service_name = 'test';

      UPDATE active_storage_blobs
      SET service_name = 'database_public'
      WHERE service_name = 'local_public';
    SQL
  end
end
