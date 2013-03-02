#!/usr/bin/env ruby
require 'lobotomy'

quiz_name = "vocab_quiz"
data_file = "./vocab.list"
symbols = [:word, :romaji]
column_separator = "\|"
column_sub_separator = nil
nb_questions = 10

quiz = Lobotomy::Quiz.new( quiz_name, data_file, symbols, column_separator, column_sub_separator )

quiz.question_symbol = :word
quiz.answer_symbol = :romaji

quiz.on_bad_answer do
	puts "Wrong".red
end

quiz.on_good_answer do
  puts "Good".green
end

quiz.launch(nb_questions)
