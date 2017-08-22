require 'rails_helper'

describe ApplicationRequest do

  before do
    ApplicationRequest.clear_cache!
  end

  def inc(key,opts=nil)
    ApplicationRequest.increment!(key,opts)
  end

  it 'logs nothing for an unflushed increment' do
    ApplicationRequest.increment!(:anon)
    expect(ApplicationRequest.count).to eq(0)
  end

  it 'can automatically flush' do
    t1 = Time.now.utc.at_midnight
    freeze_time(t1)
    inc(:http_total)
    inc(:http_total)
    inc(:http_total, autoflush: 3)

    expect(ApplicationRequest.http_total.first.count).to eq(3)
  end

  it 'can flush based on time' do
    t1 = Time.now.utc.at_midnight
    freeze_time(t1)
    ApplicationRequest.write_cache!
    inc(:http_total)
    expect(ApplicationRequest.count).to eq(0)

    freeze_time(t1 + ApplicationRequest.autoflush_seconds + 1)
    inc(:http_total)

    expect(ApplicationRequest.count).to eq(1)
  end

  it 'flushes yesterdays results' do
    t1 = Time.now.utc.at_midnight
    freeze_time(t1)
    inc(:http_total)
    freeze_time(t1.tomorrow)
    inc(:http_total)

    ApplicationRequest.write_cache!
    expect(ApplicationRequest.count).to eq(2)
  end

  it 'clears cache correctly' do
    # otherwise we have test pollution
    inc(:anon)
    ApplicationRequest.clear_cache!
    ApplicationRequest.write_cache!

    expect(ApplicationRequest.count).to eq(0)
  end

  it 'logs a few counts once flushed' do
    time = Time.now.at_midnight
    freeze_time(time)

    3.times { inc(:http_total) }
    2.times { inc(:http_2xx) }
    4.times { inc(:http_3xx) }

    ApplicationRequest.write_cache!

    expect(ApplicationRequest.http_total.first.count).to eq(3)
    expect(ApplicationRequest.http_2xx.first.count).to eq(2)
    expect(ApplicationRequest.http_3xx.first.count).to eq(4)

  end
end
