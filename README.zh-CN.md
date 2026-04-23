# Boring Notch

![Boring Notch App Icon](./newappicon.png)

个人维护的 macOS 刘海区实验项目与长期开发分支。

[English README](./README.md)

## 项目简介

这个仓库现在作为我个人维护的 Boring Notch 项目继续开发。
当前重点是围绕 macOS 刘海区交互做功能扩展、界面打磨和本地实验。

> [!NOTE]
> 这个项目延续自原始上游仓库：
> [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch)
>
> 当前代码库以我个人维护和持续开发为主，但这里仍然保留原项目链接，用于来源说明和致谢。

当前方向：

- 围绕 macOS 刘海区的媒体与效率工具体验
- 更快验证个人功能想法
- 为这个代码库维护独立的开发文档和更新日志

## 开发说明

### 环境要求

- macOS 14 或更高版本
- Xcode 16 或更高版本

### 本地运行

```bash
git clone https://github.com/neversaywanan/boring.notch.git
cd boring.notch
open boringNotch.xcodeproj
```

然后在 Xcode 中使用 `Cmd + R` 运行应用。

### 说明

- 开发过程中应用可能会请求辅助功能等系统权限。
- 如果你把本地构建产物导出后被 macOS 阻止启动，可以手动移除隔离属性：

```bash
xattr -dr com.apple.quarantine /Applications/boringNotch.app
```

## 项目结构

- `boringNotch/`：SwiftUI 主应用代码
- `boringNotch/components/`：刘海区模块、设置面板、引导流程、Shelf、剪贴板、摄像头、HUD
- `boringNotch/managers/`：共享管理器，例如剪贴板管理
- `boringNotch/models/`：应用状态、默认配置与共享模型
- `boringNotch/helpers/`：辅助工具与图标相关逻辑
- `boringNotch.xcodeproj/`：Xcode 项目配置

## 当前个人开发重点

- 保持刘海区交互流畅、视觉统一
- 提升实用面板在日常使用中的可用性
- 改进系统集成行为和设置可靠性
- 持续打磨引导流程、本地化和自定义体验

## 更新日志

### 2026-04-24

- 新增刘海区内的剪贴板标签页。
- 新增剪贴板历史、快速重新复制和单项删除能力。
- 新增剪贴板相关设置，包括功能开关、标签页显示控制和历史数量上限。
- 调整并优化了相关标签切换和动效表现。

### 2026-04-21

- 更新应用图标资源与仓库品牌展示。
- 优化多个刘海区视图与设置流程的交互表现。
- 改进 XPC Helper 行为与辅助功能授权处理。
- 持续完善引导流程、设置页与本地化文本。

## 许可证

仓库中现有的许可证与致谢文件保持不变。
