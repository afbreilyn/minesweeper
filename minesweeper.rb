#!/usr/bin/env ruby
require 'yaml'

module Minesweeper

  ADJACENT_TILES = [
    [1,   0], [1,   1],
    [0,   1], [-1,  1],
    [-1,  0], [-1, -1],
    [0,  -1], [1,  -1]  ]

  class Tile
    attr_accessor :explored, :contains, :flagged, :won
    attr_reader :neighbors, :coordinates

    def initialize(coordinates, game)
      @game = game
      @coordinates = coordinates
      @neighbors = howdy_neighbors

      @explored = false
      @contains = :B if rand(20) == 1
      @flagged = false
      @won = nil
    end

    def howdy_neighbors
      future_neighbors = []
      ADJACENT_TILES.each do |dif|
        poss_neighbor = [@coordinates[0] + dif[0], @coordinates[1] + dif[1]]
        next unless poss_neighbor[0].between?(0,8)
        next unless poss_neighbor[1].between?(0,8)
        future_neighbors << poss_neighbor
      end

      future_neighbors
    end

    def inspect
      return "F" if flagged
      return "*" if !explored
      return "B" if contains == :B
      return neighboring_bombs if neighboring_bombs > 0
      return "_"
    end

    def neighboring_bombs
      bomb_count = 0
      @neighbors.each do |coords|
        if @game.board[coords.first][coords.last].contains == :B
          bomb_count += 1
        end
      end
      bomb_count
    end

  end

  class Game
    attr_accessor :board

    def initialize(board=Array.new(9){ Array.new(9) })
      @board = board
      #set_tiles
    end

    def set_tiles
      @board.each do |cols|
        #p cols
        cols.each_index do |row|
          #p cols[row] # = Tile.new([cols, row])
          cols[row] = Tile.new([@board.index(cols), row], self)
        end
      end
    end

    def play
      play_intro_text
      loop do
        break unless @won.nil?
        take_turn
        @won = true if check_win
      end

      if @won
        puts "You're a winner!"
      else
        puts "You're a loser."
        reveal_all
      end
      inspect
    end

    def play_intro_text
      puts "Minesweeper Ruby Edition v1.0.0.0.00.0"
      puts "#{self}"
      puts ""
      puts "Always enter co-ordinates, regardless of command"
      puts "R = 'reveal', F = 'flag', U = 'unflag', Q = 'quit'"
      puts ""
    end

    def take_turn
      inspect
      puts ""
      puts "Enter command & coordinates:"
      puts "(EXAMPLE: F 3,1 will flag position 3,1)"
      parse(gets.chomp)

      nil
    end

    def inspect
      board.each do |rows|
        p rows
      end
    end

    def parse(string)
      string_arr = string.split(" ")
      string_arr += string_arr.pop.split(",")
      x, y = Integer(string_arr[1]), Integer(string_arr[2])

      if x.between?(0, 8) && y.between?(0, 8)
        exe_command(string_arr.first.upcase, x, y)
      end
      nil
    end

    def exe_command(com, x, y)
      case com
      when "F"
        flag([x, y])
      when "R"
        if is_bomb?([x, y])
          @won = false
          return
        end
        reveal([x, y])
      when "A"
        reveal_all
      when "H"
        hide_all
      when "U"
        unflag([x, y])
      when "Q"
        @won = false
      when "S"
        save
        puts "You've saved. Just like Jesus."
      else
        puts "YOU'RE SO DUMB YOU GET A YOU'RE DUMB ERROR"
        puts "Try again, you dumb:"

        inspect
        parse(gets.chomp)
      end
    end

    def reveal(coordinate)
      tile = @board[coordinate.first][coordinate.last]

      unless tile.flagged || tile.explored || tile.contains == :B
        tile.explored = true
        bomb_count = tile.neighboring_bombs
        tile.neighbors.each { |coords| reveal(coords) } unless bomb_count > 0
      end
    end

    def flag(coordinate)
      tile = @board[coordinate.first][coordinate.last]
      if tile.explored || tile.flagged
        puts "Move is invalid."
        parse(gets.chomp)
      else
        tile.flagged = true
      end
      nil
    end

    def unflag(coordinate)
      tile = @board[coordinate.first][coordinate.last]
      if !tile.flagged
        puts "Move is invalid."
        parse(gets.chomp)
      else
        tile.flagged = false
      end
      nil
    end

    def check_win
      @board.each do |col|
        col.each_index do |row|
          tile = col[row]
          return false if tile.contains == :B && !tile.flagged
          return false if tile.contains == nil && tile.flagged
        end
      end

      true
    end

    private

    def is_bomb?(coordinate)
      @board[coordinate[0]][coordinate[1]].contains == :B
    end

    def reveal_all
      @board.each do |columns|
        columns.each_index do |row|
          columns[row].explored = true
        end
      end
    end

    def hide_all
      @board.each do |columns|
        columns.each_index do |row|
          columns[row].explored = false
        end
      end
    end

    def save
      File.open("minesweeper_save.yml", 'w') { |file| file.write (@board.to_yaml) }
    end

  end
end


if $PROGRAM_NAME == __FILE__
  if ARGV[0].nil?
    game = Minesweeper::Game.new
    game.set_tiles
  else
    saved_board = YAML.load_file(ARGV.pop)
    game = Minesweeper::Game.new(saved_board)
  end
  game.play
end
