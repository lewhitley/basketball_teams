#!/usr/bin/env ruby

require 'csv'

CSV_NAME_FIELD = 'First & Last Name'
CSV_HEIGHT_FIELD = 'Height'
CSV_CAPTAIN_FIELD = 'Returning Players Only:  Are you willing to be a Captain this season? (Please sign up to be a Captain!  Captains make sure their team uses the sub list and ensures equal play)'

def get_teams(manual_captains = [])
  team_file = ARGV[0]
  number_of_teams = ARGV[1].to_i
  players = CSV.read(team_file, headers: true, encoding: 'bom|utf-8')

  first_pass = manual_captains.empty? ? pick_captains(players, number_of_teams) : remove_captains(manual_captains, players)

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

def pick_captains(players, number_of_teams)
  captains = [['Lindsey Whitley'], ['Pam Krnjaich']]
  remaining_players = []
  players.each do |player|
    if player[CSV_CAPTAIN_FIELD] == 'Yes'
      if captains.count < number_of_teams
        captains << [player[CSV_NAME_FIELD]]
      end
    else
      remaining_players << player
    end
  end

  {teams: captains, players: remaining_players}
end

def remove_captains(manual_captains, players)
  remaining_players = []
  players.each do |player|
    remaining_players << player unless manual_captains.include?(player[CSV_NAME_FIELD])
  end
  captains = manual_captains.map {|captain| [captain] }

  {teams: captains, players: remaining_players}
end

def sort_remaining_players(teams, players, number_of_teams)
  sorted_by_height = players.sort_by { |player| player[CSV_HEIGHT_FIELD]}

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

MANUAL_CAPTAINS = ['Lindsey Whitley', 'Pam krnjaich', 'Harlie Pollock', 'Abby Brown', 'Karen Blair', 'Brittany Little', 'Kelly Smit', 'France Lam', 'Christine Staley']
get_teams(MANUAL_CAPTAINS)
