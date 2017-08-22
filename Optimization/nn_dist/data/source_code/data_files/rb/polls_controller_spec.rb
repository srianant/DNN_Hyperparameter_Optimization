require "rails_helper"
require_relative "../helpers"

describe ::DiscoursePoll::PollsController do
  routes { ::DiscoursePoll::Engine.routes }

  let!(:user) { log_in }
  let(:topic) { Fabricate(:topic) }
  let(:poll)  { Fabricate(:post, topic_id: topic.id, user_id: user.id, raw: "[poll]\n- A\n- B\n[/poll]") }

  describe "#vote" do

    it "works" do
      MessageBus.expects(:publish)

      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["5c24fc1df56d764b550ceae1b9319125"] }

      expect(response).to be_success
      json = ::JSON.parse(response.body)
      expect(json["poll"]["name"]).to eq("poll")
      expect(json["poll"]["voters"]).to eq(1)
      expect(json["vote"]).to eq(["5c24fc1df56d764b550ceae1b9319125"])
    end

    it "requires at least 1 valid option" do
      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["A", "B"] }

      expect(response).not_to be_success
      json = ::JSON.parse(response.body)
      expect(json["errors"][0]).to eq(I18n.t("poll.requires_at_least_1_valid_option"))
    end

    it "supports vote changes" do
      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["5c24fc1df56d764b550ceae1b9319125"] }
      expect(response).to be_success

      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["e89dec30bbd9bf50fabf6a05b4324edf"] }
      expect(response).to be_success
      json = ::JSON.parse(response.body)
      expect(json["poll"]["voters"]).to eq(1)
      expect(json["poll"]["options"][0]["votes"]).to eq(0)
      expect(json["poll"]["options"][1]["votes"]).to eq(1)
    end

    it "works even if topic is closed" do
      topic.update_attribute(:closed, true)
      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["5c24fc1df56d764b550ceae1b9319125"] }
      expect(response).to be_success
    end

    it "ensures topic is not archived" do
      topic.update_attribute(:archived, true)
      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["A"] }
      expect(response).not_to be_success
      json = ::JSON.parse(response.body)
      expect(json["errors"][0]).to eq(I18n.t("poll.topic_must_be_open_to_vote"))
    end

    it "ensures post is not trashed" do
      poll.trash!
      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["A"] }
      expect(response).not_to be_success
      json = ::JSON.parse(response.body)
      expect(json["errors"][0]).to eq(I18n.t("poll.post_is_deleted"))
    end

    it "ensures polls are associated with the post" do
      xhr :put, :vote, { post_id: Fabricate(:post).id, poll_name: "foobar", options: ["A"] }
      expect(response).not_to be_success
      json = ::JSON.parse(response.body)
      expect(json["errors"][0]).to eq(I18n.t("poll.no_polls_associated_with_this_post"))
    end

    it "checks the name of the poll" do
      xhr :put, :vote, { post_id: poll.id, poll_name: "foobar", options: ["A"] }
      expect(response).not_to be_success
      json = ::JSON.parse(response.body)
      expect(json["errors"][0]).to eq(I18n.t("poll.no_poll_with_this_name", name: "foobar"))
    end

    it "ensures poll is open" do
      closed_poll = Fabricate(:post, raw: "[poll status=closed]\n- A\n- B\n[/poll]")
      xhr :put, :vote, { post_id: closed_poll.id, poll_name: "poll", options: ["A"] }
      expect(response).not_to be_success
      json = ::JSON.parse(response.body)
      expect(json["errors"][0]).to eq(I18n.t("poll.poll_must_be_open_to_vote"))
    end

    it "doesn't discard anonymous votes when someone votes" do
      default_poll = poll.custom_fields["polls"]["poll"]
      add_anonymous_votes(poll, default_poll, 17, {"5c24fc1df56d764b550ceae1b9319125" => 11, "e89dec30bbd9bf50fabf6a05b4324edf" => 6})

      xhr :put, :vote, { post_id: poll.id, poll_name: "poll", options: ["5c24fc1df56d764b550ceae1b9319125"] }
      expect(response).to be_success

      json = ::JSON.parse(response.body)
      expect(json["poll"]["voters"]).to eq(18)
      expect(json["poll"]["options"][0]["votes"]).to eq(12)
      expect(json["poll"]["options"][1]["votes"]).to eq(6)
    end

    it "tracks the users ids for public polls" do
      public_poll = Fabricate(:post, topic_id: topic.id, user_id: user.id, raw: "[poll public=true]\n- A\n- B\n[/poll]")
      body = { post_id: public_poll.id, poll_name: "poll" }

      message = MessageBus.track_publish do
        xhr :put, :vote, body.merge(options: ["5c24fc1df56d764b550ceae1b9319125"])
      end.first

      expect(response).to be_success

      json = ::JSON.parse(response.body)
      expect(json["poll"]["voters"]).to eq(1)
      expect(json["poll"]["options"][0]["votes"]).to eq(1)
      expect(json["poll"]["options"][1]["votes"]).to eq(0)
      expect(json["poll"]["options"][0]["voter_ids"]).to eq([user.id])
      expect(json["poll"]["options"][1]["voter_ids"]).to eq([])
      expect(message.data[:post_id].to_i).to eq(public_poll.id)
      expect(message.data[:user][:id].to_i).to eq(user.id)

      xhr :put, :vote, body.merge(options: ["e89dec30bbd9bf50fabf6a05b4324edf"])
      expect(response).to be_success

      json = ::JSON.parse(response.body)
      expect(json["poll"]["voters"]).to eq(1)
      expect(json["poll"]["options"][0]["votes"]).to eq(0)
      expect(json["poll"]["options"][1]["votes"]).to eq(1)
      expect(json["poll"]["options"][0]["voter_ids"]).to eq([])
      expect(json["poll"]["options"][1]["voter_ids"]).to eq([user.id])

      another_user = Fabricate(:user)
      log_in_user(another_user)

      xhr :put, :vote, body.merge(options: ["e89dec30bbd9bf50fabf6a05b4324edf", "5c24fc1df56d764b550ceae1b9319125"])
      expect(response).to be_success

      json = ::JSON.parse(response.body)
      expect(json["poll"]["voters"]).to eq(2)
      expect(json["poll"]["options"][0]["votes"]).to eq(1)
      expect(json["poll"]["options"][1]["votes"]).to eq(2)
      expect(json["poll"]["options"][0]["voter_ids"]).to eq([another_user.id])
      expect(json["poll"]["options"][1]["voter_ids"]).to eq([user.id, another_user.id])
    end
  end

  describe "#toggle_status" do

    it "works for OP" do
      MessageBus.expects(:publish)

      xhr :put, :toggle_status, { post_id: poll.id, poll_name: "poll", status: "closed" }
      expect(response).to be_success
      json = ::JSON.parse(response.body)
      expect(json["poll"]["status"]).to eq("closed")
    end

    it "works for staff" do
      log_in(:moderator)
      MessageBus.expects(:publish)

      xhr :put, :toggle_status, { post_id: poll.id, poll_name: "poll", status: "closed" }
      expect(response).to be_success
      json = ::JSON.parse(response.body)
      expect(json["poll"]["status"]).to eq("closed")
    end

    it "ensures post is not trashed" do
      poll.trash!
      xhr :put, :toggle_status, { post_id: poll.id, poll_name: "poll", status: "closed" }
      expect(response).not_to be_success
      json = ::JSON.parse(response.body)
      expect(json["errors"][0]).to eq(I18n.t("poll.post_is_deleted"))
    end

  end
end
