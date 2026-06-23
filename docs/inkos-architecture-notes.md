# InkOS 架构提炼

参考仓库：`F:\AI写作助手母版\inkos`

## 目录拆解

- `packages/core`：真正的小说引擎。包含 agent、pipeline、state、LLM provider、artifact/export。
- `packages/studio`：Vite/React Web UI，加本地 API server 和 SSE。
- `packages/cli`：命令入口，把 core 能力包装成 `plan/compose/draft/audit/revise/review/export`。
- `skills/SKILL.md`：把 InkOS 当成可复用技能，强调“工具结果和文件存在才算完成”。

## 核心流水线

InkOS 的主线不是简单的 Agent 串联，而是：

```text
planChapter
-> composeChapter
-> writeChapter
-> auditChapter
-> reviseChapter
-> persistChapterArtifacts
-> review approve/reject
-> export
```

关键点：

- `PlannerAgent` 产出章节意图和 memo。
- `ComposerAgent` 选上下文，写 `context.json / rule-stack.yaml / trace.json`。
- `WriterAgent` 只写正文和状态 delta。
- `ContinuityAuditor` 做审计。
- `ReviserAgent` 默认只做有限自动修复。
- `persistChapterArtifacts` 是唯一最终落盘口。

## Agent 管线

可复用思想：

- Agent 之间不直接互改全局状态，只交换 artifact。
- 每个 Agent 的输入/输出有固定契约。
- `Coordinator/Director` 只编排，不写正文。
- Writer 只写 prose，不负责审稿、导出、审批。
- Editor 同时负责 audit/revise，但修订结果仍走统一 persistence。

不建议复制：

- 10+ Agent 的历史兼容层。
- 多 provider、短篇、互动世界、封面生成等旁路功能。
- 旧 markdown truth files 与新 JSON state 的双轨迁移代码。
- 大量热修补丁式 Phase 文件名。

## Artifact

InkOS 强项是 artifact-first：

- runtime artifact：`chapter-0001.context.json`、`chapter-0001.rule-stack.yaml`、`chapter-0001.trace.json`
- chapter artifact：章节 markdown、章节 index
- truth artifact：`story/state/*.json` 与人可读 markdown 投影
- export artifact：txt/md/epub

新项目应保留“每一步都写 artifact”，但第一版只保留一个统一 `ArtifactStore`，不要先拆很多存储后端。

## State

InkOS 的状态分三层：

- 结构化 state：权威状态。
- markdown projection：给人检查。
- memory db：检索加速。

新项目第一版建议：

- 权威状态只用 JSON schema。
- markdown 作为 artifact 输出，不作为权威源。
- 长期记忆先存 `facts/hooks/summaries`，后续再加向量或 SQLite。

## Audit / Revise

InkOS 的审稿闭环：

```text
draft
-> deterministic checks
-> LLM audit
-> one repair pass
-> re-audit
-> pick better snapshot
-> ready-for-review / audit-failed
```

新项目应复制这个策略，不复制复杂实现：

- 自动修复最多一轮。
- 修差了就回退。
- 不能把 audit 问题悄悄吞掉。
- AI 味处理使用 `humanizer-zh adapter`，不要给每个 Agent 单独造一套。

## Human Review Gate

InkOS 的 gate 很轻：

- `ready-for-review`
- `audit-failed`
- `approved`
- `rejected`

批准只是改章节 index 状态；拒绝默认回滚到上一章快照。

新项目第一版同样保持轻量：章节到 `ready-for-review` 就停，用户批准后才 export。
