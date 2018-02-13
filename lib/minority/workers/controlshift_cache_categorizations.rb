class ControlshiftCacheCategorizationsWorker
  include Sidekiq::Worker

  def perform(url)
    table = open(url, 'r:utf-8')
    csv = SmarterCSV.process(table, chunk_size: 25) do |lines|
      lines.each do |row|
        issue = issue_for_category row[:name]
        if issue.nil?
          Padrino.cache["CSL:category:issue:#{row[:id]}"] = -1
        else
          Padrino.cache["CSL:category:issue:#{row[:id]}"] = issue.id
        end
      end
    end
  end

  def issue_for_category(name)
    category = IssueCategory.where("name ILIKE ?", name).first
    if category.nil?
      issue_name = name
    else
      issue_name = "#{name} - inne"
    end
    return Issue.where("name ILIKE ?", issue_name).first
  end
end
