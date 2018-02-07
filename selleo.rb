#!/bin/ruby

require 'tmpdir'
require 'date'

class XDate < Date
  DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].freeze

  def begining_of_the_prev_month
    prev_month
  end

  def end_of_the_prev_month
    prev    = prev_month
    new_day = DAYS[prev.month - 1]

    if new_day == 28 && self.class.leap?(prev.year)
      new_day = 29
    end

    XDate.new(prev.year, prev.month, new_day)
  end

  private

  def prev_month
    new_month = month - 1
    new_year  = year

    if (new_month == 0)
      new_month = 12
      new_year -= 1
    end

    XDate.new(new_year, new_month, 1)
  end
end

class StdinReader
  def gets
    lines = []
    loop do
      line = STDIN.gets.chomp
      break if line.empty?
      lines << line
    end
    lines.join("\n")
  end
end

class Pdf
  def initialize(template)
    @pwd      = Dir.pwd
    @template = template
  end

  def generate(params)
    replacements = {
      "{{NET_INCOME}}" => params.net_income,
      "{{BEGIN_DATE}}" => params.begin_date.to_s,
      "{{END_DATE}}"   => params.end_date.to_s,
      "{{LIST}}"       => params.todos.gsub("\n", "<br>").gsub(" ", "&nbsp;")
    }

    Dir.mktmpdir do |dir|
      FileUtils.cp(File.join(@pwd, @template), dir)
      html_file = File.join(dir, @template)
      puts "Replacing params tmp file: #{html_file}"
      data = File.read(html_file)
      replacements.each do |key, value|
        data.gsub!(key, value)
      end
      File.open(html_file, "w") do |f|
        f.write(data)
      end

      out_dir  = File.join(@pwd, "pdf")
      out_file = File.join(dir, "out.pdf")
      FileUtils.mkdir_p(out_dir)
      pdf = "wkhtmltopdf --page-size A4 \"#{html_file}\" \"#{out_file}\""
      puts "Running wkhtmltopdf: #{pdf}"
      system pdf

      puts "Copying generated PDF"
      file_name = "#{params.begin_date.to_s.gsub("-", "")}-#{params.end_date.to_s.gsub("-", "")}.pdf"
      FileUtils.cp(out_file, File.join(out_dir, file_name))
      puts "Done"
    end
  end
end

Params = Struct.new(:net_income, :begin_date, :end_date, :todos) do
  def valid?
    !net_income.nil?
  end

  def calculate_dates
    self.begin_date = XDate.today.begining_of_the_prev_month
    self.end_date   = XDate.today.end_of_the_prev_month
  end

  def to_s
    <<~STR
    NET_INCOME: #{net_income}zł
    BEGIN_DATE: #{begin_date}
    END_DATE:   #{end_date}
    TODOs:
      #{todos}
    STR
  end
end

args = ARGV.dup

params = Params.new
params.calculate_dates
params.net_income = args.shift

if params.valid?
  puts "Provide TODOs, example [empty line will finish the prompt]:"
  puts "- Project 1"
  puts "  - module A"
  puts "  - module B"
  puts ""
  puts "Prompt:\n"
  params.todos = StdinReader.new.gets
  puts "Generating PDF with:\n#{params}"
  pdf = Pdf.new("protokol.html")
  pdf.generate(params)
else
  puts "Not enough params to generate PDF"
end
