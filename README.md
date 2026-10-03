# Song download helper
Helps you download songs from your YouTube playlist using any music platform.
The tool parses a playlist saved as HTML, extracts song names, and opens a browser window with the list.
Each song is a link that opens search results for that song on the configured platform.
After downloading, it helps rename the files to a uniform pattern.

## Configuration
1. Copy `./dl-helper.example.env` to `./dl-helper.env` and update your preferences
   (playlist name, preferred browser, renaming rules, etc.).
2. Copy `./dl-helper/config.example.ts` to `./dl-helper/config.ts` and set up search queries for your music platform(s).

## How to use
1. Open your [YouTube playlist](https://www.youtube.com/feed/playlists) and save it.
2. ```bash
   ./load-html.sh
   ```
3. Check the [`listing`](listing) directory and verify that there are no duplicates and all song names are properly
   formatted (`list-clean.tsv`). This file is used as the source to generate download links.
4. ```bash
   ./list-util.sh
   ```
5. Search & download in the browser.
6. ```bash
   ./stage-load.sh
   ```
