#!/usr/bin/env python3
"""
Fetch GitHub star history and save to JSON.

Usage:
    python fetch_star_history.py                    # Uses default repo (moltbot/moltbot)
    python fetch_star_history.py owner/repo         # Explicit repo
    GITHUB_TOKEN=xxx python fetch_star_history.py   # Authenticated (higher rate limit)

Output:
    data/star_history.json with cumulative daily star counts.

Rate Limits:
    - Unauthenticated: 60 requests/hour
    - Authenticated: 5,000 requests/hour
"""

import json
import os
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

DEFAULT_REPO = "moltbot/moltbot"
OUTPUT_PATH = Path(__file__).parent.parent.parent / "data" / "star_history.json"
PER_PAGE = 100


def fetch_stargazers(repo: str, token: str | None = None) -> list[dict]:
    """
    Fetch all stargazers with timestamps from GitHub API.

    Args:
        repo: Repository in "owner/repo" format.
        token: Optional GitHub token for higher rate limits.

    Returns:
        List of {"starred_at": "ISO timestamp", "user": {...}} dicts.
    """
    stargazers = []
    page = 1

    headers = {
        "Accept": "application/vnd.github.star+json",
        "User-Agent": "moltbot-star-tracker",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"

    print(f"Fetching stargazers for {repo}...")

    while True:
        url = f"https://api.github.com/repos/{repo}/stargazers?per_page={PER_PAGE}&page={page}"
        request = Request(url, headers=headers)

        try:
            with urlopen(request, timeout=30) as response:
                data = json.loads(response.read().decode("utf-8"))

                if not data:
                    break

                stargazers.extend(data)
                print(f"  Page {page}: {len(data)} stargazers (total: {len(stargazers)})")

                # Check if there are more pages
                if len(data) < PER_PAGE:
                    break

                page += 1

        except HTTPError as e:
            if e.code == 403:
                # Rate limit exceeded
                reset_time = e.headers.get("X-RateLimit-Reset")
                if reset_time:
                    reset_dt = datetime.fromtimestamp(int(reset_time), tz=timezone.utc)
                    print(f"\nRate limit exceeded. Resets at {reset_dt.isoformat()}")
                    if not token:
                        print("Tip: Set GITHUB_TOKEN env var for higher rate limits (5000/hour).")
                else:
                    print(f"\nRate limit exceeded.")
                sys.exit(1)
            elif e.code == 404:
                print(f"\nRepository not found: {repo}")
                sys.exit(1)
            else:
                print(f"\nHTTP error {e.code}: {e.reason}")
                sys.exit(1)
        except URLError as e:
            print(f"\nNetwork error: {e.reason}")
            sys.exit(1)

    return stargazers


def aggregate_by_date(stargazers: list[dict]) -> list[dict]:
    """
    Convert stargazer timestamps to cumulative daily counts.

    Args:
        stargazers: List of stargazer objects with "starred_at" timestamps.

    Returns:
        List of {"date": "YYYY-MM-DD", "stars": cumulative_count} sorted by date.
    """
    # Count stars per date
    daily_counts: dict[str, int] = defaultdict(int)

    for star in stargazers:
        starred_at = star.get("starred_at")
        if starred_at:
            date = starred_at[:10]  # Extract YYYY-MM-DD
            daily_counts[date] += 1

    # Sort dates and compute cumulative counts
    sorted_dates = sorted(daily_counts.keys())
    history = []
    cumulative = 0

    for date in sorted_dates:
        cumulative += daily_counts[date]
        history.append({"date": date, "stars": cumulative})

    return history


def save_history(repo: str, history: list[dict], total_stars: int) -> None:
    """
    Save star history to JSON file.

    Args:
        repo: Repository name.
        history: List of daily cumulative star counts.
        total_stars: Total star count.
    """
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    data = {
        "repository": repo,
        "fetched_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "total_stars": total_stars,
        "history": history,
    }

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    print(f"\nSaved to {OUTPUT_PATH}")


def main() -> None:
    """Main entry point."""
    # Parse arguments
    repo = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_REPO

    # Validate repo format
    if "/" not in repo or repo.count("/") != 1:
        print(f"Invalid repository format: {repo}")
        print("Expected format: owner/repo")
        sys.exit(1)

    # Get token from environment
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        print("Using authenticated requests (5000/hour rate limit).")
    else:
        print("Using unauthenticated requests (60/hour rate limit).")
        print("Tip: Set GITHUB_TOKEN env var for higher rate limits.\n")

    # Fetch stargazers
    stargazers = fetch_stargazers(repo, token)

    if not stargazers:
        print(f"\nNo stargazers found for {repo}.")
        save_history(repo, [], 0)
        return

    # Aggregate by date
    print(f"\nAggregating {len(stargazers)} stars by date...")
    history = aggregate_by_date(stargazers)

    # Save to file
    total_stars = history[-1]["stars"] if history else 0
    save_history(repo, history, total_stars)

    # Summary
    print(f"\nSummary:")
    print(f"  Repository: {repo}")
    print(f"  Total stars: {total_stars:,}")
    print(f"  Date range: {history[0]['date']} to {history[-1]['date']}")
    print(f"  Days with activity: {len(history)}")


if __name__ == "__main__":
    main()
