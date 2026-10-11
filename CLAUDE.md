# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

KI-Glossar is a German-language (`de`) glossary site built with [Blume](https://www.npmjs.com/package/blume) (a docs framework; Node.js 22.19+ required) and published at https://kiglossar.schreibauf.de. There is no application code — the repo is site configuration plus a deploy script.

## Commands

- `npm run dev` — local dev server with live reload (`blume dev`)
- `npm run build` — build the static site into `dist/` (`blume build`)
- `npm run doctor` — Blume config/content diagnostics
- `scripts/deploy.sh [--dry-run] [--no-build]` — build, then `rsync --delete` `dist/` to `milos:/opt/www/kiglossar/`. Use `--dry-run` first to preview changes on the server.

There are no tests or linters.

## Architecture

- [blume.config.ts](blume.config.ts) defines two content sources that are merged into one site:
  1. `filesystem({ root: "docs" })` — MDX pages in this repo (currently only [docs/index.mdx](docs/index.mdx), still the Blume placeholder).
  2. `obsidian({ vault: "/Users/bbruecker/Notizen/IT/KI/_KI-Glossar" })` — the actual glossary content lives in an Obsidian vault **outside this repo** at an absolute local path (folders `Templates` and `Daily` are excluded). Builds only work on a machine where that vault exists; glossary entries are edited in Obsidian, not here.
- `.blume/` (generated), `dist/` and `node_modules/` are gitignored.
- [scripts/deploy.sh](scripts/deploy.sh) is built on the `scripts/runlib` git submodule (shell library for logging, locking, notifications, worker loop). Run `git submodule update --init` after cloning. The script reads an optional untracked `scripts/global.conf`; all `*.conf` files are gitignored (only `*.conf.example` is versioned), and logs go to `scripts/logs/`. The deploy refuses to sync if `dist/index.html` is missing, since `--delete` would otherwise wipe the server.
