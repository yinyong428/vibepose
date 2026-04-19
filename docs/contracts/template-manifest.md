# Template Manifest Contract

## 最小字段

- `templateId`
- `version`
- `status`
- `displayNameKey`
- `subtitleKey`
- `sceneTags`
- `styleTags`
- `effectTags`
- `framing`
- `subjectCount`
- `difficulty`
- `cameraFacing`
- `mirrorPolicy`
- `pose`
- `matching`
- `guide`

## 命名规范

- 模板 ID 语言无关，统一使用小写下划线
- 推荐模式：`vp_{scene}_{framing}_{style}_{index}`
- 左右镜像默认通过 `mirrorPolicy` 运行时控制，不复制 template

## 匹配配置

- `readyThreshold`
- `perfectThreshold`
- `holdDuration`
- `jointWeights`

## 引导配置

- `coachKey`
- `photographerKey`
- `framingKey`
- `preferredCamera`

## MVP 约束

- `subjectCount = 1`
- 模板资源全部本地随包发布
- starter pack 先交付 `10-15` 个可联调模板

