require 'match/version'
require 'match/options'
require 'match/runner'
require 'match/nuke'
require 'match/utils'
require 'match/table_printer'
require 'match/git_helper'
require 'match/generator'
require 'match/setup'
require 'match/encrypt'
require 'match/spaceship_ensure'
require 'match/change_password'

require 'fastlane_core'
require 'terminal-table'
require 'spaceship'

module Match
  Helper = FastlaneCore::Helper # you gotta love Ruby: Helper.* should use the Helper class contained in FastlaneCore
  UI = FastlaneCore::UI
  ROOT = Pathname.new(File.expand_path('../..', __FILE__))

  def self.environments
    envs = %w(appstore adhoc development)
    envs << "enterprise" if self.enterprise?
    return envs
  end

  # @return [Boolean] returns true if the unsupported enterprise mode should be enabled
  def self.enterprise?
    ENV["MATCH_FORCE_ENTERPRISE"]
  end

  # @return [Boolean] returns true if match should interpret the given [certificate|profile] type as an enterprise one
  def self.type_is_enterprise?(type)
    Match.enterprise? && type != "development"
  end

  def self.profile_type_sym(type)
    return :enterprise if self.type_is_enterprise? type
    return :adhoc if type == "adhoc"
    return :appstore if type == "appstore"
    return :development
  end

  def self.cert_type_sym(type)
    return :enterprise if self.type_is_enterprise? type
    return :development if type == "development"
    return :distribution
  end
end
