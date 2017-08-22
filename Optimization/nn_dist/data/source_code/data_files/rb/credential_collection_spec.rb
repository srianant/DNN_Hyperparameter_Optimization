require 'spec_helper'
require 'metasploit/framework/credential_collection'

RSpec.describe Metasploit::Framework::CredentialCollection do

  subject(:collection) do
    described_class.new(
      blank_passwords: blank_passwords,
      pass_file: pass_file,
      password: password,
      user_as_pass: user_as_pass,
      user_file: user_file,
      username: username,
      userpass_file: userpass_file,
    )
  end

  let(:blank_passwords) { nil }
  let(:username) { "user" }
  let(:password) { "pass" }
  let(:user_file) { nil }
  let(:pass_file) { nil }
  let(:user_as_pass) { nil }
  let(:userpass_file) { nil }

  describe "#each" do
    specify do
      expect { |b| collection.each(&b) }.to yield_with_args(Metasploit::Framework::Credential)
    end

    context "when given a user_file and password" do
      let(:username) { nil }
      let(:user_file) do
        filename = "foo"
        stub_file = StringIO.new("asdf\njkl\n")
        allow(File).to receive(:open).with(filename,/^r/).and_yield stub_file

        filename
      end

      specify  do
        expect { |b| collection.each(&b) }.to yield_successive_args(
          Metasploit::Framework::Credential.new(public: "asdf", private: password),
          Metasploit::Framework::Credential.new(public: "jkl", private: password),
        )
      end
    end

    context "when given a pass_file and username" do
      let(:password) { nil }
      let(:pass_file) do
        filename = "foo"
        stub_file = StringIO.new("asdf\njkl\n")
        allow(File).to receive(:open).with(filename,/^r/).and_return stub_file

        filename
      end

      specify  do
        expect { |b| collection.each(&b) }.to yield_successive_args(
          Metasploit::Framework::Credential.new(public: username, private: "asdf"),
          Metasploit::Framework::Credential.new(public: username, private: "jkl"),
        )
      end
    end


    context "when given a userspass_file" do
      let(:username) { nil }
      let(:password) { nil }
      let(:userpass_file) do
        filename = "foo"
        stub_file = StringIO.new("asdf jkl\nfoo bar\n")
        allow(File).to receive(:open).with(filename,/^r/).and_yield stub_file

        filename
      end

      specify  do
        expect { |b| collection.each(&b) }.to yield_successive_args(
          Metasploit::Framework::Credential.new(public: "asdf", private: "jkl"),
          Metasploit::Framework::Credential.new(public: "foo", private: "bar"),
        )
      end
    end

    context "when given a pass_file and user_file" do
      let(:password) { nil }
      let(:username) { nil }
      let(:user_file) do
        filename = "user_file"
        stub_file = StringIO.new("asdf\njkl\n")
        allow(File).to receive(:open).with(filename,/^r/).and_yield stub_file

        filename
      end
      let(:pass_file) do
        filename = "pass_file"
        stub_file = StringIO.new("asdf\njkl\n")
        allow(File).to receive(:open).with(filename,/^r/).and_return stub_file

        filename
      end

      specify  do
        expect { |b| collection.each(&b) }.to yield_successive_args(
          Metasploit::Framework::Credential.new(public: "asdf", private: "asdf"),
          Metasploit::Framework::Credential.new(public: "asdf", private: "jkl"),
          Metasploit::Framework::Credential.new(public: "jkl", private: "asdf"),
          Metasploit::Framework::Credential.new(public: "jkl", private: "jkl"),
        )
      end
    end

    context "when :user_as_pass is true" do
      let(:user_as_pass) { true }
      specify  do
        expect { |b| collection.each(&b) }.to yield_successive_args(
          Metasploit::Framework::Credential.new(public: username, private: password),
          Metasploit::Framework::Credential.new(public: username, private: username),
        )
      end
    end

    context "when :blank_passwords is true" do
      let(:blank_passwords) { true }
      specify  do
        expect { |b| collection.each(&b) }.to yield_successive_args(
          Metasploit::Framework::Credential.new(public: username, private: password),
          Metasploit::Framework::Credential.new(public: username, private: ""),
        )
      end
    end

  end

  describe "#prepend_cred" do
    specify do
      prep = Metasploit::Framework::Credential.new(public: "foo", private: "bar")
      collection.prepend_cred(prep)
      expect { |b| collection.each(&b) }.to yield_successive_args(
        prep,
        Metasploit::Framework::Credential.new(public: username, private: password),
      )
    end
  end

end
