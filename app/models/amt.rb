require 'rubygems'
require 'rturk'
AWSAccessKey = '5Frkab8gi3wAwS7MIKeQNRBeVlNX0kbY9+mirMnt'
AWSAccessKeyId = 'AKIAJ4FM3PEEOXTPIEVQ'
SANDBOX = false

class AMT

  def self.xp_examples

    h = {}
    h[900] = "system properties remote"
    h[1050] = "internet protocols tcp ip properties"
    h[1066] = "power options properties schemes"
    h[1169] = "system properties automatic update"
    h[1186] = "display properties themes"
    h[1189] = "display properties appearance"
    h[1179] = "windows task manager performance"
    h[1187] = "date and time properties"
    h[1160] = "sound and audio devices properties"
    h[733] = "local area connection properties"
    h[639] = "accessibility options keyboard"
    h[709] = "system properties computer name"
    h[684] = "folder options"
    h

    
  end

  def self.xp_ids
    [900,1050,1066,1169,1189,1186,1179,684,709,639]
  end

  def self.mac_examples
    h = {}
    h[1250] = "mac universal access"
    h[1259] = "mac expose spaces"
    h[1265] = "mac international formats"
    h[1246] = "mac  speech recognition "
    h[1241] = "mac date and time zone"
    h[1240] = "mac date and time"
    h[1236] = "mac account"
    h[1223] = "mac desktop and screensaver"
    h[1197] = "mac system preferences"
    h[1200] = "mac appearance"
    h
  end

  def self.mac_ids
    mac_examples.keys
  end

  def self.create_all
    h = mac_examples
    mac_ids.each {|x| create_json(x,h[x])}
  end

  def self.submit_all
    mac_ids.each {|x| submit(x)}
  end

  def self.create_json(query_id,query_phrase)
    query = Query.find(query_id)
    photo_ids,votes = query.match

    json_localpath = "public/amt/c-#{query_id}.json"
    result = Result.new
    result.add_by_photo_ids(photo_ids[0..3]) 
    result.add_by_bing_web(query_phrase.split,4)
    result.add_by_bing_image(query_phrase.split,4)
    result.add_by_bing_garbage([query_phrase.split[0]],4)
    result.pages.shuffle!
    #result.pages.slice!(0,10)   
    result.save_exhibit(json_localpath)
  end

  def self.generate_comparison_tasks    
    amt_submit = lambda do |id|

      title = "Look at pairs of screenshots and answer if they are similar"
      props = {:Title=>title,
        :MaxAssignments=>10, :LifetimeInSeconds=>3600, 
        :Reward=>{:Amount=>0.10, :CurrencyCode=>"USD"}, 
        :Keywords=>"search, rating, english, easy", 
        :Description=>title,
        :RequesterAnnotation=>"amt_compare:mac1:#{id}",
        :AssignmentDurationInSeconds=>3600, :AutoApprovalDelayInSeconds=>3600*4, 
        :QualificationRequirement=>[{
                                      # Approval rate of greater than 90%
                                      :QualificationTypeId=>"000000000000000000L0", 
                                      :IntegerValue=>90, 
                                      :Comparator=>"GreaterThan", 
                                      :RequiredToPreview=>"false"
                                    }]
      }

      turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)
      page = RTurk::ExternalQuestionBuilder.build("http://poq.csail.mit.edu:3100/search/amt", :id => id)

      # Turkers will be directed to http://myapp.com/turkers/add_tags?item_id=1234&AssignmentId=abcd12345\
      p turk.create_hit(props, page)
    end

    examples = mac_examples
    ids = mac_ids
    
    h = examples
    ids.each {|x| 
#      create_json(x,h[x])
      amt_submit.call("c-#{x}")
    }    
