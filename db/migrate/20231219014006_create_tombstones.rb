class CreateTombstones < ActiveRecord::Migration[7.1]
  def change
    create_table :tombstones do |t|
      t.datetime :erected_at
    end
  end
end
