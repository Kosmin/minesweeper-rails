class Board
  attr_reader :level, :rows, :cols, :visible_board, :full_board, :game_id

  def initialize(level, game_id)
    @level = level
    @game_id = game_id
  end

  def generate_board
    @full_board = BoardGenerator.new(level).perform
    @rows = full_board.length
    @cols = full_board.first.length
    @visible_board = Array.new(rows) { Array.new(cols, '□') }
  end

  def restore(data)
    @game_status = data[:game_status]
    @full_board = data[:full_board]
    @visible_board = data[:visible_board]
    @rows = full_board.length
    @cols = full_board.first.length
  end

  def open(x, y)
    return visible_board if !valid_position?(x, y) || visible_board[x][y] != '□'

    reveal(x, y)

    visible_board
  end

  # Saves the board by game id to redis
  def save!
    self.class.redis_client.set(cache_key, Marshal.dump({
      level: @level,
      full_board: @full_board,
      visible_board: @visible_board,
    }))
  end

  def visible_board_string
    visible_board.map { |row| row.join('') }.join("\n")
  end

  def won?
    !lost? && visible_board.flatten.count('□') == full_board.flatten.count('*')
  end

  def lost?
    visible_board.flatten.any? { |cell| cell == '*' }
  end

  def self.restore_board(game_id)
    data = redis_client.get(cache_key(game_id))
    return unless data

    data = Marshal.load(data)
    Board.new(data[:level], game_id).tap { |board| board.restore(data) }
  end

  private

  def reveal(x, y)
    return if !valid_position?(x, y) || visible_board[x][y] != '□'

    @visible_board[x][y] = full_board[x][y]

    # If it's an empty cell (0), reveal all surrounding tiles recursively
    if full_board[x][y] == 0
      neighbors(x, y).each { |nx, ny| reveal(nx, ny) }
    end
  end

  def valid_position?(x, y)
    x.between?(0, rows - 1) && y.between?(0, cols - 1)
  end

  def neighbors(x, y)
    directions = [-1, 0, 1].repeated_permutation(2).to_a - [[0, 0]]
    directions.map { |dx, dy| [x + dx, y + dy] }.select { |nx, ny| valid_position?(nx, ny) }
  end

  def cache_key
    self.class.cache_key(game_id)
  end

  def self.cache_key(game_id)
    "minesweeper_game_#{game_id}"
  end

  def self.redis_client
    @redis_client ||= Redis.new
  end
end