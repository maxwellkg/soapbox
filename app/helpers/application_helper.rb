module ApplicationHelper
  def standard_formatted_date(date)
    date.strftime("%d %B %Y")
  end
end