#    xp_ids[0..1].


  end

  def self.generate_labeling_tasks
    #dataset = 'vista'
    #source = 'test/vista'
    #dataset = 'app'
    #source = 'test/app'
    dataset = 'xp'
    source = 'test/xp'

    amt_submit = lambda do |id|

      title = "Look at pairs of screenshots and answer if they are similar"
      props = {:Title=>title,
        :MaxAssignments=>1, :LifetimeInSeconds=>3600, 
        :Reward=>{:Amount=>0.10, :CurrencyCode=>"USD"}, 
        :Keywords=>"search, rating, english, easy", 
        :Description=>title,
        :RequesterAnnotation=>"amt_label:#{dataset}:#{id}",
        :AssignmentDurationInSeconds=>3600, :AutoApprovalDelayInSeconds=>3600*4, 
        :QualificationRequirement=>[{
                                      # Approval rate of greater than 90%
                                      :QualificationTypeId=>"000000000000000000L0", 
                                      :IntegerValue=>90, 
                                      :Comparator=>"GreaterThan", 
                                      :RequiredToPreview=>"false"
                                    }]
      }

      turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)
      page = RTurk::ExternalQuestionBuilder.build("http://poq.csail.mit.edu:3100/search/amt_label", :id => id)

      # Turkers will be directed to http://myapp.com/turkers/add_tags?item_id=1234&AssignmentId=abcd12345\
      p turk.create_hit(props, page)
    end

    # all mac query images
#    (1197..1267).each do |query_id|     

    Query.find_all_by_source(source).select do |query|
      query.match[0].size >= 10
    end.shuffle.slice(0,100).each_with_index do |query,i|
      num_matches = query.match[0].size
      puts "#{i+1} submit query  #{query.id} from #{query.source} with #{num_matches} matches"

      amt_submit.call(query.id)
    end

    true
  
  end


  def self.generate_ranking_tasks(submit=false)
   [1200,1197,1240,1241,1250].each do |query_id|
   # [1197].each do |query_id|
      generate_ranking_tasks_for_query(query_id,submit)
    end
  end

  def  self.bad_photos 
    [84928,41031,40940,85117,41919,85075,85030,85028]
  end

  def self.generate_ranking_tasks_for_query(query_id,submit=false)


    amt_submit = lambda do |id|

      props = {:Title=>"View search results and rate their usefulness", 
        :MaxAssignments=>1, :LifetimeInSeconds=>3600, 
        :Reward=>{:Amount=>0.10, :CurrencyCode=>"USD"}, 
        :Keywords=>"search, rating, english, easy", 
        :Description=>"View search results and rate their usefulness",
        :RequesterAnnotation=>"#{id}",
        :AssignmentDurationInSeconds=>3600, :AutoApprovalDelayInSeconds=>7200, 
        :QualificationRequirement=>[{
                                      # Approval rate of greater than 90%
                                      :QualificationTypeId=>"000000000000000000L0", 
                                      :IntegerValue=>90, 
                                      :Comparator=>"GreaterThan", 
                                      :RequiredToPreview=>"false"
                                    }]
      }

      turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)
      page = RTurk::ExternalQuestionBuilder.build("http://poq.csail.mit.edu:3100/search/amt", :id => id)

      # Turkers will be directed to http://myapp.com/turkers/add_tags?item_id=1234&AssignmentId=abcd12345\
      p turk.create_hit(props, page)
    end

    query = Query.find(query_id)

    photo_ids = query.result_ids

  
    json_files = (1..5).map do |x| 
      amt_id = "ranking-#{query_id}-#{x}"
      json_localpath = "public/amt/#{amt_id}.json"
      
      result = Result.new

      selected = photo_ids.shuffle[0..5]
      bad = bad_photos.shuffle[0..1]
      repeated = (bad+selected).shuffle[0..1]

      result.add_by_photo_ids(selected)
      result.add_by_photo_ids(bad) 
      result.add_by_photo_ids(repeated)             
  
      result.pages.shuffle!    
      result.save_exhibit(json_localpath)

      if submit
        amt_submit.call(amt_id)
      end
    end

    
  end


  def self.submit(query_id)

    require 'rubygems'



    props = {:Title=>"View search results and rate their usefulness", 
      :MaxAssignments=>10, :LifetimeInSeconds=>3600, 
      :Reward=>{:Amount=>0.10, :CurrencyCode=>"USD"}, 
      :Keywords=>"search, rating, english", 
      :Description=>"View search results and rate their usefulness",
      :RequesterAnnotation=>"Exp5-#{query_id}",
      :AssignmentDurationInSeconds=>3600, :AutoApprovalDelayInSeconds=>3600, 
      :QualificationRequirement=>[{
                                    # Approval rate of greater than 90%
                                    :QualificationTypeId=>"000000000000000000L0", 
                                    :IntegerValue=>90, 
                                    :Comparator=>"GreaterThan", 
                                    :RequiredToPreview=>"false"
                                  }]
    }

    @turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)
    page = RTurk::ExternalQuestionBuilder.build("http://poq.csail.mit.edu:3100/search/amt", :id => query_id)


    # Turkers will be directed to http://myapp.com/turkers/add_tags?item_id=1234&AssignmentId=abcd12345

    p @turk.create_hit(props, page)
    

  end


  def self.delete_all
    @turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)    

    @turk.searchHITs({:PageSize=>50, :sandbox=>SANDBOX})["SearchHITsResult"]["HIT"].each do |x|
      puts
      hit = @turk.getHIT(x)["HIT"]
      #p hit
      annotation = hit["RequesterAnnotation"]
      puts annotation

      if annotation.match(/Exp3/mi)
        p @turk.forceExpireHIT(x)
        p @turk.disposeHIT(x)
      end
    end

    true
  end


  def self.expire_all_hits
    @turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)    

    @turk.searchHITs(:SortProperty => 'CreationTime', :SortDirection => 'Descending', 
                     :PageSize => 5,:sandbox=>SANDBOX)["SearchHITsResult"]["HIT"].each do |x|
      puts
      hit = @turk.getHIT(x)["HIT"]
      p hit
      p hit["HITId"]
      p @turk.forceExpireHIT({"HITId" => hit["HITId"],:sandbox => SANDBOX}) 
    end

  end

  def self.annotation_pattern
    #/ranking/i
    #/label:\d/i
    #/vista/i
    #/app/i
    #/xp/i
    /comp/i
  end

  def self.each_hit(&block)
    pagesize = 10
    (1..3).each do |page|
    @turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)    
    @turk.searchHITs(:SortProperty => 'CreationTime',                     
                     :SortDirection => 'Descending', 
                     #                     :ResponseGroup => 'HITMinimal',#,HITAssignmentSummary',
                     :PageNumber => page,
                     :PageSize => pagesize,:sandbox=>SANDBOX)["SearchHITsResult"]["HIT"].each do |x|


      hit = @turk.getHIT(x)["HIT"]
      annotation = hit["RequesterAnnotation"]

      if annotation.match(annotation_pattern)
        puts "===================================================="
        puts "ANNO.: #{annotation},  HITId: #{hit["HITId"]}"
        yield(hit)
      end
    end
