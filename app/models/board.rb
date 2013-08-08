class Board < ActiveRecord::Base
  attr_accessible :game_id, :user_id, :cells_attributes

  belongs_to :user
  belongs_to :game
  has_many :cells, dependent: :destroy
  accepts_nested_attributes_for :cells
  has_many :phrases, through: :cells #needed?

  after_create :make_cells
  after_destroy :notify_other_players, :destroy_game_if_empty

  SIZE = 4

  def pending_votes(user)
    self.cells.map { |cell| cell.pending_votes(user) }.select{|photo| photo }
  end

  def cell_at(x_coord,y_coord)
    cells.find_by_x_coord_and_y_coord(x_coord, y_coord)
  end

  private
  def make_cells
    phrase_ids_to_use = self.game.theme.phrases.pluck(:id).sample(16)
    cells_attributes = []

    SIZE.times do |i|
      SIZE.times do |j|
        cells_attributes << {
          :phrase_id => phrase_ids_to_use.pop,
          :x_coord => i,
          :y_coord => j
        }
      end
    end

    self.cells.create(cells_attributes)
  end

  def notify_other_players
    game.notifications.create(subject_id: user.id,
      quality: "quit")
  end

  def destroy_game_if_empty
    game.destroy if game.boards.empty?
  end

end