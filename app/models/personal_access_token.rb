# frozen_string_literal: true

# Personal Access Token class
class PersonalAccessToken < ApplicationRecord
  has_logidze
  serialize :scopes, type: Array, coder: YAML

  attr_reader :token

  acts_as_paranoid

  belongs_to :user

  before_create :ensure_token

  validates :scopes, presence: true
  validate :validate_scopes

  scope :active, -> { not_revoked.not_expired }
  scope :not_revoked, -> { where(revoked: [false, nil]) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def revoke!
    update!(revoked: true)
  end

  def revoked?
    revoked == true
  end

  def expires?
    expires_at.present?
  end

  def expired?
    expires? && expires_at <= Time.current
  end

  def active?
    !revoked? && !expired?
  end

  def self.find_by_token(token)
    token_digest = Devise.token_generator.digest(self, :token_digest, token)

    find_by(token_digest:)
  end

  private

  def validate_scopes
    valid_scopes = Irida::Auth.all_available_scopes

    return if revoked || scopes.all? { |scope| valid_scopes.include?(scope.to_sym) }

    errors.add :scopes, :inclusion
  end

  def write_new_token
    @token, self.token_digest = Devise.token_generator.generate(self.class, :token_digest)
  end

  def ensure_token
    write_new_token if token_digest.blank?
  end
end