end
    true
  end
  
  def self.view_hits
    fields = ["HITStatus","HITReviewStatus","NumberofAssignmentsPending","NumberofAssignmentsCompleted"]
    each_hit do |hit|
      fields.each {|f|
        puts "#{f}: #{hit[f]}"
      }
    end
  end

  def self.dispose_hits
    each_hit do |hit|
      p @turk.disposeHIT({"HITId" => hit["HITId"],:sandbox => SANDBOX})          
    end
    true
  end

  def self.evaluate_labeling_tasks

    worker_history = {}
    image_ids = []

    all = []

    each_assignment do |assignment|

      checks = []

      h = {}

      good = 0

      each_qa(assignment) do |q,a|
        print "#{q}:#{a} "

        rank,type,photo_id = q.split('-')

        yesno = a.to_i
       
        if type == 'u'
          good += 1 if yesno == 1
        end

        if type == 'b'
          checks << (yesno == 0)
        end
        if type == 'g'
          checks << (yesno == 1)
          image_ids << photo_id
        end
        if h[photo_id]
           checks << (h[photo_id] == yesno)
        end
        h[photo_id] = yesno
      end
      
      workerId = assignment["WorkerId"]
      puts
      p good
      p checks
      all << good

      passed = checks.select {|x| x}.size >= 2

      worker_history[workerId] = (worker_history[workerId] || []) << passed
        
    end

    puts all.size
    p all


    bad_workers = []
    worker_history.each do |w,n|
      puts "worker: #{w}, history: #{n.join(' ')}"
      if n.select{|x|not x}.size > 3
        bad_workers << w
      end
    end

