#!/usr/bin/env python3
"""
Fetch GitHub star history and save to JSON using the GraphQL API.

Usage:
    python fetch_star_history.py                    # Uses default repo (moltbot/moltbot)
    python fetch_star_history.py owner/repo         # Explicit repo
    GITHUB_TOKEN=xxx python fetch_star_history.py   # Authenticated (required for GraphQL)

Output:
    data/star_history.json with cumulative daily star counts.

Notes:
    - Uses GraphQL API to bypass the 40,000 star REST API limit
    - GitHub token is REQUIRED (GraphQL doesn't allow unauthenticated requests)
    - Rate limit: 5,000 points/hour (each page costs 1 point)
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

GRAPHQL_QUERY = """
query($owner: String!, $name: String!, $first: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    stargazers(first: $first, after: $after) {
      totalCount
      edges {
        starredAt
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
"""


def fetch_stargazers_graphql(owner: str, name: str, token: str) -> list[str]:
    """
    Fetch all stargazer timestamps using GitHub GraphQL API.

    Args:
        owner: Repository owner.
        name: Repository name.
        token: GitHub token (required for GraphQL).

    Returns:
        List of ISO timestamp strings when each star was given.
    """
    timestamps: list[str] = []
    cursor: str | None = None
    page = 0

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "User-Agent": "moltbot-star-visualizer",
    }

    print(f"Fetching stargazers for {owner}/{name} using GraphQL API...")

    while True:
        page += 1
        variables = {
            "owner": owner,
            "name": name,
            "first": PER_PAGE,
            "after": cursor,
        }

        payload = json.dumps({"query": GRAPHQL_QUERY, "variables": variables}).encode()
        request = Request(
            "https://api.github.com/graphql",
            data=payload,
            headers=headers,
            method="POST",
        )

        try:
            with urlopen(request, timeout=30) as response:
                result = json.loads(response.read().decode("utf-8"))

                if "errors" in result:
                    for error in result["errors"]:
                        print(f"GraphQL error: {error.get('message', error)}")
                    sys.exit(1)

                data = result["data"]["repository"]["stargazers"]
                total_count = data["totalCount"]

                for edge in data["edges"]:
                    timestamps.append(edge["starredAt"])

                print(f"  Page {page}: {len(data['edges'])} stars (total: {len(timestamps)}/{total_count})")

                if not data["pageInfo"]["hasNextPage"]:
                    break

                cursor = data["pageInfo"]["endCursor"]

        except HTTPError as e:
            if e.code == 401:
                print("\nAuthentication failed. Check your GITHUB_TOKEN.")
                sys.exit(1)
            elif e.code == 403:
                reset_time = e.headers.get("X-RateLimit-Reset")
                if reset_time:
                    reset_dt = datetime.fromtimestamp(int(reset_time), tz=timezone.utc)
                    print(f"\nRate limit exceeded. Resets at {reset_dt.isoformat()}")
                else:
                    print("\nRate limit exceeded.")
                sys.exit(1)
            elif e.code == 502 or e.code == 503:
                print(f"\nGitHub API temporarily unavailable (HTTP {e.code}). Try again later.")
                sys.exit(1)
            else:
                print(f"\nHTTP error {e.code}: {e.reason}")
                sys.exit(1)
        except URLError as e:
            print(f"\nNetwork error: {e.reason}")
            sys.exit(1)

    return timestamps


def aggregate_by_date(timestamps: list[str]) -> list[dict]:
    """
    Convert stargazer timestamps to cumulative daily counts.

    Args:
        timestamps: List of ISO timestamp strings.

    Returns:
        List of {"date": "YYYY-MM-DD", "stars": cumulative_count} sorted by date.
    """
    daily_counts: dict[str, int] = defaultdict(int)

    for ts in timestamps:
        date = ts[:10]  # Extract YYYY-MM-DD
        daily_counts[date] += 1

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
    repo = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_REPO

    if "/" not in repo or repo.count("/") != 1:
        print(f"Invalid repository format: {repo}")
        print("Expected format: owner/repo")
        sys.exit(1)

    owner, name = repo.split("/")

    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print("Error: GITHUB_TOKEN environment variable is required for GraphQL API.")
        print("\nTo get a token:")
        print("  1. Go to https://github.com/settings/tokens")
        print("  2. Generate a new token (no scopes needed for public repos)")
        print("  3. Run: GITHUB_TOKEN=your_token python fetch_star_history.py")
        print("\nOr if you have gh CLI installed:")
        print("  GITHUB_TOKEN=$(gh auth token) python fetch_star_history.py")
        sys.exit(1)

    timestamps = fetch_stargazers_graphql(owner, name, token)

    if not timestamps:
        print(f"\nNo stargazers found for {repo}.")
        save_history(repo, [], 0)
        return

    print(f"\nAggregating {len(timestamps)} stars by date...")
    history = aggregate_by_date(timestamps)

    total_stars = history[-1]["stars"] if history else 0
    save_history(repo, history, total_stars)

    print(f"\nSummary:")
    print(f"  Repository: {repo}")
    print(f"  Total stars: {total_stars:,}")
    print(f"  Date range: {history[0]['date']} to {history[-1]['date']}")
    print(f"  Days with activity: {len(history)}")


if __name__ == "__main__":
    main()
