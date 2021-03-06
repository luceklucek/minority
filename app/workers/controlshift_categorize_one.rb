class ControlshiftCategorizeOneWorker
  include Sidekiq::Worker
  
  def perform(row, retries=3)
    @row = row
    @retries = retries

    begin
      issue = ControlshiftIssueLink.find(row["category_id"]).issue
      logger.info("issue id mapping: CSL:category:issue:#{row["category_id"]} = #{issue.name}")

      action = Action.includes(:campaign).where(
        technical_type: 'cby_petition',
        external_id: row["petition_id"]).first
      logger.info("CSL petition action #{action.try(:name)}")
      return try_later if action.nil? or action.campaign.nil?

      action.campaign.issue = issue
      action.campaign.save!

    rescue ActiveRecord::RecordNotFound => e
      return try_later
    end
  end

  def try_later
    if @retries > 0
      ControlshiftCategorizeOneWorker.perform_in(5.minutes, @row, @retries - 1)
    end
  end
end
