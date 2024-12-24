module Assistant::Slug
  extend ActiveSupport::Concern

  included do
    before_validation :set_default_slug
    before_save :clear_slug_on_delete
  end

  private

  def clear_slug_on_delete
    self.slug = nil if deleted_at_changed? && deleted_at_was.nil? && deleted_at.present?
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
