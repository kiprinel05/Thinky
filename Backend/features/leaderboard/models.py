"""
Currently we don't need dedicated DB models for leaderboard – everything is
computed on the fly from missions, mission progress and workshop downloads.

This module exists to keep the `features.leaderboard` package valid and can be
extended later if we decide to persist leaderboard snapshots.
"""  # noqa: D400,D401

