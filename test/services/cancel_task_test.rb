require_relative '../minitest_helper'

describe Services::CheckerTasks::Cancel do
  let(:subdomain) { 'istanbul' }
  let(:order_id) { '104681' }
  let(:code) { '345AFDEA' }
  let(:url) { "http://#{subdomain}.kdmid.ru/queue/OrderInfo.aspx?id=#{order_id}&cd=#{code}" }

  before do
    @user = User.create!(uid: 123)
    @service = Services::CheckerTasks::Cancel.new(user: @user)
  end

  describe '#call' do
    describe 'there is no task for user' do
      it 'returns false' do
        r = @service.call
        _(r.result).must_equal false
      end
    end

    describe 'task exists' do
      before do
        @user.tasks.create!(
          url: url,
          subdomain: subdomain,
          order_id: order_id,
          code: code,
          status: :created
        )
      end

      it 'returns true' do
        r = @service.call
        _(r.result).must_equal url
      end

      it 'changes task status to created' do
        _(@user.tasks.last.status).must_equal 'created'
        @service.call
        _(@user.tasks.reload.last.status).must_equal 'canceled'
      end
    end
  end
end
