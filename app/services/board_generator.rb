class BoardGenerator
  attr_accessor :rows, :cols, :mine_count, :board

  LEVELS = {
    0 => { rows: 9, cols: 9, mines: 10 },      # Easy
    1 => { rows: 16, cols: 16, mines: 40 },    # Medium
    2 => { rows: 16, cols: 30, mines: 99 },    # Hard
    3 => { rows: 24, cols: 30, mines: 180 }    # Very Hard
  }

  def initialize(level)
    config = LEVELS[level] || LEVELS[0]
    @rows, @cols, @mine_count = config.values_at(:rows, :cols, :mines)
    @board = Array.new(@rows) { Array.new(@cols, 0) }
  end

  def perform
    place_mines
    update_numbers
    board
  end

  private

  def place_mines
    positions = (0...rows * cols).to_a.sample(mine_count)
    positions.each do |pos|
      r, c = pos.divmod(cols)
      board[r][c] = '*'
    end
  end

  def update_numbers
    directions = [-1, 0, 1].repeated_permutation(2).to_a - [[0, 0]]

    rows.times do |r|
      cols.times do |c|
        next if board[r][c] == '*'

        count = directions.count do |dr, dc|
          nr, nc = r + dr, c + dc
          nr.between?(0, rows - 1) && nc.between?(0, cols - 1) && board[nr][nc] == '*'
        end

        board[r][c] = count if count > 0
      end
    end
  end
end