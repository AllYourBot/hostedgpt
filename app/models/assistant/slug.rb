module Assistant::Slug
  extend ActiveSupport::Concern

  included do
    before_validation :set_default_slug
    before_validation :clear_conflicting_deleted_assistant_slug
    validates :slug, uniqueness: { scope: :user_id, message: "has already been taken" }
  end

  private

  def clear_conflicting_deleted_assistant_slug
    return if slug.blank?
    return if !slug_changed?

    conflicting_assistant = user.assistants_including_deleted.where.not(deleted_at: nil).find_by(slug: slug)
    conflicting_assistant&.update_column(:slug, nil) if conflicting_assistant != self
  end

  def set_default_slug
    return if slug.present?
    return if name.blank?

    base_slug = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-$/, "")

    existing_base_slugs = user.assistants.where("slug LIKE ?", "#{base_slug}%").pluck(:slug)
    largest_slug_number = existing_base_slugs.map { |slug| slug.split("--").last.to_i }.max
    self.slug = if largest_slug_number.present?
      "#{base_slug}--#{largest_slug_number + 1}"
    elsif existing_base_slugs.any?
      "#{base_slug}--1"
    else
      base_slug
    end
  end
end
