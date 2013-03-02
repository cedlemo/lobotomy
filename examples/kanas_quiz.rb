#!/usr/bin/env ruby
# encoding: UTF-8
require 'lobotomy'

#handle Ctrl-C
trap('INT') {
  puts " leaving..."
  exit
}
#clear the terminal
system("clear")

#set default number of questions for the quiz
nb_quiz_questions = 10

#user can modify the number of questions with the first argument of the script
if ARGV.length ==1 and ARGV[0].to_i> 0 and ARGV[0].to_i <1000
  nb_quiz_questions = ARGV[0].to_i
end

kanas_file = "kanas.list"
stats_directory="/home/" +ENV['USER']+"/.lobotomy/stats"

quiz = Lobotomy::Quiz.new("kanas_quiz", kanas_file, [:romaji,:hiragana,:katakana],"\s",nil)

quiz.question_symbol = :hiragana
quiz.answer_symbol = :romaji 
quiz.question_label(":hiragana".blue + " ?")
quiz.stats_dir = stats_directory

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

quiz.on_good_answer do
  print "\t:--Good !!!--".green 
  system("mplayer kanas_sounds/#{quiz.random_entry[:romaji]}.mp3 > /dev/null 2>&1")
  print "  Continue ...(hit Return)"
  STDIN.gets
end

quiz.load_results

quiz.launch(nb_quiz_questions)

#analyse the current stats (not part of the quiz)
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

puts "Do you want to save results?"
if STDIN.gets.chomp.match(/[yY]/)
  quiz.save_results
  puts "Results saved, bye!"
else
  puts "bye!"
end

