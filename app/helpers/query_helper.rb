module QueryHelper
  include PhotoableHelper
  
  def results_column(record)
    @query = record      
    render :partial => 'query/results'      
  end
  
end
