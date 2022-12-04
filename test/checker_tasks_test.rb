require_relative 'minitest_helper'

describe CheckerTasks::Create do
  let(:subdomain) { 'istanbul' }
  let(:order_id) { '104681' }
  let(:code) { '345AFDEA' }
  let(:url) { "http://#{subdomain}.kdmid.ru/queue/OrderInfo.aspx?id=#{order_id}&cd=#{code}" }

  before do
    @user = User.create!(uid: 123)
    @service = CheckerTasks::Create.new(url: url, user: @user)
  end

  describe '#call' do
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

    describe 'active task already exists' do
      before do
        @user.tasks.create!(
          subdomain: subdomain,
          order_id: '123',
          code: '123'
        )
      end

      it 'does not add new task' do
        _(@user.tasks.count).must_equal 1
        @service.call
        _(@user.tasks.count).must_equal 1
      end
    end
  end
end
