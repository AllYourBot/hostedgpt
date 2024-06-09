class RemoveAuthFromUsers < ActiveRecord::Migration[7.1]
  def up
    User.where.not(password_digest: nil).each do |user|
      credential = user.credentials.build(
        type: "PasswordCredential",
        password_digest: user.password_digest,
        last_authenticated_at: user.person.updated_at
      )
      credential.save(validate: false) # skips password verification
    end

    remove_column :users, :password_digest
    remove_column :users, :auth_uid # don't need to migrate these since the user will be logged out they'll just re-do google auth
  end

  def down
    add_column :users, :password_digest, :text
    add_column :users, :auth_uid, :text
  end
end
