require 'active_record'

class Task < ActiveRecord::Base
  include AASM
  belongs_to :user
  validates :subdomain, presence: true
  validates :order_id, presence: true
  validates :code, presence: true
  validates :url, presence: true, length: { maximum: 255 }

  validate :uniqueness_by_order_id_and_code

  scope :active, -> { where(status: [:created, :in_progress]) }

  enum status: { created: 0, in_progress: 1, stopped: 2, canceled: 3 }

  aasm column: 'status', enum: true, timestamps: true do
    state :created, initial: true
    state :in_progress, :stopped, :canceled

    event :restart do
      transitions from: :stopped,
                  to: :created
    end

    event :start do
      transitions from: :created,
                  to: %i[in_progress stopped]
    end

    event :stop do
      transitions from: [:created, :in_progress],
                  to: :stopped
    end

    event :cancel do
      transitions from: %i[created in_progress stopped],
                  to: :canceled
    end
  end

  def uniqueness_by_order_id_and_code
    if Task.where(order_id: order_id, code: code)
      .where.not(id: id)
      .where(status: %i[created in_progress stopped])
      .exists?
      errors.add(:order_id, "Already exists for #{order_id}:#{code}")
    end
  end
end
