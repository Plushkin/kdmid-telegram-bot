require 'active_record'

class Task < ActiveRecord::Base
  include AASM
  belongs_to :user
  validates :subdomain, presence: true
  validates :order_id, presence: true
  validates :code, presence: true

  validates :order_id, uniqueness: { scope: :code }

  scope :active, -> { where(status: [:created, :in_progress]) }

  enum status: { created: 0, in_progress: 1, stopped: 2, canceled: 3 }

  aasm column: 'status', enum: true do
    state :created, initial: true
    state :in_progress, :stopped, :canceled

    event :start do
      transitions from: :created,
                  to: %i[in_progress stopped]
    end

    event :stop do
      transitions from: :in_progress,
                  to: :stopped
    end

    event :cancel do
      transitions from: %i[created in_progress stopped],
                  to: :canceled
    end
  end
end
