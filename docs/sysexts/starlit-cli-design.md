# starlit-cli design note

Decision note for whether `starlit-cli` should remain a collection sysext or be split into single-tool sysexts.

## Current recommendation

**Keep `starlit-cli` as a collection sysext for now.**

Current bundle contents:

- `fish`
- `bat`
- `eza`

These still form a coherent, user-facing "better terminal experience" bundle:

- `fish` — interactive shell
- `bat` — improved file viewer / `cat` replacement
- `eza` — improved directory listing / `ls` replacement

The bundle is still small enough to explain in one sentence and install in one step.

## Why keep the collection now

### 1. Clear user story

`starlit-cli` currently reads as one opinionated terminal UX add-on, not a grab bag of unrelated binaries.

That makes it easy to document and easy to recommend:

> install `starlit-cli` if you want a better terminal experience on Dakota

### 2. Lower operator overhead

A collection sysext keeps the repo surface area smaller:

- one top-level sysext element
- one just workflow
- one install path
- one archive path
- one future raw/sysupdate component if the bundle grows that path later

### 3. Better adoption path for opt-in features

Because sysexts are optional, one bundle often has a better adoption story than asking users to choose among several small pieces before they have even tried the feature set.

## Risks of keeping the collection

### 1. Coupled release cadence

Any update to one bundled tool changes the whole sysext.

If one tool updates much more often than the others, the bundle may become noisy to maintain.

### 2. Shared compatibility label

The bundle can only be as portable as its most host-sensitive member.

Today that matters because:

- `fish` is packaged from a static upstream Linux binary
- `bat` and `eza` are packaged from dynamically linked upstream Linux binaries

So the current bundle should still be treated as **Dakota-targeted**, not host-independent.

### 3. Reduced user choice

A user who wants only `bat` or only `eza` still has to install `fish` too.

That is acceptable for an intentionally opinionated starter bundle, but it becomes a problem if the bundle grows too broad.

## When to split into single-tool sysexts

Revisit this decision if any of the following become true:

### 1. The bundle loses its theme

If `starlit-cli` starts accumulating tools that do not clearly fit the same "terminal UX starter pack" story, it should stop growing and new tools should be packaged separately.

Examples of warning signs:

- adding unrelated admin tooling
- adding network utilities with a different lifecycle
- adding many small convenience binaries just because they are useful

### 2. One tool wants a different lifecycle

Split if one member has meaningfully different:

- release frequency
- portability profile
- support burden
- host-side behavior

### 3. Users are likely to want only one member

This is especially relevant for `fish`, because it is a shell and therefore more opinionated than `bat` or `eza`.

If user demand strongly centers around one tool at a time, single-tool sysexts become a better fit.

### 4. Public sysupdate distribution becomes per-tool

If the project later wants per-tool optional feeds, update visibility, or UI management, then single-tool sysexts become more attractive because the versioning and activation boundaries are cleaner.

## Special note about `fish`

If `starlit-cli` is eventually split, `fish` is the strongest first candidate to separate.

Reasons:

- it is the most opinionated tool in the bundle
- it changes the shell experience more than `bat` or `eza`
- users may want `bat`/`eza` without wanting a new shell

## Recommended bundle rule

Use this rule for future `starlit-cli` membership decisions:

> `starlit-cli` should stay limited to a small, opinionated terminal UX bundle. If a candidate tool does not clearly fit that story, package it as its own sysext instead of growing the collection.

## Decision framework

Keep a collection sysext when all of these are true:

1. The tools form one clear user-facing story.
2. One install flow is more valuable than per-tool choice.
3. The tools can reasonably share release cadence and compatibility risk.

If any of those stop being true, prefer single-tool sysexts.
