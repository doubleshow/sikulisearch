# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def show_spinner
    content_tag "div", "working ..." + image_tag("spinner.gif"), 
                :id => "ajax_busy", :style => "display:none;"
  end
end