#    {:matches => all, :image_ids => image_ids, :bad_workers => bad_workers}
  end


  def self.evaluate_labeling_tasks

    worker_history = {}
    image_ids = []

    all = []

    each_assignment do |assignment|

      checks = []

      h = {}

      good = 0

      each_qa(assignment) do |q,a|
        print "#{q}:#{a} "

        rank,type,photo_id = q.split('-')

        yesno = a.to_i
       
        if type == 'u'
          good += 1 if yesno == 1
        end

        if type == 'b'
          checks << (yesno == 0)
        end
        if type == 'g'
          checks << (yesno == 1)
          image_ids << photo_id
        end
        if h[photo_id]
           checks << (h[photo_id] == yesno)
        end
        h[photo_id] = yesno
      end
      
      workerId = assignment["WorkerId"]
      puts
      p good
      p checks
      all << good

      passed = checks.select {|x| x}.size >= 2

      worker_history[workerId] = (worker_history[workerId] || []) << passed
        
    end

    puts all.size
    p all


    bad_workers = []
    worker_history.each do |w,n|
      puts "worker: #{w}, history: #{n.join(' ')}"
      if n.select{|x|not x}.size > 3
        bad_workers << w
      end
    end

    {:matches => all, :image_ids => image_ids, :bad_workers => bad_workers}
  end


  def self.evaluate_comparison_tasks

    worker_history = {}

    type_scores = {}
    type_scores["BingImagePage"] = []
    type_scores["BingWebPage"] = []
    type_scores["PdfPage"] = []
    type_scores["WebPage"] = []

    each_assignment do |assignment|

      checks = []

      scores = []

      each_qa(assignment) do |q,a|
        print "#{q}:#{a} "

        rank,type,photo_id = q.split(':')

        score = a.to_i

        if type == "GarbagePage"
          checks << (score <= 2)
        elsif type
          scores << [type,score]
        end
        
      end
      
      workerId = assignment["WorkerId"]
      puts
      puts checks

      is_good = checks.select {|x| x}.size >= 2

      worker_history[workerId] = (worker_history[workerId] || []) << is_good

      # add scores if this assignment is determined to be good
      if is_good
        scores.each do |type,score|
          type_scores[type] << score
        end
      end
        
    end

    ta = worker_history.values.flatten
    puts "total answers: #{ta.size}"
    puts "valid answers: #{ta.select{|x|x}.size}"

    bad_workers = []
    good_workers = []
    worker_history.each do |w,n|
      puts "worker: #{w}, history: #{n.join(' ')}"
      if n.select{|x|not x}.size > (n.size/2)
        bad_workers << w
      else
        good_workers << w
      end
    end

    puts "good workers: #{good_workers.size}"
    puts "bad workers: #{bad_workers.size}"


    type_scores["PdfPage"] += type_scores["WebPage"]
    type_scores.each do |t,s|
      #puts "#{t}: #{s.join(' ')}"
      puts "#{t}: #{s.size} : #{s.sum.to_f/s.size}"
    end

    type_scores.each do |t,s|
      puts "#{t} = [#{s.join(' ')}]"
    end

    bad_workers

    do_approve = false
    if do_approve
      each_assignment do |assignment|

        if assignment["AssignmentStatus"] != 'Submitted'
          next
        end

        workerId = assignment["WorkerId"]
        if bad_workers.include? workerId
          puts "disapprove #{workerId}'s work"
          p @turk.rejectAssignment(:AssignmentId => assignment["AssignmentId"], 
             :RequesterFeedback => 'did not pass validation')
        else
          puts "approve #{workerId}'s work"
          p @turk.approveAssignment(:AssignmentId => assignment["AssignmentId"])
        end

      end

    end
  end

  
  def self.find_bad_workers

    worker_history = {}




    each_assignment do |assignment|

      checks = []

      scores = {}

      each_qa(assignment) do |q,a|
        print "#{q}:#{a} "

        rank,type,photo_id = q.split(':')

        score = a.to_i

        if bad_photos.include? photo_id.to_i
          checks << (score < 2)
        end                
        if scores[photo_id]
          checks << ((scores[photo_id]-score).abs <= 1)
        end
        scores[photo_id] = score
      end
      
      workerId = assignment["WorkerId"]
