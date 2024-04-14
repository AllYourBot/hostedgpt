module ExtendActiveRecord
  def last(*args)
    if to_sql.include?("DISTINCT ON")
      limit = args.first
      result = unscoped.from("(#{to_sql}) AS subq").select("subq.*").order(subq_position: :desc).limit(limit)

      limit ? result.reverse : result.first
    else
      super(*args)
    end
  end

  def count(*args)
    if to_sql.include?("DISTINCT ON")
      unscoped.from("(#{reorder(nil).to_sql}) AS subq").select("count(*)").to_a.first['count'].to_i
    else
      super(*args)
    end
  end
end

ActiveRecord::Relation.prepend(ExtendActiveRecord)