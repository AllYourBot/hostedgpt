# == Schema Information
#
# Table name: tombstones
#
#  id         :bigint           not null, primary key
#  erected_at :datetime
#
class Tombstone < ApplicationRecord
  include Personable
end
