class String
  def to_b
    ActiveModel::Type::Boolean.new.cast(self)
  end
end

class NilClass
  def to_b
    nil
  end
end

class TrueClass
  def to_b
    true
  end
end

class FalseClass
  def to_b
    false
  end
end
