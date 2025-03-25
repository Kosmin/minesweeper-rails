class GameChannel < ApplicationCable::Channel
  def subscribed
    stream_from "game_#{game_id}"
  end

  def receive(data)
    command = data["command"]
    if command == "new"
      new_game(data["level"])
    elsif command == "map"
      get_map
    elsif command == "open"
      open(data["row"].to_i,data["col"].to_i)
    end
  end

  def unsubscribed
    redis_client.del("game_#{params[:game_id]}")
  end

  private

  def new_game(level)
    # Create a new game with the specified level
    @board = Board.new(level.to_i, game_id)
    @board.generate_board
    @board.save!
    ActionCable.server.broadcast("game_#{game_id}", { data: 'new: OK' })
  end

  def get_map
    # Send the map to the client
    ActionCable.server.broadcast(
      "game_#{game_id}", {
        data: "map:\n#{board.visible_board_string}"
      }
    )
  end

  def open(row,col)
    board.open(row, col)
    board.save!
    if board.lost?
      ActionCable.server.broadcast("game_#{game_id}", { data: "open: You lose" })
    elsif board.won?
      ActionCable.server.broadcast("game_#{game_id}", { data: "open: You win" })
    else
      ActionCable.server.broadcast(
        "game_#{game_id}", {
          data: "map:\n #{board.visible_board_string}"
        }
      )
    end
  end

  def game_id
    @game_id = params[:game_id]
  end

  def board
    @board ||= Board.restore_board(params[:game_id])
  end

  def self.redis_client
    @redis_client ||= Redis.new
  end
end
