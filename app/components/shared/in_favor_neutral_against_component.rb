# app/components/shared/in_favor_neutral_against_component.rb
class Shared::InFavorNeutralAgainstComponent < ApplicationComponent
  attr_reader :votable
  
  # Make sure to include the helper we need
  use_helpers :vote_percentage_for_weight, :t

  def initialize(votable)
    @votable = votable
  end

  private

  # We add a smart helper to find the correct title,
  # exactly like we did for the other component.
  #
  def votable_title_for_aria_label
    if votable.is_a?(Comment) && votable.commentable&.respond_to?(:title)
      # It's a Comment, so we get the title from its parent (the Debate)
      votable.commentable.title
    elsif votable.respond_to?(:title)
      # It's a Debate (or something else with its own title)
      votable.title
    else
      # Fallback
      ""
    end
  end

  # These helpers are for accessibility (aria-label)
  # They now use our new smart helper method.
  
  def agree_aria_label
    t("votes.agree_label", title: votable_title_for_aria_label)
  end

  def disagree_aria_label
    t("votes.disagree_label", title: votable_title_for_aria_label)
  end

  def neutral_aria_label
    t("votes.neutral_label", title: votable_title_for_aria_label)
  end
end