class Photo < ActiveRecord::Base
  attr_accessible :img, :cell_id, :status
  #status can be "pending", "approved", "rejected"
  #set default to pending in database!!!

  belongs_to :cell
  has_one :board, through: :cell
  has_one :game, through: :board
  has_one :user, through: :board
  has_many :notifications, dependent: :destroy, inverse_of: :photo
  has_many :votes, dependent: :destroy, inverse_of: :photo

  has_attached_file :img, :styles => {
    :big => "600x600",
    :small => "#{Cell::WIDTH}x#{Cell::WIDTH}"
  }

  validates_presence_of :img, :cell
  validates :status, inclusion: {in: ["approved", "rejected", "pending"]}

  after_create :notify_players, :auto_accept_in_a_day

  def pending_votes?(voting_user)
    !game.end &&
    status == "pending" &&
    votes.find_by_user_id(voting_user.id).nil? &&
    voting_user.id != user.id
  end

  def check_status
    #This should run whenever a vote is placed
    vote_array = votes.pluck(:approve)
    number_other_players = (game.boards.count - 1).to_f
    if vote_array.count(true) >= (number_other_players / 2).ceil
      update_attribute(:status, "approved")
      notifications.create(subject_id: user.id,
        game_id: game.id,
        quality: "accept")
        board.win_check
    elsif vote_array.count(false) >= (number_other_players / 2).floor
      update_attribute(:status, "rejected")
      notifications.create(subject_id: user.id,
        game_id: game.id,
        quality: "reject")
    end
  end

  def auto_accept_in_a_day
    update_attribute(:status, "approved")
  end
  handle_asynchronously :auto_accept_in_a_day, :run_at => Proc.new { 1.minutes.from_now }

  private
  def notify_players
    game.notifications.create(subject_id: user.id,
      quality: "new", photo_id: id)
  end

end