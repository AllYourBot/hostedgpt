class EncryptKeys < ActiveRecord::Migration[7.1]
  def up
    puts ""
    puts "### ERROR? #################################################"
    puts "### YOU SHOULD NOT RUN db:migrate INSTEAD RUN db:prepare ###"
    puts "############################################################"
    puts ""

    User.find_each do |user|
      Rails.logger.info "Encrypt keys for #{user.id}. Has openai_key: #{user.openai_key.present?}; has anthropic_key: #{user.anthropic_key.present?}"
      user.encrypt
      if !user.save
        Rails.logger.warn "Could not update user #{user.id}: #{user.errors.full_messages.join(',')}"
      else
        Rails.logger.info "Successfully updated user #{user.id}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new "Won't decrypt data"
  end
end
