##Lobotomy

###Create cli quizzes and force your brain:
Lobotomy is a module that helps you to create little quizzes, for terminal emulator, based on data in a text file.

###Install:
Get current version:

    git clone git://github.com/cedlemo/lobotomy.git

Create the gem:

    cd lobotomy
    gem build lobotomy.gemspec

Install lobotomy for the current user:

    gem install lobotomy-*.gem

###Lobotomy overview:
When I started learning Japanese, I needed a tool that helps me to quickly create little quizzes in order to learn things and to check what I have learned .

lobotomy read a text file which contains data and is formated like this:

    #word romaji
    shoe|kutsu
    sock|kutsushita
    house|uchi

User create a new Lobotomy::Quiz class that load this file and generate a new quiz. User can see his stats and save them.

###Examples:
Code examples for a simple quiz and more advanced ones.

####Simple example:
Here is a simple quiz that just displays if your answer is good or wrong.

With the file vocab.list :

    #word romaji
    shoe|kutsu
    sock|kutsushita
    house|uchi

Create a new ruby script called vocab_quizz.rb

    #!/usr/bin/env ruby
    require 'lobotomy'
    
    quiz_name = "vocab_quiz"
    data_file = "./vocab.list"
    symbols = [:word, :romaji]
    column_separator = "\|"
    column_sub_separator = nil
    nb_questions = 10

    quiz = Lobotomy::Quiz.new( quiz_name, data_file, symbols, column_separator, column_sub_separator )

    #The quiz will use the word column in order to create the question and the answer are checked with the romaji column.
		#quiz.question_symbol will be filled with  :word
    #quiz.answer_symbol will be filled with :romaji
    
    quiz.question_is_word_answer_is_romaji()
    
		quiz.on_bad_answer do
      puts "Wrong".red
    end

    quiz.on_good_answer do
      puts "Good".green
    end

    quiz.launch(nb_questions)

####Quiz with more customization:

The data file is kanas.list:

    #romaji hiragana katakana
    a あ ア
    i い イ
    u う ウ
    ...

There are mp3 files in the kanas_sounds directory that correspond to the sound of each kanas.

The associated ruby script is kanas_quiz.rb (in examples/):

We create a new Quiz class that load the file kanas.list, with "kanas_quiz" as the quiz name. The symbols we define corresponds of the column names in our data file.
The separator we use is the "space" char. No sub separator is given because we don't have multiple data in each columns' 

    kanas_file = "kanas.list"
    stats_directory="/home/" +ENV['USER']+"/.lobotomy/stats"
    quiz = Lobotomy::Quiz.new("kanas_quiz", kanas_file, [:romaji,:hiragana,:katakana],"\s",nil)

Here is the basic and mandatory configuration of the script:

    #define the column hiragana used as the question value
    #define the column romaji used as the answer value (it's this value that is checked with the user answer)
    quiz.question_is_hiragana_answer_is_romaji()

This part is optional but help to have a more customized quiz.

Modify the question label. User can customize the question label with a model. In this model if you use one or more symbols ( the same defined above) those symbols are substitued by the current value when the question is build.
User can modify colors of a part of the string. Lobotomy module extends the String class with new methods (bold, underline, reversed, black, red, green, yellow, blue, magenta, cyan) when you use require 'lobotomy' 

    quiz.question_label(":hiragana".blue + " ?")

You can define the directory where the stats will be saved/loaded 

    quiz.stats_dir = stats_directory

It 's possible to associate code for the two main events of a quiz which are good answer or bad answer:

Just use the methods on_bad_answer() and on_good_answer() and feed them with ruby blocks. You can access the current random entry taken from the full set of data with quiz.random_entry. Look at the code of the examples.

Here we define a block for the bad answer event. If the user answer is wrong, we display information.
Then we check if the user answer correspond to something in the data.
At the end, we play a media file and wait for user input in order to continue the quizz.

    quiz.on_bad_answer do
      puts "\t!!! Wrong".bold.yellow + " #{quiz.random_entry[:hiragana]}".blue + " => " + "#{quiz.random_entry[:romaji]}".cyan
      #find is user input correspond to another word
      print "\t\t"
      quiz.data.each do | entry |
        if entry[quiz.answer_symbol].match(/^#{quiz.user_answer}$/)
          print "you mistake #{quiz.random_entry[:hiragana]} for #{entry[quiz.question_symbol].black} => #{entry[quiz.answer_symbol].black}."
        end
      end
      system("mplayer kanas_sounds/#{quiz.random_entry[:romaji]}.mp3 > /dev/null 2>&1")
      print " Continue ...(hit Return)"
      STDIN.gets
    end

In the block for the good answer event we just display in green the "--Good !!!--" string. Play a media file and wait for user input

    quiz.on_good_answer do
      print "\t:--Good !!!--".green 
      system("mplayer kanas_sounds/#{quiz.random_entry[:romaji]}.mp3 > /dev/null 2>&1")
      print "  Continue ...(hit Return)"
      STDIN.gets
    end

Then we allow user to see some of his stats or error:

    puts "Do you want to see your difficulties?".black
    if STDIN.gets.chomp.match(/[yY]/)
    
      quiz.results.each do | entry |
        if entry[:stats].length != 0
          good=0
          bad = 0
          entry[:stats].each do | stats |
            if stats[:good] == true
              good += 1
            else
              bad += 1
            end
          end
          if bad > good
            puts "* ".black + entry[:hiragana].magenta + " => " + entry[:romaji].bold.red 
          end
        end
      end
    end

####Quiz with multiple data in columns:

You can have multiple data in each columns. Lobotomy can deals with this!

Example vocabulary.list:

    #romaji|kanas
    house|いえ/うち
    ox/cow|うし

The creation of a new Quiz class for this file will be done with:

    Lobotomy::Quiz.new("vocabulary_quiz", "vocabulary.list", [:romaji,:kana],"\|","\/")

That's all. You just have to be carefull when you are using quiz.random_entry. With sub separator, each data in a column have been put in an array:

    quiz.random_entry.inspect => {:romaji => "house", :kana => ["うち","いえ"]}
    quiz.random_entry.inspect => {:romaji => ["ox","cow"], :kana => "うし"}

cedlemo at gmx dot com
