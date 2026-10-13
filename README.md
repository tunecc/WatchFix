[English](./README.md) | [简体中文](./README.zh-CN.md)

This repository is a fork/mod of [577fkj/WatchFix](https://github.com/577fkj/WatchFix). It includes the upstream fixes merged through `9cbcefa` and keeps the following user-facing differences.

## Upstream Reference

- Full upstream README: [577fkj/WatchFix README](https://github.com/577fkj/WatchFix/blob/app/README.md)

## Differences From Upstream

- **Separate Messages fix:** `Prevent Messages Removal` can be installed independently of `AppsSupport`. Install both if you need watch app installation compatibility and protection against Messages disappearing after pairing on watchOS 11.4 or later.
- **Optional watchOS update block:** `WatchOS Update Block` suppresses update scans and prompts in the iPhone Watch app while installed. Leave it uninstalled if you want normal watchOS update checks.
- **Clearer plugin management:** plugin pages show plain-language descriptions, examples, compatibility requirements, and technical details on demand. The plugin list also separates unsupported plugins.
- **Language choice:** the app offers English, Simplified Chinese, and Traditional Chinese.
- **Separate package identity:** this fork uses the package identifier `cn.fkj233.watchfix.mod`.

Rootless and roothide packages are separate; install the one matching your jailbreak environment. Plugin availability also depends on the iOS and watchOS versions shown in the app.

Support the upstream author: [爱发电](https://afdian.com/a/577fkj).
