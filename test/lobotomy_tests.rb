require File.dirname(__FILE__) + '/../lib/lobotomy'
require 'test/unit'
class Quiz < Lobotomy::Quiz
  def test_question_output
    @random_entry = @draw.pick
    question_output
  end
  
  def entry_value_to_s_test(entry, join_char)
    if entry.is_a?(Array)
      entry.join(join_char)
    elsif entry.is_a?(String)
      entry
    end
  end
  
  def random_string(length = 8)
    # simple rand(36**length).to_s(36)
    (36**(length-1) + rand(36**length - 36**(length-1))).to_s(36)
  end

  def fake_user_answer(bool = true)
    @user_answer = if bool && @random_entry[@answer_symbol].is_a?(Array)
      @random_entry[@answer_symbol].sample 
    elsif bool && @random_entry[@answer_symbol].is_a?(String)
      @random_entry[@answer_symbol]
    else
      random_string() 
    end
  #STDOUT.puts(@user_answer.inspect + " " + @random_entry[@answer_symbol].inspect )
  end
end

class TmpData
  attr_reader :file, :symbols, :data, :sep, :sub_sep
  def initialize(name, sep, sub_sep)
    @file = "/tmp/#{name}.txt"
    @sep, @sub_sep = sep, sub_sep
    gen_tmp_file
    gen_data
  end
  def gen_tmp_file 
    File.open(@file, 'w') do |f|
		  f.puts '#français' + @sep + 'anglais' + @sep + 'type'
			f.puts 'bonjour' + @sep + 'hello' + @sep + 'interjection'
			f.puts 'bonjour' + @sep + 'hi' + @sub_sep + 'hello' + @sep + 'interjection'
		  f.puts 'pari' + @sep + 'wager' + @sep
		end
  end
  def gen_data
		@symbols = [ :french, :english, :type ]
		@data = [ 
      { french: 'bonjour', english: 'hello', type: 'interjection', index: 0 },
		  { french: 'bonjour', english: ['hi','hello'], type: 'interjection', index: 1 },
			{ french: 'pari', english: 'wager', type: '', index: 2} ]
  end
