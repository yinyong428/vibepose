# Sprint 0 / Spike

## 目标

在正式功能迭代前冻结 3 个关键面向：

- 范围 cut line
- 主链路技术可行性
- 模板与运行时合同

## 冻结决策

- 识别主引擎：`Vision 2D Body Pose`
- 统一骨架：`CanonicalPose19`
- MVP 首发范围：`单人主链路 + 本地模板 + 收藏/分享 + 可降级自动快门`
- 可整体回切：`Copy Pose Beta / 面部辅助 / 复杂推荐增强`

## Spike 检查项

- 相机冷启动与前后摄切换是否稳定
- Vision 单人骨架是否达到预期帧率
- CanonicalPose19 是否足以承接模板匹配
- 最新帧优先链路是否不堆帧
- 叠加层、分数更新、倒计时状态机是否能并行顺滑运行

## 交付物

- 可编译 iOS 工程
- starter pack 模板 JSON
- 核心 domain / infra 边界
- README 与合同文档

