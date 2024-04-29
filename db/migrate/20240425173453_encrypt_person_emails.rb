class EncryptPersonEmails < ActiveRecord::Migration[7.1]
  def up
    Person.find_each do |person|
      Rails.logger.info "Encrypt email for #{person.id}"
      person.encrypt
      if !person.save(validate: false)
        Rails.logger.warn "Could not update person #{person.id}: #{person.errors.full_messages.join(',')}"
      else
        Rails.logger.info "Successfully updated user #{person.id}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new "Won't decrypt data"
  end
end
