# Grant Automation
This is the parent repo for a project that calls the grants.gov API for a few pre-configured searches, and configures the results into an RSS feed so slack can see it

It contains two Git submodules:

- **`grant-getter`** — Calls Grants.gov search2 API, tracks what has already been messaged into the chat, and generates an RSS feed.
- **`grant-getter-feed`** — Publishes the generated RSS feed through GitHub Pages so it can be accessed by slack

## Pipeline

```text
Grants.gov Search API
        ↓
grant-getter
        ↓
SQLite deduplication
        ↓
RSS feed generation
        ↓
grant-getter-feed
        ↓
GitHub Pages
        ↓
Slack RSS app
```


The public RSS feed is available at: https://micom-hub.org/grant-getter-feed/feed.xml

This repo uses submodules, so clone it with --recursive-submodules 

## Running
The orchestration script, run-and-publish.sh, needs executtable permission.

## Search Configuration
Searches are configured in grant-geter/config.yaml, with supported fields for searching listed under grant-getter/grant_getter/api.py


## Deduplication

There is a SQLite database stored under grant-getter/state/. This contains the bootstrapped results (the grant opportunities that existed on 10/19/26 when this was initialized), and appends results to this as they are identified by subsequent searches

## Resetting the bootstrapped database

Running the following from the grant-getter directory...
```{bash}
python -m grant_getter \
  --database state/production.sqlite3 \
  bootstrap
```

... will reset the sqlite database that determines what has "already been seen" by the RSS feed. This could be useful if you are restircing/resetting search terms. You can then check stored opportunities and published opportunities with
```{bash}
sqlite3 state/production.sqlite3 \
  'SELECT COUNT(*) FROM opportunities;'
#and
sqlite3 state/production.sqlite3 \
  'SELECT COUNT(*) FROM feed_items;'
# View bootstrap metadata
sqlite3 -header -column state/production.sqlite3 '
SELECT key, value
FROM metadata
ORDER BY key;
'
# Test a run:
python -m grant_getter \
  --database state/production.sqlite3 \
  run
# You should expect it to output "Found 0 previously unseen oppotunities."
```
