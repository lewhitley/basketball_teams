#!/usr/bin/env ruby

# call file like: bin/make_teams.rb PLAYERS_FILE NUMBER_TEAMS
require 'csv'
require 'dotenv/load'

CSV_NAME_FIELD = 'First & Last Name'
CSV_HEIGHT_FIELD = 'Height'
CSV_CAPTAIN_FIELD = 'Returning Players Only:  Are you willing to be a Captain this season? (Please sign up to be a Captain!  Captains make sure their team uses the sub list and ensures equal play)'

def get_teams(manual_captains = [])
  team_file = ARGV[0]
  number_of_teams = ARGV[1].to_i
  players = CSV.read(team_file, headers: true, encoding: 'bom|utf-8')

  first_pass = remove_captains(manual_captains, players)

  teams = sort_remaining_players(first_pass[:teams], first_pass[:players], number_of_teams)
  teams.each_with_index do |team, index|
    temp_team = team.dup
    temp_team[0] = "Captain: " + temp_team.first

    puts "Team #{index + 1}"
    puts temp_team
    puts "\n"
  end

  teams
end

def remove_captains(manual_captains, players)
  remaining_players = []
  players.each do |player|
    remaining_players << player unless manual_captains.include?(player[CSV_NAME_FIELD].strip)
  end
  captains = manual_captains.map {|captain| [captain] }

  {teams: captains, players: remaining_players}
end

def sort_remaining_players(teams, players, number_of_teams)
  sorted_by_height = players.sort_by { |player| parse_height(player[CSV_HEIGHT_FIELD]) }

  full_teams = []
  teams.each_with_index do |team, team_i|
    (0..5).each do |i|
      player_index = (number_of_teams * i) + team_i
      next if player_index >= sorted_by_height.count

      team << sorted_by_height[player_index][CSV_NAME_FIELD]
    end
    full_teams << team
  end

  full_teams
end

def parse_height(csv_height)
  feet, inches = csv_height.delete('"').split("'")
  (feet.to_i * 12) + inches.to_i
end

get_teams(ENV['MANUAL_CAPTAINS'].split(','))