#      puts checks

      good = checks.select {|x| x}.size >= 3

      worker_history[workerId] = (worker_history[workerId] || []) << good
        
    end

    bad_workers = []
    worker_history.each do |w,n|
      puts "worker: #{w}, history: #{n.join(' ')}"
      if n.select{|x|not x}.size > 3
        bad_workers << w
      end
    end

    bad_workers
  end

  def self.export_approved_assignments

    orders = []    

    each_assignment do |assignment|
   
      if assignment["AssignmentStatus"] != 'Approved'
        next
      end
      
      scores = {}
      pairs = []
      each_qa(assignment) do |q,a|

        rank,type,photo_id = q.split(':')

        score = a.to_i

#        if bad_photos.include? photo_id.to_i
#          next
#        end                

          
        if scores[photo_id]
          next
        end

        pairs << [photo_id,score]

        puts "#{photo_id} #{score}"

      end

      pairs.sort!{|x,y| y[1]<=>x[1]}
      
#      top = p]

      p = pairs
      for i in (0..p.size-1)
        for j in (i..p.size-1)
          if p[i][1] > p[j][1]
            orders << [p[i][0],p[j][0]]
          end
        end
      end

      p orders
    end

    orders
  end

        



  def self.approve_assignments

#    bad_workers = find_bad_workers
    bad_workers = find_bad_workers_for_labeling_tasks

    each_assignment do |assignment|
      
      if assignment["AssignmentStatus"] != 'Submitted'
        next
      end

      workerId = assignment["WorkerId"]
      if bad_workers.include? workerId
        puts "disapprove #{workerId}'s work"
        p @turk.rejectAssignment(:AssignmentId => assignment["AssignmentId"], 
                                 :RequesterFeedback => 'did not pass validation')
      else
        puts "approve #{workerId}'s work"
        p @turk.approveAssignment(:AssignmentId => assignment["AssignmentId"])
      end
    end
  end

  def self.view_assignments

    each_assignment do |assignment|

      fields = ["AssignmentStatus","WorkerId"]
      fields.each do |f|
        puts "#{f}: #{assignment[f]}"        
      end    


      each_qa(assignment) do |q,a|
        print "#{q}:#{a} "
      end
      puts
    end

  end

  def self.each_assignment(&block)
   
    each_hit do |hit|
      
      result =  @turk.getAssignmentsForHIT("HITId" => hit["HITId"], :sandbox => SANDBOX)["GetAssignmentsForHITResult"]     

      if result["TotalNumResults"].to_i == 0
        next
      end
     
      [result["Assignment"]].flatten.each do |assignment|

        puts "---------------------------------"# #{assignment["AssignmentId"]} -----"
        yield(assignment)

        end
    end
  end


  def self.each_qa(assignment,&block)

    answer_text = assignment["Answer"]
    
    pat = /<QuestionIdentifier>(.*?)<\/QuestionIdentifier>.<FreeText>(.*?)<\/FreeText>/m
    answer_text.scan(pat).each do |qid,txt|
      
      if qid == 'Submit'
        next
      end

      yield(qid,txt)

    end
    
  end

  def self.check_status


    responses = []

    @turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)    

    #@turk.getReviewableHITs({:status => 'Reviewing', :sandbox=>SANDBOX})["GetReviewableHITsResult"]["HIT"].each do |x|

    @turk.searchHITs(:SortProperty => 'CreationTime', :SortDirection => 'Descending', :PageNumber => 1,
                     :PageSize => 20,:sandbox=>SANDBOX)["SearchHITsResult"]["HIT"].each do |x|
      puts
      hit = @turk.getHIT(x)["HIT"]
      #p hit
      annotation = hit["RequesterAnnotation"]
      puts annotation

 
      # x = {"HITId"=>"XBCZVKYSSJ2ZXX14XS30"}
      result =  @turk.getAssignmentsForHIT(x.merge({:sandbox => SANDBOX}))["GetAssignmentsForHITResult"]     

      if result["TotalNumResults"].to_i == 0
        next
      end
     


      [result["Assignment"]].flatten.each do |assignment|

        
        answer_text = assignment["Answer"]

        puts "#{assignment["WorkerId"]}"
        if assignment["WorkerId"] == 'AF2FJ0STR5AH6'
          p @turk.rejectAssignment(:AssignmentId => assignment["AssignmentId"], 
                                   :RequesterFeedback => 'did not pass validation')
          next
        else
          p @turk.approveAssignment(:AssignmentId => assignment["AssignmentId"])
        end
          

        pat = /<QuestionIdentifier>(.*?)<\/QuestionIdentifier>.<FreeText>(.*?)<\/FreeText>/m
        answers =  []
        answer_text.scan(pat).each { |qid,txt|
          
          if qid == 'Submit'
            next
          end

          rank,type = qid.split(':')
          score = txt.to_i
          answers << {:rank => rank, :type => type, :score => score}

          puts "#{qid} => #{txt}"
        }

        responses << {"Assignment" => assignment, :answers => answers, :annotation => annotation}
        
      end

