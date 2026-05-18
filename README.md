[English](./README.md) | [简体中文](./README.zh-CN.md)

This repository is a fork/mod of [577fkj/WatchFix](https://github.com/577fkj/WatchFix).

## Upstream Reference

- Full upstream README: [577fkj/WatchFix README](https://github.com/577fkj/WatchFix/blob/app/README.md)

## Fork-Specific Changes

- Package identifier changed to `cn.fkj233.watchfix.mod`. 
- In-app plugin detail pages were rewritten and expanded with clearer summaries, usage examples, system requirements, injection targets, and restart hints.
- Added an in-app language switch with English, Simplified Chinese, and Traditional Chinese strings for the plugin help content.
- `AppsSupport` now focuses on watch app installation compatibility only.
- Added `Prevent Messages Removal`, split out from the original `AppsSupport`, to address Messages disappearing after pairing on watchOS 11.4 and later.
- Added `WatchOS Update Block` to suppress watchOS update scans and update prompts shown by the iPhone Watch app.
