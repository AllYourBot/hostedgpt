class ScopeOauthGrantCredentialUniquenessToUser < ActiveRecord::Migration[8.1]
  # GoogleCredential, MicrosoftGraphCredential, and HttpHeaderCredential double as login
  # identities (a single external account must map to at most one User), so their
  # external_id/oauth_email uniqueness stays global across all users.
  #
  # GmailCredential and GoogleTasksCredential are pure API-access grants, not login
  # identities: nothing prevents the same Google account being connected for Gmail/Tasks
  # under two different HostedGPT users. Scoping their uniqueness to user_id fixes the
  # "Oauth has already been taken, Oauth email has already been taken" error users hit
  # when reconnecting Google Tasks/Gmail for an account whose credential row got
  # orphaned under an old/duplicate user record.
  LOGIN_TYPES = %w[GoogleCredential MicrosoftGraphCredential HttpHeaderCredential]
  EMAIL_LOGIN_TYPES = %w[GoogleCredential MicrosoftGraphCredential]
  GRANT_TYPES = %w[GmailCredential GoogleTasksCredential]

  def change
    remove_index :credentials, name: "index_credentials_on_type_and_external_id"
    remove_index :credentials, name: "index_credentials_on_type_and_oauth_email"

    add_index :credentials, [ :type, :external_id ], unique: true,
      where: "type IN (#{LOGIN_TYPES.map { |t| "'#{t}'" }.join(', ')})",
      name: "index_credentials_on_type_and_external_id"

    add_index :credentials, [ :type, :oauth_email ], unique: true,
      where: "type IN (#{EMAIL_LOGIN_TYPES.map { |t| "'#{t}'" }.join(', ')})",
      name: "index_credentials_on_type_and_oauth_email"

    add_index :credentials, [ :type, :user_id, :external_id ], unique: true,
      where: "type IN (#{GRANT_TYPES.map { |t| "'#{t}'" }.join(', ')})",
      name: "index_credentials_on_type_user_id_and_external_id"

    add_index :credentials, [ :type, :user_id, :oauth_email ], unique: true,
      where: "type IN (#{GRANT_TYPES.map { |t| "'#{t}'" }.join(', ')})",
      name: "index_credentials_on_type_user_id_and_oauth_email"
  end
end
