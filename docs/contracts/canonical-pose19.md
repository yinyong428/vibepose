# CanonicalPose19 Contract

## 目标

统一 `Vision`、模板资源、评分引擎和未来导入能力的骨架语义，避免业务层直接依赖底层识别引擎输出。

## 数据结构

- `PosePoint`
  - `joint: JointName`
  - `x: Double`
  - `y: Double`
  - `confidence: Double`
- `CanonicalPose19`
  - `points: [JointName: PosePoint]`
  - `coverage: Double`
  - `source: PoseEngineSource`
  - `mirrorMode: PoseMirrorMode`

## JointName

- `nose`
- `neck`
- `leftShoulder`
- `rightShoulder`
- `leftElbow`
- `rightElbow`
- `leftWrist`
- `rightWrist`
- `leftHip`
- `rightHip`
- `leftKnee`
- `rightKnee`
- `leftAnkle`
- `rightAnkle`
- `leftEye`
- `rightEye`
- `leftEar`
- `rightEar`
- `pelvis`

## 规则

- 坐标归一化到 `0...1`
- 原点采用预览层左上角
- `neck` 与 `pelvis` 为导出关节，可由肩膀/髋部中点推导
- 低置信度点可以保留，但不得参与高权重评分
- 业务层不得直接读取 `Vision` 原始 joint enum

