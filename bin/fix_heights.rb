#!/usr/bin/env ruby

# I updated the form so that heights should only be entered in inches (2 numeric characters). That means this script will hopefully not be needed.

require 'csv'

CSV_HEIGHT_FIELD = 'Height'

def parse_height(height)
  height = height.gsub(/\s+/, "")

  normal = parse_normal_format(height)
  return normal if normal

  metric = parse_metric_format(height)
  return metric if metric

  weird_normal = parse_weird_normal_format(height)
  return weird_normal if weird_normal

  backward = parse_backward_format(height)
  return backward if backward

  incomplete1 = parse_incomplete_format1(height)
  return incomplete1 if incomplete1

  incomplete2 = parse_incomplete_format2(height)
  return incomplete2 if incomplete2

  incomplete3 = parse_incomplete_format3(height)
  return incomplete3 if incomplete3

  weird1 = parse_weird_format1(height)
  return weird1 if weird1

  weird2 = parse_weird_format2(height)
  return weird2 if weird2
end

def parse_normal_format(height)
  return unless /\d'\d+"/.match(height)
  split = height.split("'")
  feet = split.first.to_i
  inches = split.last.delete('"').to_i

  (feet * 12) + inches
end

def parse_weird_normal_format(height)
  return unless /\d’\d+”/.match(height)
  split = height.split("’")
  feet = split.first.to_i
  inches = split.last.delete('”').to_i

  (feet * 12) + inches
end

def parse_backward_format(height)
  return unless /\d"\d+'/.match(height)
  split = height.split('"')
  feet = split.first.to_i
  inches = split.last.delete('"').to_i

  (feet * 12) + inches
end

def parse_incomplete_format1(height)
  return unless /\d"\d+/.match(height)

  split = height.split('"')
  feet = split.first.to_i
  inches = split.last.to_i

  (feet * 12) + inches
end

def parse_incomplete_format2(height)
  return unless /\d'\d+/.match(height)

  split = height.split("'")
  feet = split.first.to_i
  inches = split.last.to_i

  (feet * 12) + inches
end

def parse_incomplete_format3(height)
  return unless /\d’\d+/.match(height)

  split = height.split('’')
  feet = split.first.to_i
  inches = split.last.to_i

  (feet * 12) + inches
end

def parse_weird_format1(height)
  return unless /\dft\d+/.match(height)

  split = height.split('ft')
  feet = split.first.to_i
  inches = split.last.to_i

  (feet * 12) + inches
end

def parse_weird_format2(height)
  return unless /\d-\d+/.match(height)

  split = height.split('-')
  feet = split.first.to_i
  inches = split.last.to_i

  (feet * 12) + inches
end

def parse_metric_format(height)
  return unless /\dm/.match(height)

  height.delete('m').to_i * 39.3701
end

def run
  team_file = ARGV[0]
  raw_file = CSV.read(team_file, headers: true, encoding: 'bom|utf-8')

  new_file = team_file.delete('.csv') + 'corrected' + '.csv'

  uncorrected = []
  raw_file.each do |player|
    raw_height = player[CSV_HEIGHT_FIELD]

    corrected_height = parse_height(raw_height)
    uncorrected << raw_height unless corrected_height

    # puts "given: #{raw_height}"
    # puts "corrected: #{corrected_height}"
  end
end

run