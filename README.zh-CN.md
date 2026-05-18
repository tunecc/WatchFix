[English](./README.md) | [简体中文](./README.zh-CN.md)

这个仓库是 [577fkj/WatchFix](https://github.com/577fkj/WatchFix) 的一个 fork/mod。

## 上游参考

- 上游完整 README： [577fkj/WatchFix README](https://github.com/577fkj/WatchFix/blob/app/README.md)

## 本分支改动

- 软件包标识改为 `cn.fkj233.watchfix.mod`。
- 应用内的插件详细说明页已经重写并扩充，补上了更清楚的功能摘要、使用场景、系统要求、注入目标和重启提示。
- 插件帮助内容新增应用内语言切换，当前提供英文、简体中文和繁体中文三套文案。
- `AppsSupport` 现在只负责手表 App 安装兼容性这一类问题。
- 新增 `避免信息卸载`，从原先的 `AppsSupport` 中拆出，专门处理 watchOS 11.4 及之后配对后“信息”消失的问题。
- 新增 `WatchOS 更新屏蔽`，用于压住 iPhone 上 Watch App 的 watchOS 更新扫描和升级提示。
