require 'two_captcha'
require 'watir'
require 'watir-get-image-content'

class QueueChecker
  attr_reader :browser, :client, :current_time, :task, :user
  PASS_CAPTCHA_ATTEMPTS_LIMIT = 5

  def initialize(task)
    @task = task
    @user = task.user
    @link = "http://#{task.subdomain}.kdmid.ru/queue/OrderInfo.aspx?id=#{task.order_id}&cd=#{task.code}"

    @client = TwoCaptcha.new(ENV.fetch('TWO_CAPTCHA_KEY'))
    @current_time = Time.now.utc.to_s
    log 'Init...'

    options = {}
    if ENV['BROWSER_PROFILE']
      options.merge!(profile: ENV['BROWSER_PROFILE'])
    end
    @browser = Watir::Browser.new(
      ENV.fetch('BROWSER').to_sym,
      url: "http://#{ENV.fetch('HUB_HOST')}/wd/hub",
      options: options
    )
  end

  def check_queue
    log "===== Current time: #{current_time} ====="

    create_dirs

    browser.goto @link

    pass_hcaptcha
    pass_ddgcaptcha

    browser.button(id: 'ctl00_MainContent_ButtonA').wait_until(timeout: 30, &:exists?)

    pass_captcha_on_form

    browser.button(id: 'ctl00_MainContent_ButtonA').click

    sleep 3

    if browser.alert.exists?
      browser.alert.ok
    end

    sleep 1

    pass_hcaptcha
    pass_ddgcaptcha

    return if task_code_invalid

    click_make_appointment_button

    save_page

    stop_text_found = browser.p(text: /Извините, но в настоящий момент/).exists? ||
      browser.p(text: /Свободное время в системе записи отсутствует/).exists?

    unless stop_text_found
      task.stop!
      notify_users
    end

    browser.close
    log '=' * 50
  rescue Exception => e
    $logger.error e.inspect
    sleep 3
    browser.close
    raise e
  end

  private

  def task_code_invalid?
    task_code_invalid = browser.div(text: /Защитный код заявки задан неверно/).exists?
    return false unless task_code_invalid

    log "task code invalid"
    task.cancel!
    browser.close
    true
  end

  def log(message)
    log "[#{task.id}] #{message}"
  end

  def notify_users
    Telegram::Bot::Client.run($config.get_token, logger: $logger) do |bot|
      active_tasks_for_subdomain = Taks.active.where(subdomain: task.subdomain).includes(:user)
      active_tasks_for_subdomain.find_each do |t|
        message = I18n.t('new_slot_found_message', link: t.url)
        MessageSender.new(bot: bot, chat_id: t.user.chat_id, username: t.user.username, text: message).send
        t.stop!
      end
    end
  end

  def create_dirs
    %w[captches screenshots pages].each do |folder_name|
      FileUtils.mkdir_p "/files/#{folder_name}"
    end
  end

  def pass_hcaptcha
    sleep 5

    return unless browser.div(id: 'h-captcha').exists?

    sitekey = browser.div(id: 'h-captcha').attribute_value('data-sitekey')
    log "sitekey: #{sitekey} url: #{browser.url}"

    captcha = client.decode_hcaptcha!(sitekey: sitekey, pageurl: browser.url)
    captcha_response = captcha.text
    log "captcha_response: #{captcha_response}"

    3.times do |i|
      log "attempt: #{i}"
      sleep 2
      ['h-captcha-response', 'g-recaptcha-response'].each do |el_name|
        browser.execute_script(
          "document.getElementsByName('#{el_name}')[0].style = '';
           document.getElementsByName('#{el_name}')[0].innerHTML = '#{captcha_response.strip}';
           document.querySelector('iframe').setAttribute('data-hcaptcha-response', '#{captcha_response.strip}');"
        )
      end
      sleep 3
      browser.execute_script("cb();")
      sleep 3
      break unless browser.div(id: 'h-captcha').exists?
    end

    if browser.alert.exists?
      browser.alert.ok
      log 'alert found'
    end
  end

  def pass_ddgcaptcha
    attempt = 1
    sleep 5

    while browser.div(id: 'ddg-captcha').exists? && attempt <= PASS_CAPTCHA_ATTEMPTS_LIMIT
      log "attempt: [#{attempt}] let's find the ddg captcha image..."

      checkbox = browser.div(id: 'ddg-captcha')
      checkbox.wait_until(timeout: 60, &:exists?)
      checkbox.click

      captcha_image = browser.iframe(id: 'ddg-iframe').images(class: 'ddg-modal__captcha-image').first
      captcha_image.wait_until(timeout: 5, &:exists?)

      log 'save captcha image to file...'
      sleep 3
      image_filepath = "/files/captches/#{task.id}-#{current_time}.png"
      base64_to_file(captcha_image.src, image_filepath)

      log 'decode captcha...'
      captcha = client.decode!(path: image_filepath)
      captcha_code = captcha.text
      log "captcha_code: #{captcha_code}"

      # log 'Enter code:'
      # code = gets
      # log code

      text_field = browser.iframe(id: 'ddg-iframe').text_field(class: 'ddg-modal__input')
      text_field.set captcha_code
      browser.iframe(id: 'ddg-iframe').button(class: 'ddg-modal__submit').click

      if browser.alert.exists?
        browser.alert.ok
        log 'alert found'
      end

      attempt += 1
      sleep 15
    end
  end

  def base64_to_file(base64_data, filename=nil)
    start_regex = /data:image\/[a-z]{3,4};base64,/
    filename ||= SecureRandom.hex

    regex_result = start_regex.match(base64_data)
    start = regex_result.to_s

    File.open(filename, 'wb') do |file|
      file.write(Base64.decode64(base64_data[start.length..-1]))
    end
  end

  def pass_captcha_on_form
    sleep 3

    if browser.alert.exists?
      browser.alert.ok
      log 'alert found'
    end

    log "let's find the captcha image..."
    captcha_image = browser.images(id: 'ctl00_MainContent_imgSecNum').first
    captcha_image.wait_until(timeout: 5, &:exists?)

    log 'save captcha image to file...'
    image_filepath = "/files/captches/#{task.id}-#{current_time}.png"
    File.write(image_filepath, captcha_image.to_png)

    log 'decode captcha...'
    captcha = client.decode!(path: image_filepath)
    captcha_code = captcha.text
    log "captcha_code: #{captcha_code}"

    # log 'Enter code:'
    # code = gets
    # log code

    text_field = browser.text_field(id: 'ctl00_MainContent_txtCode')
    text_field.set captcha_code
  end

  def click_make_appointment_button
    make_appointment_btn = browser.button(id: 'ctl00_MainContent_ButtonB')
    make_appointment_btn.wait_until(timeout: 60, &:exists?)
    make_appointment_btn.click
  end

  def save_page
    browser.screenshot.save "/files/screenshots/#{task.id}-#{current_time}.png"
    File.open("/files/pages/#{task.id}-#{current_time}.html", 'w') { |f| f.write browser.html }
  end
end
