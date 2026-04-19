# Runtime Config / Feature Flag Contract

## RuntimeConfig

- `baselineDevice = A15`
- `targetInferenceFPS = 12...15`
- `uiRefreshMode = adaptive 30/60`
- `cameraMode = front/back`

## Feature Flags

- `autoCaptureEnabled`
- `faceAssistEnabled`
- `copyPoseEnabled`
- `photographerGuidanceEnabled`
- `overlayScreenshotEnabled`
- `watermarkEnabled`

## 原则

- 增强能力默认可关
- 增强能力不得阻塞主链路
- 降级优先级：
  1. 关闭复杂推荐刷新
  2. 关闭面部辅助
  3. 关闭自动快门，仅保留手动拍照
  4. 回切 Copy Pose Beta

