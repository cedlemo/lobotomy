# #
#  Lobotomy module
#  Contains a set of methods and class in order to create command line quiz
module Lobotomy
  require File.dirname(__FILE__) + '/lobotomy/colored'
  # #
  #  Split a line into an array based on separator
  def self.split_to_array(string, sep, sub_sep)
    return nil if string.nil?
    columns = []
    string.chomp.split(sep).each do | column |
      if sub_sep && column.match(/#{sub_sep}/)
        columns << column.split(sub_sep)
      else
        columns << column
      end
    end
    columns
  end
  # #
  # Check if filename exist and return its fullname or nil
  def self.check_file(filename)
    full_filename = File.expand_path(filename)
    File.exist?(full_filename) ? full_filename : nil
  end
  # #
  # Read data from a formated file and create an array
  def self.list_to_array(filename, col_sep, col_sub_sep = nil)
    list_in_array = []
    if check_file(filename)
      File.readlines(filename).each do |line|
        # don't read line starting with "# " which are comments lines
        unless line.match(/^#/)
          (columns = split_to_array(line.strip, col_sep, col_sub_sep)) &&
          list_in_array << columns
        end
      end
    end
    list_in_array
  end
  # #
  # get an hash from an array of value and an array of symbols
  def self.array_to_hash(symbols, array)
    an_hash = {}
    symbols.each do |symbol|
      an_hash[symbol] = array[symbols.index(symbol)] || ''
    end
    an_hash
  end
  # #
  # Read data from a formated file and create an array of hash with symbols
  def self.list_to_hash(file, symbols, col_sep, col_sub_sep = nil)
    data_in_array = Lobotomy.list_to_array(file, col_sep, col_sub_sep)
    data_in_hashes = []
    data_in_array.each_with_index do |entry, i|
      data_in_hashes << array_to_hash(symbols, entry)
      data_in_hashes[i][:index] = i
    end
    data_in_hashes
  end
  
  # Generate multiple draw without replacement on a data set
  class DrawWR
    attr_reader :data, :last_draw
    def initialize(data)
      return nil if !data || !data.is_a?(Array)
      @data_store = data
      @data = @data_store.clone
      @random = Random.new
    end
    # #
    # get a random entry in the entries set. This is a draw without replacement
    # each entry will be selected.
    # * *Returns* :
    #   - an element of the initial array
    def pick
      @data = @data_store.clone if @data.empty?
      @last_draw = @data.delete_at(random_number)
      @last_draw
    end

    def random_number
      max = @data.size > 0 ? @data.size - 1 : 0
      @random.rand(0..max)
    end
  end

  # Generate a quiz from a set of data in a file.
  # Each lines in the file is an entry. In each line there is informations that
  # are separated by a pattern
  #
  class Quiz
    # @data array that contains the original data entries used for the quiz
    # @user_answer contains the user answer to the current question (only
    # usefull with in block of on_bad_answer and on_good_answer)
    # @random_entry contains the radom value used to create the current
    # question (only usefull with in block of on_bad_answer and on_good_answer)
    # @stats current stats class for the quiz instance
    # @draw contains a Draw object ( Draw.data return the remaining data of the
    # quiz
    # @good_answers_number number of good answers
    # @bad_answers_number number of bad answers
    # @total_questions number of total questions
    # @stats_dir define the saved /load dir for the stats
    attr_reader :data, :user_answer, :random_entry , :stats,
                :draw, :good_answers_number, :bad_answers_number,
                :total_questions, :stats_dir
    # #
    # @question_symbol define the column used to create the question or answer
    # @answer_symbol define the column used to create the answer
    attr_accessor :quiz_name, :question_symbol, :answer_symbol
    # #
    # create a new Quiz object
    # * *Args*    :
    #   - +quiz_name+ -> name of the quiz (used to defined the filename of
    # dumped stats)
    #   - +filename+ -> the name of the file containing the data
    #   - +symbols+ -> an array of ruby symbols that will be used as columns
    # names
    #   - +column_separator+ -> pattern to use to separe each multiple value
    # in a column (optionnal)
    #   - +column_sub_separator+ -> pattern to use to separe each columns
    #   - +block+ -> do { |line | line.gsub(/\s/,"") } if each entry values
    # are separated by space and go in a hash
    # * *Returns* :
    #   - A New Quiz object
    def initialize(quiz_name, file, symbols, col_sep, col_sub_sep = nil)
      @quiz_name, @symbols, @col_sub_sep  = quiz_name, symbols, col_sub_sep
      @data = Lobotomy.list_to_hash(file, symbols, col_sep, col_sub_sep)
      @time = @good_answers_number = @bad_answers_number = 0
      @draw = Lobotomy::DrawWR.new(@data)

      stats_file = @quiz_name + '_' + @question_symbol.to_s + '_and_' +
        @answer_symbol.to_s + '_stats.dump'
      @stats = Lobotomy::Stats.new(@data, symbols, ENV['USER'], stats_file)
    end

    # #
    # launch the quiz
    # * *Args*    :
    #   - +nb_questions+ -> the number of questions for the current quiz
    #      if nil default is 20
    # * *Returns* :
    #   - nothing
    def launch(nb_questions = 20)
      @total_questions = nb_questions

      @total_questions.times do
        (@current_question_number = 0).next

        @random_entry = @draw.pick

        STDOUT.print("#{question_output}\n\t")

        read_user_input

        check_user_answer ? do_when_answer_is(true) : do_when_answer_is(false)
      end
    end

    # #
    # adapt the displayed question for your need.
    # * *Args*    :
    #   - +string+ -> a string. Must contains at least one symbol (":symbol")
    #     in order to display a random value.
    #     The symbols you can use are the same that you defined when you create
    #     the your Quiz class.
    #     Those symbols are replaced by the corresponding value for the current
    #     random value
    # * *Returns* :
    #   - nothing
    def question_label(string = nil)
      @question = string if string.is_a?(String)
    end

    # #
    # return the stats class for to the current quiz
    def results
      @stats.stats_data
    end

    # #
    # Save the current results to a Marshall dump file:
    def save_results
      @stats.save
    end
    # #
    # Load old results from a Marshall dump file:
    def load_results
      @stats.load
    end

    def on_bad_answer(&block)
      @on_bad_answer = Proc.new(&block)
    end

    def on_good_answer(&block)
      @on_good_answer = Proc.new(&block)
    end

    def method_missing(method, *args, &block)
      if /question_is_(?<q>[^_]*)_answer_is_(?<a>[^_]*)/ =~ method.to_s
        @question_symbol = q.to_sym
        @answer_symbol = a.to_sym
      end
    end

    private
    
    def do_when_answer_is(bool)
      if bool
        @good_answers_number += 1
        @on_good_answer.call if @on_good_answer
      else
        @bad_answers_number += 1
        @on_bad_answer.call if @on_bad_answer
      end
      @stats.add(@random_entry[:index], good: bool, time: @time)
    end

    def entry_value_to_s(entry)
      if entry.is_a?(Array)
        entry.join(@col_sub_sep)
      elsif entry.is_a?(String)
        entry
      end
    end

    def question_output
      @time = Time.now
      if @question
        replace_symbol_by_value_in(@question, @random_entry)
      else
        entry_value_to_s(@random_entry[@question_symbol])
      end
    end

    def read_user_input
      @user_answer = STDIN.gets.chomp

      # Quit if user types ctrl-Q
      exit if @user_answer.match(/^[qQ]$/)
    end

    def replace_symbol_by_value_in(string, entry)
      new_string = string

      @symbols.each do | sym |
        s_to_sub = entry_value_to_s(entry[sym])
        new_string = new_string.gsub(/\:#{sym.to_s}/, s_to_sub)
      end

      new_string
    end

    def check_user_answer
      @time = Time.now - @time
      # if only one answer:
      good_answer  = if @random_entry[@answer_symbol].is_a?(String)
        @user_answer == @random_entry[@answer_symbol]
      elsif @random_entry[@answer_symbol].is_a?(Array)
        # more than one possible answer
        @random_entry[@answer_symbol].include?(@user_answer)
      end
      good_answer
    end
  end

  # Record/load some data
  class Stats
    require 'fileutils'
    attr_accessor :stats_dir, :stats_session, :stats_file
    attr_reader :stats_data

    # #
    # Create a new Stats class
    # datas => array of datas used by the quiz
    # symbols => array of ruby symbols which can be those given in order to
    # create the quiz.
    def initialize(data, symbols, session = ENV['USER'], file = 'stats.dump')
      @stats_dir = File.expand_path('./stats')
      @stats_session, @symbols = session, symbols
      @stats_file = @stats_dir + '/' + @stats_session + '/' + file
      @stats_data =  []

      data.each_with_index do |entry|
        an_h = entry.select { |k, v| symbols.include?(k) }
        an_h[:stats] = []
        @stats_data.push(an_h.clone)
      end
    end

    def add(entry_index, stats)
      @stats_data[entry_index][:stats].push(stats)
    end

    def dir_tree_create_if_not_exist
      # check if stats dir exist else create it
      if !File.directory?(@stats_dir)
        FileUtils.mkdir_p(@stats_dir + "/#{@stats_session}")
      elsif !File.directory?(@stats_dir + "/#{@stats_session}")
        FileUtils.mkdir(@stats_dir + "/#{session_name}")
      end
    end

    def save
      dir_tree_create_if_not_exist

      File.open(@stats_file, 'w') do | file |
        file.write(Marshal.dump(@stats_data))
      end
    end

    def select_compare_set(hash)
      hash.select { |k, v| @symbols.include?(k) }
    end

    def compare_stats_data(set_1, set_2)
      return false if set_1.size != set_2.size
      # compare each array entry
      same = true
      set_1.each_with_index do |entry, i|
        same = select_compare_set(entry) == select_compare_set(set_2[i])
        break if same == false
      end
      same
    end

    def load
      if !File.directory?(@stats_dir + '/' + @stats_session)
        puts 'error no stats to load'
        return -1
      elsif !File.exist?(@stats_file)
        puts 'bad dump files for #{@stats_session} session'
        return -1
      end
      # need to check if the @stats_data generated at the class creation
      # and the loaded stats_data datacontains the same entries
      loaded_stats_data = Marshal.load(File.read(@stats_file))
      if compare_stats_data(@stats_data, loaded_stats_data)
      @stats_data = loaded_stats_data.clone
#     loaded_stats_data.length != @stats_data.length
#      @stats_data.each do | data |
#        same_entry = nil
#        found_at = nil
#        count = 0
#        loaded_stats_data.each do | loaded_stats |
#          @symbols.each do | symbol |
#            if data[symbol] == loaded_stats[symbol]
#              unless same_entry == false
#                same_entry = true
#              end
#            else
#              same_entry = false
#            end
#            if same_entry == true
#              data[:stats] += loaded_stats[:stats].clone
#              found_at = count
#              break
#            end
#          end
#          if found_at
#            loaded_stats_data.delete_at(found_at)
#          end
#          same_entry = nil
#          found_at = nil
 #         count += 1
      end
    end
  end
end

# TODO: in Quiz.load_results add boolean argument in order to create a new
# Quiz.data set without the already tested entries. On each load_results,
# new quiz will only use non tested entries