#   @turk.disposeHIT(x)
    end
    true
  end
  
  def self.review


    responses = []

    @turk = RTurk::Requester.new(AWSAccessKeyId, AWSAccessKey, :sandbox => SANDBOX)    

    #@turk.getReviewableHITs({:status => 'Reviewing', :sandbox=>SANDBOX})["GetReviewableHITsResult"]["HIT"].each do |x|

    @turk.searchHITs(:SortProperty => 'CreationTime', :SortDirection => 'Descending', 
                     :PageSize => 20,:sandbox=>SANDBOX)["SearchHITsResult"]["HIT"].each do |x|
      puts
      hit = @turk.getHIT(x)["HIT"]
      #p hit
      annotation = hit["RequesterAnnotation"]
      puts annotation

 

      if not annotation.match(/Exp4/mi)
        next
      end

      # x = {"HITId"=>"XBCZVKYSSJ2ZXX14XS30"}
      result =  @turk.getAssignmentsForHIT(x.merge({:sandbox => SANDBOX}))["GetAssignmentsForHITResult"]     

      if result["TotalNumResults"].to_i == 0
        next
      end
     

      [result["Assignment"]].flatten.each do |assignment|
        
        answer_text = assignment["Answer"]


        pat = /<QuestionIdentifier>(.*?)<\/QuestionIdentifier>.<FreeText>(.*?)<\/FreeText>/m
        answers =  []
        answer_text.scan(pat).each { |qid,txt|
          
          if qid == 'Submit'
            next
          end

          rank,type = qid.split(':')
          score = txt.to_i
          answers << {:rank => rank, :type => type, :score => score}
        }

        responses << {"Assignment" => assignment, :answers => answers, :annotation => annotation}
        
      end

#   @turk.disposeHIT(x)
    end

    count = {}

    ['PdfPage','WebPage','BingWebPage','BingImagePage','GarbagePage'].each {|x| count[x] = []}



    # validate collected responses
    valid_responses = responses.select do |r|
      answers = r[:answers]

      # check for bad answers
      bad_answers = answers.select do |answer|
        answer[:type] == 'GarbagePage' and answer[:score] > 2
      end

      status = r["Assignment"]["AssignmentStatus"]
      assignmentId = r["Assignment"]["AssignmentId"]

      #p status
      
      bad =  bad_answers.size > 2

      puts "Response to #{r[:annotation]} from Worker #{r["Assignment"]["WorkerId"]} is #{bad ? 'bad' : 'good'}!"  

      if status == "Submitted"
        if bad 
          p @turk.rejectAssignment(:AssignmentId => assignmentId, 
                                   :RequesterFeedback => 'did not pass validation')
        else 
          puts "Approve assignment #{r["Assignment"]["AssignmentId"]}"
          p @turk.approveAssignment(:AssignmentId => assignmentId)
        end
      end

      not bad
    end


    valid_responses.each do |r|
      r[:answers].each do |a|
        count[a[:type]] << a[:score]
      end
    end   

    puts "\n\n====================================================="
    puts "Summary:"
    puts "Responses (valid/total): #{valid_responses.size} / #{responses.size}"

    count.each do |type,score|
      puts "#{type} :#{"%0.3f" % (score.sum.to_f / score.size)}"
    end
    
    true
  end

end
