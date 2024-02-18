#!/usr/bin/env ruby
require 'google_drive'
require 'date'

# TODO: reset these each season
START_DATE = Date.new(2024, 5, 1)
NUMBER_GAMES = 12
NUMBER_TEAMS = 9
HOLIDAYS = [Date.new(2024, 5, 27)]
SEASON_NAME = 'Spring 2024' # season and year
SCHEDULE_9TEAMS = [
  { games: [[3,4], [1,2], [7,8], [5,6]], bye: 9 },
  { games: [[1,3], [6,9], [2,4], [5,7]], bye: 8 },
  { games: [[3,6], [8,9], [1,4], [2,5]], bye: 7 },
  { games: [[1,5], [2,7], [3,8], [4,9]], bye: 6 },
  { games: [[3,9], [4,7], [1,6], [2,8]], bye: 5 },
  { games: [[1,7], [5,9], [3,6], [2,8]], bye: 4 },
  { games: [[1,8], [2,9], [6,7], [4,5]], bye: 3 },
  { games: [[4,6], [5,8], [1,9], [7,3]], bye: 2 },
  { games: [[3,5], [4,8], [2,6], [7,9]], bye: 1 },
  { games: [[7,6], [1,2], [3,4], [5,8]], bye: 9 },
  { games: [[8,6], [2,3], [4,5], [1,9]], bye: 7 },
  { games: [[2,4], [5,7], [6,9], [1,3]], bye: 8 },
]

def validate_schedule
  even_times = 0
  NUMBER_TEAMS.times do |time|
    team = time + 1
    teams_played = []
    games_6pm = 0
    games_7pm = 0

    SCHEDULE_9TEAMS.each do |week|
      week[:games].each_with_index do |game, i|
        if game.include?(team)
          teams_played += (game - [team])
          i == 0 || i == 1 ? games_6pm += 1 : games_7pm += 1
        end
      end
    end

    puts "team: #{team}"
    if teams_played.uniq.count != (NUMBER_TEAMS - 1)
      puts"teams_played: #{teams_played.uniq}"
    end
    puts "6pm: #{games_6pm}, 7pm: #{games_7pm}"

    even_times += 1 if games_6pm == 5 || games_7pm == 5
    puts '======================='
  end

  puts "even: #{even_times}"
end

## Create schedule
def create_schedule
  end_date = START_DATE + (HOLIDAYS.count * 7) + (NUMBER_GAMES * 7)
  all_mondays = (START_DATE..end_date).select(&:monday?)
  game_dates = all_mondays - HOLIDAYS

  schedule = {}
  all_mondays.each do |monday|
    if !game_dates.include?(monday)
      schedule[monday] = 'holiday'
      next
    end

    if NUMBER_TEAMS == 9
      schedule[monday] = SCHEDULE_9TEAMS.pop
    end
  end

  schedule
end

def gameify(teams)
  games = []
  teams.each_slice(2) do |a, b|
    games << [a, b]
  end
  games
end

