[English](./README.md) | [简体中文](./README.zh-CN.md)

这个仓库是 [577fkj/WatchFix](https://github.com/577fkj/WatchFix) 的一个修改版，已合入截至 `9cbcefa` 的上游修复，并保留以下用户可见的差异。

## 上游参考

- 上游完整 README： [577fkj/WatchFix README](https://github.com/577fkj/WatchFix/blob/app/README.md)

## 与上游的区别

- **信息修复可独立安装：**「避免信息卸载」与 `AppsSupport` 分开。若既需要手表 App 安装兼容，又需要处理 watchOS 11.4 及之后配对后“信息”消失的问题，可以同时安装两个插件。
- **可选的 watchOS 更新屏蔽：**安装「WatchOS 更新屏蔽」后，iPhone 上的 Watch App 会隐藏更新扫描结果和升级提示；需要正常检查更新时，不安装该插件。
- **更清楚的插件管理：**插件详情提供易读说明、使用场景、兼容要求，以及按需展开的技术信息。列表单独展示不兼容的插件。
- **应用内切换语言：**提供简体中文、繁体中文和英文。
- **独立的软件包标识：**本分支使用 `cn.fkj233.watchfix.mod`。

rootless 与 roothide 是不同安装包，请选择与你的越狱环境对应的版本。各插件是否可用还取决于应用内显示的 iOS 和 watchOS 版本要求。
