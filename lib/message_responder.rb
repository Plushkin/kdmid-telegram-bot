require './models/user'
require './models/task'
require './lib/message_sender'
require './lib/checker_tasks/create'
require './lib/queue_checker'

class MessageResponder
  attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
  end

  def respond
    create_user

    on /^\/start/ do
      answer_with_greeting_message
    end

    on /^\/stop/ do
      answer_with_farewell_message
    end

    on CheckerTasks::Create::KDMID_URL_REGEXP do
      CheckerTasks::Create.new(url: message.text.strip, user: @user).call
      answer_with_message('Check started!')
    end
  end

  private

  def create_user
    @user = User.find_or_create_by!(uid: message.from.id, username: message.chat.username)
    @user.update!(chat_id: message.chat.id)
  end

  def on regex, &block
    regex =~ message.text

    if $~
      case block.arity
      when 0
        yield
      when 1
        yield $1
      when 2
        yield $1, $2
      end
    end
  end

  def answer_with_greeting_message
    answer_with_message I18n.t('greeting_message')
  end

  def answer_with_farewell_message
    answer_with_message I18n.t('farewell_message')
  end

  def answer_with_message(text)
    MessageSender.new(bot: bot, chat_id: message.chat.id, username: message.chat.username, text: text).send
  end
end
