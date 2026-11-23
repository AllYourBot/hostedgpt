module ScheduledPrompt::Schedulable
  extend ActiveSupport::Concern

  included do
    attribute :time_zone, default: -> { Time.zone.name }

    scope :due, -> { where(enabled: true, next_run_at: ..Time.current).joins(:assistant).merge(Assistant.not_deleted) }

    validates :time_zone, inclusion: { in: -> _ { ActiveSupport::TimeZone.all.map(&:name) } }
    validate :schedule_is_recognized, if: -> { schedule.present? }

    before_save :schedule_next_run, if: -> { schedule_changed? || time_zone_changed? || enabled_changed? }
  end

  def cron
    parsed = Fugit.parse_cronish(schedule.to_s)
    zone = ActiveSupport::TimeZone[time_zone.to_s]
    return unless parsed && zone

    Fugit::Cron.parse("#{parsed.to_cron_s} #{zone.tzinfo.name}")
  end

  # Compare-and-set on next_run_at, so only one dispatcher wins each run.
  def claim!
    self.class.where(id:, next_run_at:).update_all(next_run_at: following_run_at, last_run_at: Time.current) == 1
  end

  private

  def following_run_at = cron.next_time.to_t

  def schedule_next_run
    self.next_run_at = enabled? ? following_run_at : nil
  end

  def schedule_is_recognized
    if (schedule_cron = cron).nil?
      errors.add(:schedule, "isn't a schedule we recognize")
    elsif schedule_cron.rough_frequency < 15.minutes
      errors.add(:schedule, "can't run more often than every 15 minutes")
    end
  end
end
