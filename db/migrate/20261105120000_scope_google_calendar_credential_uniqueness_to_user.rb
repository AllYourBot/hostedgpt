class ScopeGoogleCalendarCredentialUniquenessToUser < ActiveRecord::Migration[8.1]
  # GoogleCalendarCredential is an API-access grant like GmailCredential and GoogleTasksCredential,
  # so it joins their per-user uniqueness indexes (see ScopeOauthGrantCredentialUniquenessToUser).
  OLD_GRANT_TYPES = %w[GmailCredential GoogleTasksCredential]
  NEW_GRANT_TYPES = OLD_GRANT_TYPES + %w[GoogleCalendarCredential]

  def up = add_grant_indexes(NEW_GRANT_TYPES)

  def down = add_grant_indexes(OLD_GRANT_TYPES)

  private

  def add_grant_indexes(types)
    where = "type IN (#{types.map { "'#{it}'" }.join(', ')})"

    %i[external_id oauth_email].each do |column|
      name = "index_credentials_on_type_user_id_and_#{column}"
      remove_index :credentials, name: name
      add_index :credentials, [ :type, :user_id, column ], unique: true, where:, name:
    end
  end
end
