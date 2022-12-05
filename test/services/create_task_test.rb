require_relative '../minitest_helper'

describe Services::CheckerTasks::Create do
  let(:subdomain) { 'istanbul' }
  let(:order_id) { '104681' }
  let(:code) { '345AFDEA' }
  let(:url) { "http://#{subdomain}.kdmid.ru/queue/OrderInfo.aspx?id=#{order_id}&cd=#{code}" }

  before do
    @user = User.create!(uid: 123)
    @service = Services::CheckerTasks::Create.new(url: url, user: @user)
  end

  describe '#call' do
    describe 'url is invalid' do
      let(:url) { "http://#{subdomain}.kdmid.ru/queue/OrderInfo.aspx?id=#{order_id}" }

      it 'adds an error' do
        @service.call
        _(@service.errors[:url]).must_equal [I18n.t('errors.url.invalid')]
      end
    end

    describe 'there is no active task' do
      it 'adds new task with order id and code' do
        _(@user.tasks.count).must_equal 0
        @service.call
        _(@user.tasks.count).must_equal 1
        task = @user.tasks.last
        _(task.subdomain).must_equal subdomain
        _(task.order_id).must_equal order_id
        _(task.code).must_equal code
      end
    end

    describe 'active task with the same params already exists' do
      before do
        @user.tasks.create!(
          url: url,
          subdomain: subdomain,
          order_id: order_id,
          code: code
        )
      end

      it 'does not add new task' do
        _(@user.tasks.count).must_equal 1
        @service.call
        _(@user.tasks.count).must_equal 1
      end
    end

    describe 'stopped task with the same params already exists' do
      before do
        @user.tasks.create!(
          url: url,
          subdomain: subdomain,
          order_id: order_id,
          code: code,
          status: :stopped
        )
      end

      it 'does not add new task' do
        _(@user.tasks.count).must_equal 1
        @service.call
        _(@user.tasks.count).must_equal 1
      end

      it 'changes status to created' do
        _(@user.tasks.last.status).must_equal 'stopped'
        @service.call
        _(@user.tasks.reload.last.status).must_equal 'created'
      end
    end
  end
end
