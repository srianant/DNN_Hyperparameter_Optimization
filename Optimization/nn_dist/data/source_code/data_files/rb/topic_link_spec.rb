require 'rails_helper'

describe TopicLink do

  it { is_expected.to validate_presence_of :url }

  def test_uri
    URI.parse(Discourse.base_url)
  end

  let(:topic) do
    Fabricate(:topic, title: 'unique topic name')
  end

  let(:user) do
    topic.user
  end

  let(:post) { Fabricate(:post) }

  it "can't link to the same topic" do
    ftl = TopicLink.new(url: "/t/#{topic.id}",
                              topic_id: topic.id,
                              link_topic_id: topic.id)
    expect(ftl.valid?).to eq(false)
  end

  describe 'external links' do
    before do
      post = Fabricate(:post, raw: "
http://a.com/
http://b.com/b
http://#{'a'*200}.com/invalid
http://b.com/#{'a'*500}
                        ", user: user, topic: topic)

      TopicLink.extract_from(post)
    end

    it 'works' do
      # has the forum topic links
      expect(topic.topic_links.count).to eq(3)

      # works with markdown links
      expect(topic.topic_links.exists?(url: "http://a.com/")).to eq(true)

      #works with markdown links followed by a period
      expect(topic.topic_links.exists?(url: "http://b.com/b")).to eq(true)
    end

  end

  describe 'internal links' do

    it "extracts onebox" do
      other_topic = Fabricate(:topic, user: user)
      other_topic.posts.create(user: user, raw: "some content for the first post")
      other_post = other_topic.posts.create(user: user, raw: "some content for the second post")

      url = "http://#{test_uri.host}/t/#{other_topic.slug}/#{other_topic.id}/#{other_post.post_number}"
      invalid_url = "http://#{test_uri.host}/t/#{other_topic.slug}/9999999999999999999999999999999"

      topic.posts.create(user: user, raw: 'initial post')
      post = topic.posts.create(user: user, raw: "Link to another topic:\n\n#{url}\n\n#{invalid_url}")
      post.reload

      TopicLink.extract_from(post)

      link = topic.topic_links.first
      # should have a link
      expect(link).to be_present
      # should be the canonical URL
      expect(link.url).to eq(url)
    end


    context 'topic link' do

      let(:other_topic) do
        Fabricate(:topic, user: user)
      end

      let(:post) do
        other_topic.posts.create(user: user, raw: "some content")
      end

      it 'works' do

        # ensure other_topic has a post
        post

        url = "http://#{test_uri.host}/t/#{other_topic.slug}/#{other_topic.id}"

        topic.posts.create(user: user, raw: 'initial post')
        linked_post = topic.posts.create(user: user, raw: "Link to another topic: #{url}")

        # this is subtle, but we had a bug were second time
        # TopicLink.extract_from was called a reflection was nuked
        2.times do
          topic.reload
          TopicLink.extract_from(linked_post)

          link = topic.topic_links.first
          expect(link).to be_present
          expect(link).to be_internal
          expect(link.url).to eq(url)
          expect(link.domain).to eq(test_uri.host)
          link.link_topic_id == other_topic.id
          expect(link).not_to be_reflection

          reflection = other_topic.topic_links.first

          expect(reflection).to be_present
          expect(reflection).to be_reflection
          expect(reflection.post_id).to be_present
          expect(reflection.domain).to eq(test_uri.host)
          expect(reflection.url).to eq("http://#{test_uri.host}/t/unique-topic-name/#{topic.id}/#{linked_post.post_number}")
          expect(reflection.link_topic_id).to eq(topic.id)
          expect(reflection.link_post_id).to eq(linked_post.id)

          expect(reflection.user_id).to eq(link.user_id)
        end

        PostOwnerChanger.new(
          post_ids: [linked_post.id],
          topic_id: topic.id,
          acting_user: user,
          new_owner: Fabricate(:user)
        ).change_owner!

        TopicLink.extract_from(linked_post)
        expect(topic.topic_links.first.url).to eq(url)

        linked_post.revise(post.user, { raw: "no more linkies https://eviltrout.com" })
        expect(other_topic.topic_links.where(link_post_id: linked_post.id)).to be_blank
      end
    end

    context "link to a user on discourse" do
      let(:post) { topic.posts.create(user: user, raw: "<a href='/users/#{user.username_lower}'>user</a>") }
      before do
        TopicLink.extract_from(post)
      end

      it 'does not extract a link' do
        expect(topic.topic_links).to be_blank
      end
    end

    context "link to a discourse resource like a FAQ" do
      let(:post) { topic.posts.create(user: user, raw: "<a href='/faq'>faq link here</a>") }
      before do
        TopicLink.extract_from(post)
      end

      it 'does not extract a link' do
        expect(topic.topic_links).to be_present
      end
    end

    context "mention links" do
      let(:post) { topic.posts.create(user: user, raw: "Hey #{user.username_lower}") }

      before do
        TopicLink.extract_from(post)
      end

      it 'does not extract a link' do
        expect(topic.topic_links).to be_blank
      end
    end

    context "mail link" do
      let(:post) { topic.posts.create(user: user, raw: "[email]bar@example.com[/email]") }

      it 'does not extract a link' do
        TopicLink.extract_from(post)
        expect(topic.topic_links).to be_blank
      end
    end

    context "quote links" do
      it "sets quote correctly" do
        linked_post = topic.posts.create(user: user, raw: "my test post")
        quoting_post = Fabricate(:post, raw: "[quote=\"#{user.username}, post: #{linked_post.post_number}, topic: #{topic.id}\"]\nquote\n[/quote]")

        TopicLink.extract_from(quoting_post)
        link = quoting_post.topic.topic_links.first

        expect(link.link_post_id).to eq(linked_post.id)
        expect(link.quote).to eq(true)
      end
    end

    context "link to a local attachments" do
      let(:post) { topic.posts.create(user: user, raw: '<a class="attachment" href="/uploads/default/208/87bb3d8428eb4783.rb">ruby.rb</a>') }

      it "extracts the link" do
        TopicLink.extract_from(post)
        link = topic.topic_links.first
        # extracted the link
        expect(link).to be_present
        # is set to internal
        expect(link).to be_internal
        # has the correct url
        expect(link.url).to eq("/uploads/default/208/87bb3d8428eb4783.rb")
        # should not be the reflection
        expect(link).not_to be_reflection
      end

    end

    context "link to an attachments uploaded on S3" do
      let(:post) { topic.posts.create(user: user, raw: '<a class="attachment" href="//s3.amazonaws.com/bucket/2104a0211c9ce41ed67989a1ed62e9a394c1fbd1446.rb">ruby.rb</a>') }

      it "extracts the link" do
        TopicLink.extract_from(post)
        link = topic.topic_links.first
        # extracted the link
        expect(link).to be_present
        # is not internal
        expect(link).not_to be_internal
        # has the correct url
        expect(link.url).to eq("//s3.amazonaws.com/bucket/2104a0211c9ce41ed67989a1ed62e9a394c1fbd1446.rb")
        # should not be the reflection
        expect(link).not_to be_reflection
      end

    end

  end

  describe 'internal link from pm' do
    it 'works' do
      pm = Fabricate(:topic, user: user, category_id: nil, archetype: 'private_message')
      pm.posts.create(user: user, raw: "some content")

      url = "http://#{test_uri.host}/t/topic-slug/#{topic.id}"

      pm.posts.create(user: user, raw: 'initial post')
      linked_post = pm.posts.create(user: user, raw: "Link to another topic: #{url}")

      TopicLink.extract_from(linked_post)

      expect(topic.topic_links.first).to eq(nil)
      expect(pm.topic_links.first).not_to eq(nil)
    end

  end

  describe 'internal link with non-standard port' do
    it 'includes the non standard port if present' do
      other_topic = Fabricate(:topic, user: user)
      SiteSetting.port = 5678
      alternate_uri = URI.parse(Discourse.base_url)

      url = "http://#{alternate_uri.host}:5678/t/topic-slug/#{other_topic.id}"
      post = topic.posts.create(user: user, raw: "Link to another topic: #{url}")
      TopicLink.extract_from(post)
      reflection = other_topic.topic_links.first

      expect(reflection.url).to eq("http://#{alternate_uri.host}:5678/t/unique-topic-name/#{topic.id}")
    end
  end

  describe 'query methods' do
    it 'returns blank without posts' do
      expect(TopicLink.counts_for(Guardian.new, nil, nil)).to be_blank
    end

    context 'with data' do

      let(:post) do
        topic = Fabricate(:topic)
        Fabricate(:post_with_external_links, user: topic.user, topic: topic)
      end

      let(:counts_for) do
        TopicLink.counts_for(Guardian.new, post.topic, [post])
      end

      it 'creates a valid topic lookup' do
        TopicLink.extract_from(post)

        lookup = TopicLink.duplicate_lookup(post.topic)
        expect(lookup).to be_present
        expect(lookup['google.com']).to be_present

        ch = lookup['www.codinghorror.com/blog']
        expect(ch).to be_present
        expect(ch[:domain]).to eq('www.codinghorror.com')
        expect(ch[:username]).to eq(post.username)
        expect(ch[:posted_at]).to be_present
        expect(ch[:post_number]).to be_present
      end

      it 'has the correct results' do
        TopicLink.extract_from(post)
        topic_link = post.topic.topic_links.first
        TopicLinkClick.create(topic_link: topic_link, ip_address: '192.168.1.1')

        expect(counts_for[post.id]).to be_present
        expect(counts_for[post.id].find {|l| l[:url] == 'http://google.com'}[:clicks]).to eq(0)
        expect(counts_for[post.id].first[:clicks]).to eq(1)

        array = TopicLink.topic_map(Guardian.new, post.topic_id)
        expect(array.length).to eq(6)
        expect(array[0]["clicks"]).to eq("1")
      end

      it 'secures internal links correctly' do
        category = Fabricate(:category)
        secret_topic = Fabricate(:topic, category: category)

        url = "http://#{test_uri.host}/t/topic-slug/#{secret_topic.id}"
        post = Fabricate(:post, raw: "hello test topic #{url}")
        TopicLink.extract_from(post)

        expect(TopicLink.topic_map(Guardian.new, post.topic_id).count).to eq(1)
        expect(TopicLink.counts_for(Guardian.new, post.topic, [post]).length).to eq(1)

        category.set_permissions(:staff => :full)
        category.save

        admin = Fabricate(:admin)

        expect(TopicLink.topic_map(Guardian.new, post.topic_id).count).to eq(0)
        expect(TopicLink.topic_map(Guardian.new(admin), post.topic_id).count).to eq(1)

        expect(TopicLink.counts_for(Guardian.new, post.topic, [post]).length).to eq(0)
        expect(TopicLink.counts_for(Guardian.new(admin), post.topic, [post]).length).to eq(1)
      end

    end

    describe ".duplicate_lookup" do
      let(:user) { Fabricate(:user, username: "junkrat") }

      let(:post_with_internal_link) do
        Fabricate(:post, user: user, raw: "Check out this topic #{post.topic.url}/122131")
      end

      it "should return the right response" do
        TopicLink.extract_from(post_with_internal_link)

        result = TopicLink.duplicate_lookup(post_with_internal_link.topic)
        expect(result.count).to eq(1)

        lookup = result["test.localhost/t/#{post.topic.slug}/#{post.topic.id}/122131"]

        expect(lookup[:domain]).to eq("test.localhost")
        expect(lookup[:username]).to eq("junkrat")
        expect(lookup[:posted_at].to_s).to eq(post_with_internal_link.created_at.to_s)
        expect(lookup[:post_number]).to eq(1)

        result = TopicLink.duplicate_lookup(post.topic)
        expect(result).to eq({})
      end
    end
  end

end
