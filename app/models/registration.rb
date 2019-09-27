class Registration < ActiveRecord::Base
  belongs_to :person
  belongs_to :game
  belongs_to :squad
  has_many :infractions
  has_many :missions, :class_name => "Attendance"
  has_many :tagged, :foreign_key => "tagger_id", :class_name => "Tag"
  has_many :taggedby, :foreign_key => "tagee_id", :class_name => "Tag"
  has_many :check_ins
  has_many :bonus_codes
  has_many :attendances
  has_many :achievements, as: :recipient

  HUMAN_FACTION = 0
  ZOMBIE_FACTION = 1

  FACTION_NAMES = {
    HUMAN_FACTION => 'human',
    ZOMBIE_FACTION => 'zombie',
  }

  validates_uniqueness_of :person_id, :scope => :game_id
  validates_uniqueness_of :card_code, :scope => :game_id
  validates_presence_of :person_id, :game_id, :card_code

  before_validation :set_card_code


  def self.make_code
    chars = %w{ A B C D E F 1 2 3 4 5 6 7 8 9 }
    (0..5).map{ chars.to_a[rand(chars.size)] }.join
  end

  def display_score
    if is_oz && !game.ozs_revealed?
      UpdateGameState.points_for_time_survived((game.since_begin / 1.hour).floor)
    else
      self.score
    end
  end

  def display_faction_id
    return HUMAN_FACTION if is_oz && !game.ozs_revealed?
    faction_id
  end

  def display_time_survived
    return game.since_begin if is_oz && !game.ozs_revealed?
    time_survived
  end

  def has_achievement?(achievement_class)
    achievements.where(type: achievement_class).exists?
  end

  def validate
    errors.add(:base, 'Registration has not yet begun for this game!') if Time.now < self.game.registration_begins
    errors.add(:base, 'Registration has already ended for this game!') if Time.now > self.game.registration_ends
  end

  # Note: These methods are costly and should only be called asynchronously.

  def time_survived
    return 0 if self.is_oz
    tag = self.killing_tag
    real_begins = self.game.game_begins
    if tag
      return [0, tag.datetime - real_begins].max
    else
      return [0, Game.now(self.game) - real_begins].max
    end
  end

  def killing_tag
    # Each human should have only one killing tag. (That is, the tag that turned them
    # into a zombie)
    taggedby.first
  end

  def total_deaths_associated
    # Recursively finds the number of deaths
    # that were involved with a player. Note: This
    # returns 1 for zombies without kills (because
    # they died themselves)
    killing_tag = self.killing_tag
    retval = 0
    if killing_tag.nil?     # E.g. the player is an OZ or human
      retval = self.tagged.map{|x| x.count_resulting_tags}.sum
    else
      retval = killing_tag.count_resulting_tags
    end
    retval += 1 if self.is_oz
    return retval
  end

  def zombietree
    #recursively generates json data for this player's family tree.
    { id: "player#{self.id}", name: self.person.name,
      data: { tags: self.tagged.length },
      children: self.tagged(include: [:tagged, :person]).select(&:tagee).map { |x| x.tagee.zombietree}
    }
  end

  def is_human?
    # A player is human if and only if they have not been tagged in game (i.e. outside a mission)
    self.killing_tag.nil? and not self.is_oz
  end

  def is_zombie?
    # A player is a zombie if they have been tagged in game and have not yet starved.
    return true if self.is_oz
    return (!self.killing_tag.nil?)
  end



  def state_history
    # Returns the times at which the human transitioned between factions, according to the
    # current database.
    #
    # You're going to want to include
    #   :game, :taggedby, :tagged, :feeds
    human_time = self.game.game_begins
    tag = self.killing_tag
    zombie_time = self.game.game_ends
    if self.is_oz
      zombie_time = self.game.game_begins
    end
    if not tag.nil?
      zombie_time = tag.datetime + 1.hour
    end

    { :human => human_time, :zombie => zombie_time}
  end

  def state_at(time = Game.now(game))
    history = state_history

    return :human if (history[:human]..history[:zombie]).cover?(time)
    return :zombie if (history[:zombie]..history[:deceased]).cover?(time)
    return :unknown
  end

  def ==(other)
    return false if self.nil? || other.nil?
    return false if not (self.is_a?(Registration) && other.is_a?(Registration))
    self.id == other.id
  end

private

  def set_card_code
    self.card_code = Registration.make_code if self.card_code.blank?
  end
end