def move_to_drive_9team(schedule)
  # https://www.twilio.com/blog/google-spreadsheets-ruby-html
  session = GoogleDrive::Session.from_service_account_key("test-schedule-client-secret.json")

  # Get the spreadsheet by its title
  spreadsheet = session.spreadsheet_by_title("Test Schedule")
  # Get the first worksheet
  # https://github.com/gimite/google-drive-ruby/blob/master/lib/google_drive/worksheet.rb
  worksheet = spreadsheet.worksheets[0] #TODO

  # header
  worksheet.update_cells(1, 2, [
    ['East court is closest to restrooms'],
    ["SRWAC Basketball #{SEASON_NAME} Season"],
    ['All Games start promptly at 6PM and 7PM'],
  ])
  worksheet.merge_cells(1,2,1,8)
  worksheet.merge_cells(2,2,1,8)
  worksheet.merge_cells(3,2,1,8)
  worksheet.set_text_format(1,2,1,8, bold:true, foreground_color: GoogleDrive::Worksheet::Colors::RED)
  worksheet.set_background_color(2,2,1,1, GoogleDrive::Worksheet::Colors::BLACK)
  worksheet.set_text_format(2,2,1,1, bold:true, foreground_color: GoogleDrive::Worksheet::Colors::WHITE)
  worksheet.set_background_color(3,2,1,1, GoogleDrive::Worksheet::Colors::BLACK)
  worksheet.set_text_format(3,2,1,1, foreground_color: GoogleDrive::Worksheet::Colors::WHITE)

  # game header
  worksheet.update_cells(4, 2, [['Week', 'Date', 'East Court 6pm', 'West Court 6pm', '', 'East Court 7pm', 'West Court 7pm', 'Bye']])
  worksheet.set_background_color(4,2,1,8,GoogleDrive::Worksheet::Colors::GRAY)
  worksheet.set_background_color(4,6,1,1,GoogleDrive::Worksheet::Colors::BLACK)
  worksheet.set_text_format(4,2,1,8, bold: true)
  worksheet.set_text_alignment(1,2,4,8, horizontal: 'CENTER', vertical: 'MIDDLE')

  # games
  starting_cell = [5,2]
  game_counter = 1
  schedule.each do |date, info|
    if info == 'holiday'
      print_holiday_week(worksheet, date, starting_cell)
    else
      print_game_week(worksheet, date, info, game_counter, starting_cell)
      game_counter += 1
    end
    starting_cell = [starting_cell[0] + 3, starting_cell[1]]
  end

  blank_lines = 11
  blank_lines.times do |i|
    worksheet.merge_cells(7 + i*3,2,1,8)
  end

  worksheet.save

  # spreadsheet.update_from_file('')
end

def print_holiday_week(worksheet, date, starting_cell)
  return_array = []
  return_array << ['', date, 'NO GAME - GYM CLOSED', '', '', '', '' ]
  return_array << ['', '', '', '', '', '', '' ]
  return_array << ['', '', '', '', '', '', '' ]

  worksheet.update_cells(starting_cell[0], starting_cell[1], return_array)
  worksheet.merge_cells(starting_cell[0],starting_cell[1],2,1)
  worksheet.merge_cells(starting_cell[0],starting_cell[1] + 1,2,1)
  worksheet.merge_cells(starting_cell[0],starting_cell[1] + 2,2,6)

  worksheet.set_background_color(starting_cell[0], starting_cell[1] + 2,1,1,GoogleDrive::Worksheet::Colors::YELLOW)
  worksheet.set_text_format(starting_cell[0], starting_cell[1],3,6, bold: true)
  worksheet.set_text_alignment(starting_cell[0], starting_cell[1],3,8, horizontal: 'CENTER', vertical: 'MIDDLE')
end

def print_game_week(worksheet, date, info, counter, starting_cell)
  games = info[:games]

  return_array = []
  return_array << [counter, date, "Team #{games[0][0]}", "Team #{games[1][0]}", '', "Team #{games[2][0]}", "Team #{games[3][0]}", "Team #{info[:bye]}"]
  return_array << ['', '', "Team #{games[0][1]}", "Team #{games[1][1]}", '', "Team #{games[2][1]}", "Team #{games[3][1]}" ]
  return_array << ['', '', '', '', '', '', '' ]

  worksheet.update_cells(starting_cell[0], starting_cell[1], return_array)
  worksheet.merge_cells(starting_cell[0],starting_cell[1],2,1)
  worksheet.merge_cells(starting_cell[0],starting_cell[1] + 1,2,1)
  worksheet.merge_cells(starting_cell[0],starting_cell[1] + 7,2,1)
  worksheet.merge_cells(starting_cell[0]+2,starting_cell[1],1,8)

  worksheet.set_background_color(starting_cell[0],starting_cell[1] + 4,2,1,GoogleDrive::Worksheet::Colors::BLACK)
  worksheet.set_text_format(starting_cell[0],starting_cell[1],2,8, bold: true)
  worksheet.set_text_alignment(starting_cell[0], starting_cell[1],2,8, horizontal: 'CENTER', vertical: 'MIDDLE')
end

validate_schedule
schedule = create_schedule
move_to_drive_9team(schedule)