end
class TestLobotomy < Test::Unit::TestCase
  def test_split_to_array
    assert_equal(['toto','tata'], Lobotomy.split_to_array('toto,tata',',', nil))
    assert_equal(['toto','tata'], Lobotomy.split_to_array('toto,tata',',', '/'))
    assert_equal(['toto',['tata','titi']], Lobotomy.split_to_array('toto,tata/titi',',', '/'))
		assert_equal(nil, Lobotomy.split_to_array(nil, ',', '/'))
	end
	
  def test_list_to_array
	  tmp_file = '/tmp/list_to_array_test.txt'
    File.open(tmp_file, 'w') do |file|
		  file.puts 'titi,tata,toto'
			file.puts 'haha,hihi/huhu,hoho'
		  file.puts 'fifi,,fofo'
		end
		expected = [ ['titi','tata','toto'],
		           ['haha',['hihi','huhu'],'hoho'],
							 ['fifi','','fofo'] ]
		assert_equal(expected, Lobotomy.list_to_array(tmp_file, ',', '/'))
    File.delete(tmp_file)
	end

	def test_check_file
	  tmp_file = '/tmp/check_file_test.txt'
		File.open(tmp_file, 'w') do |file|
		  file.puts 'test'
		end
		assert_equal(tmp_file, Lobotomy.check_file(tmp_file))
		assert_equal(nil, Lobotomy.check_file('/tmp/file_taht_not_exists'))
		File.delete(tmp_file)
	end

  def test_array_to_hash
    symbols = [ :sym1, :sym2 ]
		array = [ 'val1', 'val2' ]
		expected = { sym1: 'val1', sym2: 'val2' }
		assert_equal(expected, Lobotomy.array_to_hash(symbols, array))
    symbols = [ :sym1 ]
		array = [ 'val1', 'val2' ]
		expected = { sym1: 'val1' }
		assert_equal(expected, Lobotomy.array_to_hash(symbols, array))
    symbols = [ :sym1, :sym2, :sym3 ]
		array = [ 'val1', 'val2' ]
		expected = { sym1: 'val1', sym2: 'val2', sym3: '' }
		assert_equal(expected, Lobotomy.array_to_hash(symbols, array))
  end
	
	def test_list_to_hash
    tmp_file = '/tmp/list_to_hash_test.txt'
    File.open(tmp_file, 'w') do |file|
		  file.puts 'titi,tata,toto'
			file.puts 'haha,hihi/huhu,hoho'
		  file.puts 'fifi,,fofo'
		end
		symbols = [ :sym1, :sym2, :sym3 ]
		expected = [ { sym1: 'titi', sym2: 'tata', sym3: 'toto', index: 0 },
		           { sym1: 'haha', sym2: ['hihi','huhu'], sym3: 'hoho', index: 1 },
							 { sym1: 'fifi', sym2: '', sym3: 'fofo', index: 2 } ]

		assert_equal(expected, Lobotomy.list_to_hash(tmp_file, symbols, ',', '/'))
		File.delete(tmp_file)
	end

  def test_classes_existence
		assert_equal([:DrawWR, :Quiz,:Stats], Lobotomy.constants.select {|c| Class === Lobotomy.const_get(c)})
	end
  
  def test_DrawWR
    data = [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
    loto = Lobotomy::DrawWR.new(data)
    assert_kind_of(Fixnum, loto.random_number)
    assert_kind_of(Fixnum, loto.pick)
    assert_equal(data.size - 1, loto.data.size) 
  end

	def test_Quiz_class_initialize
    tmp = TmpData.new('class_initialize', ',', '/')
		quiz = Quiz.new('test', tmp.file, tmp.symbols, tmp.sep, tmp.sub_sep)
		assert_equal(tmp.data, quiz.data)
		assert_equal('test', quiz.quiz_name)
		assert_equal(nil, quiz.question)
		assert_kind_of(Fixnum, quiz.draw.random_number)
		File.delete(tmp.file)
	end
  
  def test_Quiz_class_generate_questions

    tmp = TmpData.new('class_gen_qestions', ',', '/')
		quiz = Quiz.new('test', tmp.file, tmp.symbols, tmp.sep, tmp.sub_sep)

    quiz.question_is_french_answer_is_english
    10.times do 
      rep = quiz.test_question_output 
      assert_equal(quiz.random_entry[:french],rep)
    end
  
		quiz = Quiz.new('test', tmp.file, tmp.symbols, tmp.sep, tmp.sub_sep)
    quiz.question_is_french_answer_is_english
    quiz.question_label(':french se dit en anglais: :english')
    rep = quiz.test_question_output 
    expected =  quiz.entry_value_to_s_test(quiz.random_entry[:french], '/') + 
                ' se dit en anglais: ' +
                quiz.entry_value_to_s_test(quiz.random_entry[:english], '/')
    assert_equal(expected, rep)
		File.delete(tmp.file)
  end
  
  def test_Quiz_class_check_answer
    tmp = TmpData.new('class_gen_qestions', ',', '/')
		quiz = Quiz.new('test', tmp.file, tmp.symbols, tmp.sep, tmp.sub_sep)
    quiz.question_is_french_answer_is_english
    10.times do
      quiz.test_question_output 
      quiz.fake_user_answer(true)
      assert_equal(true,quiz.send(:check_user_answer))
    end 
		10.times do
      quiz.test_question_output 
      quiz.fake_user_answer(false)
      assert_equal(false,quiz.send(:check_user_answer))
    end 
    File.delete(tmp.file)
  end

  def test_Quiz_Stats_class_initialize
    tmp = TmpData.new('class_gen_qestions', ',', '/')
		quiz = Quiz.new('test', tmp.file, tmp.symbols, tmp.sep, tmp.sub_sep)
    quiz.question_is_french_answer_is_english
    tmp.data.each_with_index do | entry, i|
      assert_equal( entry.clone.tap { |x| x.delete(:index)} , 
                    quiz.stats.data[i].clone.tap{ |x| x.delete(:stats)})
    end
    File.delete(tmp.file)
  end

  def test_Quiz_load_stats
    tmp = TmpData.new('class_gen_qestions', ',', '/')
		quiz = Quiz.new('test', tmp.file, tmp.symbols, tmp.sep, tmp.sub_sep)
    quiz.question_is_french_answer_is_english
    quiz.stats.stats_dir = '/tmp'
    #create false stats:
    quiz.stats.add(1, good: true, time: Time.now)
    old_stats = quiz.stats.data.clone
    quiz.save_results
    stats_file_name = File.expand_path('/tmp') + '/' + ENV['USER'] + '/' + 
      quiz.quiz_name + '_' + quiz.question_symbol.to_s + '_and_' +
      quiz.answer_symbol.to_s + '_stats.dump'
    assert(File.exist?(stats_file_name),"wrong filename #{stats_file_name}")  		
    quiz = Quiz.new('test', tmp.file, tmp.symbols, tmp.sep, tmp.sub_sep)
    quiz.question_is_french_answer_is_english
    quiz.stats.stats_dir = '/tmp'
    assert_not_equal(old_stats, quiz.stats.data)
    assert_equal(true, quiz.load_results)
    assert_equal(old_stats, quiz.stats.data)
    assert_equal(2, quiz.draw.data.size)
    File.delete(tmp.file)

  end
end

