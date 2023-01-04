require './models/user'
require './models/task'
require './lib/message_sender'

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

    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        answer_with_greeting_message
      when '/help'
        answer_with_help_message
      when '/end'
        cancel_task = Services::CheckerTasks::Cancel.call(user: @user)
        if cancel_task.success? && cancel_task.result
          answer_with_message(I18n.t('task_removed_message', link: cancel_task.result))
        end
        answer_with_farewell_message
      when Services::CheckerTasks::Create::KDMID_URL_REGEXP
        handle_kdmid_url_message
      else
        answer_with_message(I18n.t('dont_understand_message'))
      end
    end
  end

  private

  def handle_kdmid_url_message
    create_task = Services::CheckerTasks::Create.call(url: message.text.strip, user: @user)
    if create_task.success? && create_task.result
      answer_with_message(I18n.t('task_added_message'))
      answer_with_message(I18n.t('donation_message'))
    else
      answer_with_message(I18n.t('url_invalid_message')) if create_task.errors[:url].any?
    end
  end

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

  def answer_with_help_message
    answer_with_message I18n.t('help_message')
  end

  def answer_with_farewell_message
    answer_with_message I18n.t('farewell_message')
  end

  def answer_with_message(text)
    MessageSender.new(bot: bot, chat_id: message.chat.id, username: message.chat.username, text: text).send
  end
end
