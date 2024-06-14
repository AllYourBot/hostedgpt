class String
  def to_b
    ActiveModel::Type::Boolean.new.cast(self)
  end
end
