# encoding: utf-8

require 'rails_helper'
require_dependency 'search'

describe Search do

  class TextHelper
    extend ActionView::Helpers::TextHelper
  end

  before do
    ActiveRecord::Base.observers.enable :search_observer
  end

  context 'post indexing observer' do
    before do
      @category = Fabricate(:category, name: 'america')
      @topic = Fabricate(:topic, title: 'sam saffron test topic', category: @category)
      @post = Fabricate(:post, topic: @topic, raw: 'this <b>fun test</b> <img src="bla" title="my image">')
      @indexed = @post.post_search_data.search_data
    end

    it "should index correctly" do
      expect(@indexed).to match(/fun/)
      expect(@indexed).to match(/sam/)
      expect(@indexed).to match(/america/)

      @topic.title = "harpi is the new title"
      @topic.save!
      @post.post_search_data.reload

      @indexed = @post.post_search_data.search_data

      expect(@indexed).to match(/harpi/)
    end
  end

  context 'user indexing observer' do
    before do
      @user = Fabricate(:user, username: 'fred', name: 'bob jones')
      @indexed = @user.user_search_data.search_data
    end

    it "should pick up on data" do
      expect(@indexed).to match(/fred/)
      expect(@indexed).to match(/jone/)
    end
  end

  context 'category indexing observer' do
    before do
      @category = Fabricate(:category, name: 'america')
      @indexed = @category.category_search_data.search_data
    end

    it "should pick up on name" do
      expect(@indexed).to match(/america/)
    end

  end

  it 'does not search when the search term is too small' do
    search = Search.new('evil', min_search_term_length: 5)
    search.execute
    expect(search.valid?).to eq(false)
    expect(search.term).to eq('')
  end

  it 'needs at least one term that hits the length' do
    search = Search.new('a b c d', min_search_term_length: 5)
    search.execute
    expect(search.valid?).to eq(false)
    expect(search.term).to eq('')
  end

  it 'searches for quoted short terms' do
    search = Search.new('"a b c d"', min_search_term_length: 5)
    search.execute
    expect(search.valid?).to eq(true)
    expect(search.term).to eq('"a b c d"')
  end

  it 'searches for short terms if one hits the length' do
    search = Search.new('a b c okaylength', min_search_term_length: 5)
    search.execute
    expect(search.valid?).to eq(true)
    expect(search.term).to eq('a b c okaylength')
  end

  it 'escapes non alphanumeric characters' do
    expect(Search.execute('foo :!$);}]>@\#\"\'').posts.length).to eq(0) # There are at least three levels of sanitation for Search.query!
  end

  it "doesn't raise an error when single quotes are present" do
    expect(Search.execute("'hello' world").posts.length).to eq(0) # There are at least three levels of sanitation for Search.query!
  end

  it 'works when given two terms with spaces' do
    expect { Search.execute('evil trout') }.not_to raise_error
  end

  context 'users' do
    let!(:user) { Fabricate(:user) }
    let(:result) { Search.execute('bruce', type_filter: 'user') }

    it 'returns a result' do
      expect(result.users.length).to eq(1)
      expect(result.users[0].id).to eq(user.id)
    end

    context 'hiding user profiles' do
      before { SiteSetting.stubs(:hide_user_profiles_from_public).returns(true) }

      it 'returns no result for anon' do
        expect(result.users.length).to eq(0)
      end

      it 'returns a result for logged in users' do
        result = Search.execute('bruce', type_filter: 'user', guardian: Guardian.new(user))
        expect(result.users.length).to eq(1)
      end

    end

  end

  context 'inactive users' do
    let!(:inactive_user) { Fabricate(:inactive_user, active: false) }
    let(:result) { Search.execute('bruce') }

    it 'does not return a result' do
      expect(result.users.length).to eq(0)
    end
  end

  context 'staged users' do
    let(:staged) { Fabricate(:staged) }
    let(:result) { Search.execute(staged.username) }

    it 'does not return a result' do
      expect(result.users.length).to eq(0)
    end
  end

  context 'private messages' do

    let(:topic) {
      Fabricate(:topic,
                  category_id: nil,
                  archetype: 'private_message')
    }

    let(:post) { Fabricate(:post, topic: topic) }
    let(:reply) { Fabricate(:post, topic: topic,
                                   raw: 'hello from mars, we just landed') }



    it 'searches correctly' do

       expect do
         Search.execute('mars', type_filter: 'private_messages')
       end.to raise_error(Discourse::InvalidAccess)

       TopicAllowedUser.create!(user_id: reply.user_id, topic_id: topic.id)
       TopicAllowedUser.create!(user_id: post.user_id, topic_id: topic.id)

       results = Search.execute('mars',
                                type_filter: 'private_messages',
                                guardian: Guardian.new(reply.user))

       expect(results.posts.length).to eq(1)


       results = Search.execute('mars',
                                search_context: topic,
                                guardian: Guardian.new(reply.user))

       expect(results.posts.length).to eq(1)

       # does not leak out
       results = Search.execute('mars',
                                type_filter: 'private_messages',
                                guardian: Guardian.new(Fabricate(:user)))

       expect(results.posts.length).to eq(0)

       Fabricate(:topic, category_id: nil, archetype: 'private_message')
       Fabricate(:post, topic: topic, raw: 'another secret pm from mars, testing')


       # admin can search everything with correct context
       results = Search.execute('mars',
                                type_filter: 'private_messages',
                                search_context: post.user,
                                guardian: Guardian.new(Fabricate(:admin)))

       expect(results.posts.length).to eq(1)

    end

  end

  context 'topics' do
    let(:post) { Fabricate(:post) }
    let(:topic) { post.topic}


    context 'search within topic' do

      def new_post(raw, topic)
        Fabricate(:post, topic: topic, topic_id: topic.id, user: topic.user, raw: raw)
      end

      it 'displays multiple results within a topic' do

        topic = Fabricate(:topic)
        topic2 = Fabricate(:topic)

        new_post('this is the other post I am posting', topic2)
        new_post('this is my fifth post I am posting', topic2)

        post1 = new_post('this is the other post I am posting', topic)
        post2 = new_post('this is my first post I am posting', topic)
        post3 = new_post('this is a real long and complicated bla this is my second post I am Posting birds
                         with more stuff bla bla', topic)
        post4 = new_post('this is my fourth post I am posting', topic)

        # update posts_count
        topic.reload

        results = Search.execute('posting', search_context: post1.topic)
        expect(results.posts.map(&:id)).to eq([post1.id, post2.id, post3.id, post4.id])

        # stop words should work
        results = Search.execute('this', search_context: post1.topic)
        expect(results.posts.length).to eq(4)

        # phrase search works as expected
        results = Search.execute('"fourth post I am posting"', search_context: post1.topic)
        expect(results.posts.length).to eq(1)
      end
    end

    context 'searching the OP' do
      let!(:post) { Fabricate(:post_with_long_raw_content) }
      let(:result) { Search.execute('hundred', type_filter: 'topic', include_blurbs: true) }

      it 'returns a result correctly' do
        expect(result.posts.length).to eq(1)
        expect(result.posts[0].id).to eq(post.id)
      end
    end

    context 'searching for a post' do
      let!(:reply) { Fabricate(:basic_reply, topic: topic, user: topic.user) }
      let(:result) { Search.execute('quotes', type_filter: 'topic', include_blurbs: true) }

      it 'returns the post' do
        expect(result).to be_present
        expect(result.posts.length).to eq(1)
        p = result.posts[0]
        expect(p.topic.id).to eq(topic.id)
        expect(p.id).to eq(reply.id)
        expect(result.blurb(p)).to eq("this reply has no quotes")
      end
    end

    context "search for a topic by id" do
      let(:result) { Search.execute(topic.id, type_filter: 'topic', search_for_id: true, min_search_term_length: 1) }

      it 'returns the topic' do
        expect(result.posts.length).to eq(1)
        expect(result.posts.first.id).to eq(post.id)
      end
    end

    context "search for a topic by url" do
      let(:result) { Search.execute(topic.relative_url, search_for_id: true, type_filter: 'topic')}

      it 'returns the topic' do
        expect(result.posts.length).to eq(1)
        expect(result.posts.first.id).to eq(post.id)
      end
    end

    context 'security' do

      def result(current_user)
        Search.execute('hello', guardian: Guardian.new(current_user))
      end

      it 'secures results correctly' do
        category = Fabricate(:category)

        topic.category_id = category.id
        topic.save

        category.set_permissions(:staff => :full)
        category.save

        expect(result(nil).posts).not_to be_present
        expect(result(Fabricate(:user)).posts).not_to be_present
        expect(result(Fabricate(:admin)).posts).to be_present

      end
    end

  end

  context 'cyrillic topic' do
    let!(:cyrillic_topic) { Fabricate(:topic) do
                                                user
                                                title { sequence(:title) { |i| "Тестовая запись #{i}" } }
                                              end
    }
    let!(:post) {Fabricate(:post, topic: cyrillic_topic, user: cyrillic_topic.user)}
    let(:result) { Search.execute('запись') }

    it 'finds something when given cyrillic query' do
      expect(result.posts).to be_present
    end
  end

  it 'does not tokenize search term' do
    Fabricate(:post, raw: 'thing is canned should still be found!')
    expect(Search.execute('canned').posts).to be_present
  end

  context 'categories' do

    let!(:category) { Fabricate(:category) }
    def search
      Search.execute(category.name)
    end

    it 'returns the correct result' do
      expect(search.categories).to be_present

      category.set_permissions({})
      category.save

      expect(search.categories).not_to be_present
    end

  end


  context 'type_filter' do

    let!(:user) { Fabricate(:user, username: 'amazing', email: 'amazing@amazing.com') }
    let!(:category) { Fabricate(:category, name: 'amazing category', user: user) }


    context 'user filter' do
      let(:results) { Search.execute('amazing', type_filter: 'user') }

      it "returns a user result" do
        expect(results.categories.length).to eq(0)
        expect(results.posts.length).to eq(0)
        expect(results.users.length).to eq(1)
      end

    end

    context 'category filter' do
      let(:results) { Search.execute('amazing', type_filter: 'category') }

      it "returns a category result" do
        expect(results.categories.length).to eq(1)
        expect(results.posts.length).to eq(0)
        expect(results.users.length).to eq(0)
      end

    end

  end

  context 'search_context' do

    it 'can find a user when using search context' do

      coding_horror = Fabricate(:coding_horror)
      post = Fabricate(:post)

      Fabricate(:post, user: coding_horror)

      result = Search.execute('hello', search_context: post.user)

      result.posts.first.topic_id = post.topic_id
      expect(result.posts.length).to eq(1)
    end

    it 'can use category as a search context' do
      category = Fabricate(:category)
      topic = Fabricate(:topic, category: category)
      topic_no_cat = Fabricate(:topic)

      post = Fabricate(:post, topic: topic, user: topic.user )
      _another_post = Fabricate(:post, topic: topic_no_cat, user: topic.user )

      search = Search.execute('hello', search_context: category)
      expect(search.posts.length).to eq(1)
      expect(search.posts.first.id).to eq(post.id)
    end

  end

  describe 'Chinese search' do
    it 'splits English / Chinese' do
      SiteSetting.default_locale = 'zh_CN'
      data = Search.prepare_data('Discourse社区指南').split(' ')
      expect(data).to eq(['Discourse', '社区','指南'])
    end

    it 'finds chinese topic based on title' do
      skip("skipped until pg app installs the db correctly") if RbConfig::CONFIG["arch"] =~ /darwin/

      SiteSetting.default_locale = 'zh_TW'
      SiteSetting.min_search_term_length = 1
      topic = Fabricate(:topic, title: 'My Title Discourse社區指南')
      post = Fabricate(:post, topic: topic)

      expect(Search.execute('社區指南').posts.first.id).to eq(post.id)
      expect(Search.execute('指南').posts.first.id).to eq(post.id)
    end

    it 'finds chinese topic based on title if tokenization is forced' do
      skip("skipped until pg app installs the db correctly") if RbConfig::CONFIG["arch"] =~ /darwin/

      SiteSetting.search_tokenize_chinese_japanese_korean = true
      SiteSetting.min_search_term_length = 1

      topic = Fabricate(:topic, title: 'My Title Discourse社區指南')
      post = Fabricate(:post, topic: topic)

      expect(Search.execute('社區指南').posts.first.id).to eq(post.id)
      expect(Search.execute('指南').posts.first.id).to eq(post.id)
    end
  end

  describe 'Advanced search' do

    it 'supports pinned and unpinned' do
      topic = Fabricate(:topic)
      Fabricate(:post, raw: 'hi this is a test 123 123', topic: topic)
      _post = Fabricate(:post, raw: 'boom boom shake the room', topic: topic)

      topic.update_pinned(true)

      user = Fabricate(:user)
      guardian = Guardian.new(user)

      expect(Search.execute('boom in:pinned').posts.length).to eq(1)
      expect(Search.execute('boom in:unpinned', guardian: guardian).posts.length).to eq(0)

      topic.clear_pin_for(user)

      expect(Search.execute('boom in:unpinned', guardian: guardian).posts.length).to eq(1)
    end

    it 'supports wiki' do
      topic = Fabricate(:topic)
      Fabricate(:post, raw: 'this is a test 248', wiki: true, topic: topic)

      expect(Search.execute('test 248 in:wiki').posts.length).to eq(1)
    end

    it 'supports before and after, in:first, user:, @username' do

      time = Time.zone.parse('2001-05-20 2:55')
      freeze_time(time)

      topic = Fabricate(:topic)
      Fabricate(:post, raw: 'hi this is a test 123 123', topic: topic, created_at: time.months_ago(2))
      _post = Fabricate(:post, raw: 'boom boom shake the room', topic: topic)

      expect(Search.execute('test before:1').posts.length).to eq(1)
      expect(Search.execute('test before:2001-04-20').posts.length).to eq(1)
      expect(Search.execute('test before:2001').posts.length).to eq(0)
      expect(Search.execute('test before:monday').posts.length).to eq(1)

      expect(Search.execute('test after:jan').posts.length).to eq(1)

      expect(Search.execute('test in:first').posts.length).to eq(1)
      expect(Search.execute('boom').posts.length).to eq(1)
      expect(Search.execute('boom in:first').posts.length).to eq(0)

      expect(Search.execute('user:nobody').posts.length).to eq(0)
      expect(Search.execute("user:#{_post.user.username}").posts.length).to eq(1)
      expect(Search.execute("user:#{_post.user_id}").posts.length).to eq(1)

      expect(Search.execute("@#{_post.user.username}").posts.length).to eq(1)
    end

    it 'supports group' do
      topic = Fabricate(:topic, created_at: 3.months.ago)
      post = Fabricate(:post, raw: 'hi this is a test 123 123', topic: topic)

      group = Group.create!(name: "Like_a_Boss")
      GroupUser.create!(user_id: post.user_id, group_id: group.id)

      expect(Search.execute('group:like_a_boss').posts.length).to eq(1)
      expect(Search.execute('group:"like a brick"').posts.length).to eq(0)
    end

    it 'supports badge' do

      topic = Fabricate(:topic, created_at: 3.months.ago)
      post = Fabricate(:post, raw: 'hi this is a test 123 123', topic: topic)

      badge = Badge.create!(name: "Like a Boss", badge_type_id: 1)
      UserBadge.create!(user_id: post.user_id, badge_id: badge.id, granted_at: 1.minute.ago, granted_by_id: -1)

      expect(Search.execute('badge:"like a boss"').posts.length).to eq(1)
      expect(Search.execute('badge:"test"').posts.length).to eq(0)
    end

    it 'can search numbers correctly, and match exact phrases' do
      topic = Fabricate(:topic, created_at: 3.months.ago)
      Fabricate(:post, raw: '3.0 eta is in 2 days horrah', topic: topic)

      expect(Search.execute('3.0 eta').posts.length).to eq(1)
      expect(Search.execute('"3.0, eta is"').posts.length).to eq(0)
    end

    it 'can find by status' do
      post = Fabricate(:post, raw: 'hi this is a test 123 123')
      topic = post.topic

      expect(Search.execute('test status:closed').posts.length).to eq(0)
      expect(Search.execute('test status:open').posts.length).to eq(1)
      expect(Search.execute('test posts_count:1').posts.length).to eq(1)

      topic.closed = true
      topic.save

      expect(Search.execute('test status:closed').posts.length).to eq(1)
      expect(Search.execute('status:closed').posts.length).to eq(1)
      expect(Search.execute('test status:open').posts.length).to eq(0)

      topic.archived = true
      topic.closed = false
      topic.save

      expect(Search.execute('test status:archived').posts.length).to eq(1)
      expect(Search.execute('test status:open').posts.length).to eq(0)

      expect(Search.execute('test status:noreplies').posts.length).to eq(1)

      expect(Search.execute('test in:likes', guardian: Guardian.new(topic.user)).posts.length).to eq(0)

      expect(Search.execute('test in:posted', guardian: Guardian.new(topic.user)).posts.length).to eq(1)

      TopicUser.change(topic.user.id, topic.id, notification_level: TopicUser.notification_levels[:tracking])
      expect(Search.execute('test in:watching', guardian: Guardian.new(topic.user)).posts.length).to eq(0)
      expect(Search.execute('test in:tracking', guardian: Guardian.new(topic.user)).posts.length).to eq(1)

    end

    it 'can find by latest' do
      topic1 = Fabricate(:topic, title: 'I do not like that Sam I am')
      post1 = Fabricate(:post, topic: topic1)

      post2 = Fabricate(:post, raw: 'that Sam I am, that Sam I am')

      expect(Search.execute('sam').posts.map(&:id)).to eq([post1.id, post2.id])
      expect(Search.execute('sam order:latest').posts.map(&:id)).to eq([post2.id, post1.id])

    end

    it 'can tokenize dots' do
      post = Fabricate(:post, raw: 'Will.2000 Will.Bob.Bill...')
      expect(Search.execute('bill').posts.map(&:id)).to eq([post.id])
    end

    it 'supports category slug and tags' do
      # main category
      category = Fabricate(:category, name: 'category 24', slug: 'category-24')
      topic = Fabricate(:topic, created_at: 3.months.ago, category: category)
      post = Fabricate(:post, raw: 'hi this is a test 123', topic: topic)

      expect(Search.execute('this is a test #category-24').posts.length).to eq(1)
      expect(Search.execute("this is a test category:#{category.id}").posts.length).to eq(1)
      expect(Search.execute('this is a test #category-25').posts.length).to eq(0)

      # sub category
      sub_category = Fabricate(:category, name: 'sub category', slug: 'sub-category', parent_category_id: category.id)
      second_topic = Fabricate(:topic, created_at: 3.months.ago, category: sub_category)
      Fabricate(:post, raw: 'hi testing again 123', topic: second_topic)

      expect(Search.execute('testing again #category-24:sub-category').posts.length).to eq(1)
      expect(Search.execute("testing again category:#{category.id}").posts.length).to eq(2)
      expect(Search.execute("testing again category:#{sub_category.id}").posts.length).to eq(1)
      expect(Search.execute('testing again #sub-category').posts.length).to eq(0)

      # tags
      topic.tags = [Fabricate(:tag, name: 'alpha')]
      expect(Search.execute('this is a test #alpha').posts.map(&:id)).to eq([post.id])
      expect(Search.execute('this is a test #beta').posts.size).to eq(0)
    end

    it "can find with tag" do
      topic1 = Fabricate(:topic, title: 'Could not, would not, on a boat')
      topic1.tags = [Fabricate(:tag, name: 'eggs'), Fabricate(:tag, name: 'ham')]
      Fabricate(:post, topic: topic1)
      post2 = Fabricate(:post, topic: topic1, raw: "It probably doesn't help that they're green...")

      expect(Search.execute('green tags:eggs').posts.map(&:id)).to eq([post2.id])
      expect(Search.execute('green tags:plants').posts.size).to eq(0)
    end
  end

  it 'can parse complex strings using ts_query helper' do
    str = " grigio:babel deprecated? "
    str << "page page on Atmosphere](https://atmospherejs.com/grigio/babel)xxx: aaa.js:222 aaa'\"bbb"

    ts_query = Search.ts_query(str, "simple")
    Post.exec_sql("SELECT to_tsvector('bbb') @@ " << ts_query)
  end

  context '#word_to_date' do
    it 'parses relative dates correctly' do
      time = Time.zone.parse('2001-02-20 2:55')
      freeze_time(time)

      expect(Search.word_to_date('yesterday')).to eq(time.beginning_of_day.yesterday)
      expect(Search.word_to_date('suNday')).to eq(Time.zone.parse('2001-02-18'))
      expect(Search.word_to_date('thursday')).to eq(Time.zone.parse('2001-02-15'))
      expect(Search.word_to_date('deCember')).to eq(Time.zone.parse('2000-12-01'))
      expect(Search.word_to_date('deC')).to eq(Time.zone.parse('2000-12-01'))
      expect(Search.word_to_date('january')).to eq(Time.zone.parse('2001-01-01'))
      expect(Search.word_to_date('jan')).to eq(Time.zone.parse('2001-01-01'))


      expect(Search.word_to_date('100')).to eq(time.beginning_of_day.days_ago(100))

      expect(Search.word_to_date('invalid')).to eq(nil)
    end

    it 'parses absolute dates correctly' do
      expect(Search.word_to_date('2001-1-20')).to eq(Time.zone.parse('2001-01-20'))
      expect(Search.word_to_date('2030-10-2')).to eq(Time.zone.parse('2030-10-02'))
      expect(Search.word_to_date('2030-10')).to eq(Time.zone.parse('2030-10-01'))
      expect(Search.word_to_date('2030')).to eq(Time.zone.parse('2030-01-01'))
      expect(Search.word_to_date('2030-01-32')).to eq(nil)
      expect(Search.word_to_date('10000')).to eq(nil)
    end
  end

  context "#min_post_id" do
    it "returns 0 when prefer_recent_posts is disabled" do
      SiteSetting.search_prefer_recent_posts = false
      expect(Search.min_post_id_no_cache).to eq(0)
    end

    it "returns a value when prefer_recent_posts is enabled" do
      SiteSetting.search_prefer_recent_posts = true
      SiteSetting.search_recent_posts_size = 1

      Fabricate(:post)
      p2 = Fabricate(:post)

      expect(Search.min_post_id_no_cache).to eq(p2.id)
    end
  end

end
