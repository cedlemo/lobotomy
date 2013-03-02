module Lobotomy
    require 'lobotomy/colored'

  ##
  #Read data from a formated file and create an array
  def self.list_to_array(filename, column_separator, column_sub_separator = nil)
    list_in_array = Array.new
    full_filename = File.expand_path(filename)

    if !File.exist?(full_filename)
      puts "check file name"

    else    
      File.open(full_filename) do | file |
        file.each_line do | line |
          #don't read line starting with "#" which are comments lines
          unless line.match(/^#/)
            #remove spaces at begining and end of the line
            line.match(/^\s*(.*)\s*$/)
            array_definition = $1
            unless array_definition == nil
              columns = Array.new
              buff = array_definition.chomp.split(column_separator)
              #replace each possible nil value by empty string ""
              unless column_sub_separator == nil
                buff.each do | column |
                
                  if column.match(/#{column_sub_separator}/)
                    columns.push(column.split(column_sub_separator))
                  else
                    columns.push(column)
                  end
                end
                list_in_array.push(columns)
              else
                list_in_array.push(buff)
              end
            end  
          end
        end
      end
    end

    return list_in_array
  end
  #Read data from a formated file and create an array of hash with symbols
  def self.list_to_hash(filename, symbols, column_separator, column_sub_separator = nil)

    list_in_array = Lobotomy::list_to_array(filename, column_separator, column_sub_separator )
    list_in_array_of_symbols = Array.new
    
    list_in_array.each do | entry |
      an_hash = Hash.new
      if entry.length < symbols.length      
        i = 0
        entry.each do | element |
          an_hash[symbols[i]] = element
          i+=1
        end
        for i in ( entry.length )..( symbols.length - 1 )
          an_hash[symbols[i]] = ""
        end
      elsif entry.length == symbols.length
        i = 0
        entry.each do | element |
          an_hash[symbols[i]] = element
          i+=1
        end
      else entry.length > symbols.length
        i = 0
        symbols.each do | symbol |
          an_hash[symbol] = entry[i]
          i+=1
        end
      end
      list_in_array_of_symbols.push(an_hash.clone)
    end
    
    return list_in_array_of_symbols
    
  end
  
  ##
  #Generate a quiz from a set of data in a file.
  #Each lines in the file is an entry. In each line there is informations that are
  #separated by a pattern 
  #
  class Quiz

    
    #array that contains the original data entries used for the quiz
    attr_reader :data
    #contains the user answer to the current question (only usefull with in block of on_bad_answer and on_good_answer)
    attr_reader :user_answer
    #contains the radom value used to create the current question (only usefull with in block of on_bad_answer and on_good_answer)
    attr_reader :random_entry
    #current stats class for the quiz instance
    attr_reader :stats
    #array that contains data entries 
    attr_reader :running_quiz_data
    #number of good answers
    attr_reader :good_answers_number
    #number of bas answers
    attr_reader :bad_answers_number
    #number of total questions
    attr_accessor :total_questions
    #define the column used to create the question or answer
    attr_accessor :question_symbol
    #define the column used to create the answer
    attr_accessor :answer_symbol
    #define the saved /load dir for the stats
    attr_accessor :stats_dir

    ##
    #create a new Quiz object
    #* *Args*    :
    #  - +quiz_name+ -> name of the quiz (used to defined the filename of dumped stats)
    #  - +filename+ -> the name of the file containing the data
    #  - +symbols+ -> an array of ruby symbols that will be used as columns names
    #  - +column_separator+ -> pattern to use to separe each multiple value in a column (optionnal)
    #  - +column_sub_separator+ -> pattern to use to separe each columns
    #  - +block+ -> do { |line | line.gsub(/\s/,"") } if each entry values are separated by space and go in a hash
    #* *Returns* :
    #  - A New Quiz object
    def initialize(quiz_name, filename, symbols, column_separator, column_sub_separator = nil) 
      @quiz_name = quiz_name
      @data = Lobotomy::list_to_hash(filename, symbols, column_separator, column_sub_separator) 
      
      @running_quiz_data = Array.new
      fill_running_quiz_data()
      @stats = Lobotomy::Stats.new(@data, symbols)
      @question=nil
      @symbols = symbols
      @total_questions = 20
      @current_question_number = 0
      @remaining_questions = 0
      @good_answers_number = 0
      @bad_answers_number = 0
      @random = Random.new
    end

    ##
    #get a random entry in the entries set. This is a draw without replacement each entry have been selected.
    #* *Returns* :
    #  - a hash of an entry
    def get_random()

      fill_running_quiz_data() if @running_quiz_data.empty?

      entries_number = @running_quiz_data.length
      max_Range= entries_number -1 # -1 because random number is used as index in an array
      min_Range= 0
      
      #generate random number or get the last one:
      if @running_quiz_data.length > 1
        random_number = @random.rand(min_Range...max_Range)
      else
        random_number = 0
      end
      random_value = @running_quiz_data[random_number].clone

      @running_quiz_data.delete_at(random_number)

      return random_value
    end

    ##
    #launch the quiz
    #* *Args*    :
    #  - +total_questions+ -> the number of questions for the current quiz if nil default is 20
    #* *Returns* :
    #  - nothing
    def launch( total_questions = nil )
      if total_questions == nil
        @remaining_questions = @total_questions
      else
        @total_questions = total_questions
      end
      
      @remaining_questions = @total_questions
      
      while (@remaining_questions != 0 )
        @current_question_number += 1
        @remaining_questions -=1
        
        @random_entry = self.get_random()

        if @question == nil and @random_entry[@question_symbol].class ==String
          puts @random_entry[@question_symbol]
        #elsif @question != nil and @random_entry[@question_symbol].class ==String
        #  puts replace_symbol_by_value_in( @question, @random_entry )
        elsif @question == nil and @random_entry[@question_symbol].class == Array
          puts @random_entry[@question_symbol].join("/")
        elsif @question != nil #and @random_entry[@question_symbol].class == Array
          puts replace_symbol_by_value_in( @question, @random_entry )
        end
        
        begining = Time.now
        STDOUT.print("\t")
        @user_answer = STDIN.gets.chomp

        if @user_answer.match(/^[qQ]$/)
          return
        end

        user_time = Time.now - begining
        good_answer=nil

        #if only one answer:
        if @random_entry[@answer_symbol].class == String
          if @user_answer == @random_entry[@answer_symbol]
            @good_answers_number += 1
            good_answer =true
            @on_good_answer.call unless !@on_good_answer
          else
            @bad_answers_number += 1
            good_answer = false
            @on_bad_answer.call unless !@on_bad_answer
          end
        elsif @random_entry[@answer_symbol].class == Array
          #more than one possible answer
          @random_entry[@answer_symbol].each do | answer |
            if @user_answer == answer
              @good_answers_number += 1
              good_answer =true
              break
            else
              @bad_answers_number += 1
              good_answer = false            
            end
          end
          
          if good_answer == true
            @on_good_answer.call unless !@on_good_answer
          else
            @on_bad_answer.call unless !@on_bad_answer
          end
        else
          puts "!!!!Invalid format af data".red
        end
        @stats.add_new(@random_entry[:index],{:good => good_answer, :time => user_time})
      end
      
    end

    ##
    #adapt the displayed question for your need.
    #* *Args*    :
    #  - +string+ -> a string. Must contains at least one symbol (":symbol") in order to display a random value.
    #    The symbols you can use are the same that you defined when you create the your Quiz class.
    #    Those symbols are replaced by the corresponding value for the current random value
    #* *Returns* :
    #  - nothing
    def question_label( string = nil )
      if string.class == String 
        @question = string
      end
    end

    ##
    #return the stats class for to the current quiz 
    def results()
      return @stats.stats_data
    end

    ##
    #Save the current results to a Marshall dump file:
    #the full file name is build with :
    #Quiz.stats.stats_dir + "/" + Quiz.stats.stats_session + "/" + @quiz_name + "_" + @question_symbol.to_s + "_and_"+@answer_symbol.to_s+"_stats.dump"
    def save_results()
      unless @stats_dir.nil?
        @stats.stats_dir = @stats_dir
      end
      @stats.stats_file = @stats.stats_dir + "/" + @stats.stats_session + "/" + @quiz_name + "_" + @question_symbol.to_s + "_and_"+@answer_symbol.to_s+"_stats.dump"
      @stats.save()
    end
    ##
    #Load old results from a Marshall dump file:
    #the full file name is build with :
    #Quiz.stats.stats_dir + "/" + Quiz.stats.stats_session + "/" + @quiz_name + "_" + @question_symbol.to_s + "_and_"+@answer_symbol.to_s+"_stats.dump"
    def load_results()
      unless @stats_dir.nil?
        @stats.stats_dir = @stats_dir
      end
      @stats.stats_file = @stats.stats_dir + "/" + @stats.stats_session + "/" + @quiz_name + "_" + @question_symbol.to_s + "_and_"+@answer_symbol.to_s+"_stats.dump"
			@stats.load()
		end

    def on_bad_answer(&block)
      @on_bad_answer = Proc.new( &block)
    end

    def on_good_answer(&block)
      @on_good_answer = Proc.new( &block)
    end
    private

    def fill_running_quiz_data()
      @running_quiz_data = Array.new
      for i in 0..( @data.length - 1 ) do
        @running_quiz_data.push( @data[i].clone )
        @running_quiz_data[i][:index] = i
      end
    end
  
    def replace_symbol_by_value_in( string, entry )
      new_string = string
      @symbols.each do | symbol |

        string_for_substitution = ""
        if entry[symbol].class == Array
          string_for_substitution = entry[symbol].join("/")
        else
          string_for_substitution =  entry[symbol] 
        end
        
        if new_string.match(/\:#{symbol.to_s}/)
            new_string = new_string.gsub(/\:#{symbol.to_s}/,string_for_substitution)
        end
      end
      return new_string
    end
    
  end

  class Stats
    require 'fileutils'
    attr_accessor :stats_dir, :stats_session, :stats_file
    attr_reader :stats_data

    ##
    #Create a new Stats class
    #datas => array of datas used by the quiz
    #symbols => array of ruby symbols which can be those given in order to create the quiz
    def initialize( data, symbols,session = ENV['USER'],filename ="stats.dump" )

      @stats_dir = File.expand_path("./stats")
      @stats_session = session
      @stats_file = @stats_dir + "/" + @stats_session + "/" + filename
      @stats_data =  Array.new
      @symbols = symbols
      
      for i in 0..( data.length - 1)
        an_hash = Hash.new  
        symbols.each do | symbol |
          an_hash[symbol] = data[i][symbol]
        end
        an_hash[:stats] = Array.new
        @stats_data.push( an_hash.clone )
      end
      
    end

    def add_new( entry_index, stats)
      @stats_data[entry_index][:stats].push(stats)
    end

    def save()

      #check if stats dir exist else create it
      if !File.directory?( @stats_dir)
        FileUtils.mkdir_p( @stats_dir +"/#{@stats_session}")
      elsif !File.directory?( @stats_dir + "/#{@stats_session}")
        FileUtils.mkdir( @stats_dir +"/#{session_name}")
      end

      File.open(@stats_file,"w") do | file |
        file.write(Marshal::dump(@stats_data))
      end
    end

    def load()
    
      if !File.directory?( @stats_dir + "/" + @stats_session)
        puts "error no stats to load"
        return -1
      elsif !File.exist?( @stats_file )
        puts "bad dump files for #{@stats_session} session"
        return -1
      end
      #need to check if the @stats_data generated at the class creation 
      #and the loaded stats_data datacontains the same entries 
      loaded_stats_data = Marshal.load(File.read(@stats_file))
      
      loaded_stats_data.length != @stats_data.length
      @stats_data.each do | data |
        same_entry = nil
        found_at = nil
        count = 0
        loaded_stats_data.each do | loaded_stats |
          @symbols.each do | symbol |
            if data[symbol] == loaded_stats[symbol]
              unless same_entry == false 
                same_entry = true
              end
            else
              same_entry = false
            end
            if same_entry == true
              data[:stats] += loaded_stats[:stats].clone
              found_at = count
              break
            end
          end
          if found_at
            loaded_stats_data.delete_at(found_at)
          end
          same_entry = nil
          found_at = nil
          count += 1
        end
      end
    end
    
  end
  
end

#TODO in Quiz.load_results add boolean argument in order to create a new Quiz.data set without the already tested entries. On each load_results, new quiz will only use non tested entries
