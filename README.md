# 摆个Pose / VibePose

`VibePose` 是一个 `iOS 17+`、`Global-first` 的单人姿势引导相机 MVP。当前仓库已从纯文档状态升级为可启动的 Spike 工程，目标是先冻结主链路合同，再验证 Vision + Camera + 评分 + 自动快门状态机的技术可行性。

## 当前实现

- 最小 SwiftUI iOS 工程骨架
- `CanonicalPose19`、`PoseTemplate manifest`、`RuntimeConfig / FeatureFlag` 合同
- 本地 starter pack 模板资源
- Vision 单人骨架识别适配层
- 最新帧优先的相机采样链路
- 模板匹配、推荐、自动快门状态机 Spike
- Sprint 0 文档、版本 cut line、里程碑拆解

## 目录结构

```text
VibePose/
  App/
  Features/
  Domain/
  Infra/
  Resources/
docs/
  contracts/
  planning/
VibePose.xcodeproj/
```

## 快速开始

1. 用 Xcode 打开 [VibePose.xcodeproj](/Users/olly/Documents/CodeX/摆个Pose/VibePose.xcodeproj)。
2. 选择 `VibePose` target，运行到 iPhone 模拟器或真机。
3. 首次真机运行时授权相机权限。
4. 在主页面验证：
   - 相机冷启动和前后摄切换
   - 骨架识别与模板叠加
   - 推荐卡片切换
   - `Ready / Perfect / Countdown` 状态切换

## 关键文档

- [Sprint 0 Spike](</Users/olly/Documents/CodeX/摆个Pose/docs/planning/sprint-0-spike.md>)
- [Milestones](</Users/olly/Documents/CodeX/摆个Pose/docs/planning/milestones.md>)
- [CanonicalPose19 Contract](</Users/olly/Documents/CodeX/摆个Pose/docs/contracts/canonical-pose19.md>)
- [Template Manifest Contract](</Users/olly/Documents/CodeX/摆个Pose/docs/contracts/template-manifest.md>)
- [Runtime Config Contract](</Users/olly/Documents/CodeX/摆个Pose/docs/contracts/runtime-config.md>)

## 当前边界

- `Must Ship`：单人主链路、本地模板、实时叠加、基础推荐、手动拍照入口、自动快门可降级、收藏/设置持久化接口
- `Should Ship`：摄影师角度线、叠加截图、品牌水印
- `Stretch`：Copy Pose Beta、复杂推荐增强、Foundation Models 文案增强

## 注意事项

- 当前工程的重点是 `Spike`，不是完整产品交付。
- 真机体验优于模拟器；Vision 人体识别与摄像头切换建议在 `A15+` 设备上验证。
- `Copy Pose`、面部辅助与复杂推荐仍由 Feature Flag 控制，可整体回切。

