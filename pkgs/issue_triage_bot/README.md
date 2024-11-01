> Source: https://github.com/dart-lang/ecosystem

## What's this?

A LLM based triage automation system for the `fluttercandies/flutter_photo_manager` repo. It processes
new issues filed against the repo and triages them in the same manner that a
human would. This includes:

- re-summarizing the issue for clarity
- assigning the issues to the label

## Bot trigger and entry-point

This bot is generally triggered by a GitHub workflow listening for new issues
on the `fluttercandies/flutter_photo_manager` repo.

See https://github.com/fluttercandies/flutter_photo_manager/blob/main/.github/workflows/issue-triage.yml.

## Overview

The general workflow of the tool is:

- download the issue information (existing labels, title, first comment)
- ask Gemini to summarize the issue (see [prompts](lib/src/prompts.dart))
- ask Gemini to classify the issue (see [prompts](lib/src/prompts.dart))
- create a comment on the issue (`@github-bot`) with the summary;
  apply any labels produced as part of the classification
