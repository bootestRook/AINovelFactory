# AI Novel Factory 架构规划

## 第一版代码边界

当前实现只建最小骨架：

```text
src/
  core/
    schemas.ts          统一 Schema
    artifact-store.ts   ArtifactStore 接口 + 浏览器 localStorage 实现
    agents.ts           7-Agent 职责表
    orchestrator.ts     Pipeline Orchestrator
  App.tsx               可视化 WebUI
```

先不做：

- 真实 LLM provider routing。
- 文件系统后端。
- SQLite/向量检索。
- 多书籍队列和 daemon。
- 复杂审批流。

## 目标流水线

```text
initBook
-> researchMarket
-> buildCharacters
-> buildOutline
-> planChapter
-> composeContext
-> draftChapter
-> settleState
-> auditChapter
-> reviseChapter
-> approveChapter
-> exportBook
```

默认在 `reviseChapter` 后打开 human review gate。

## 7-Agent 契约

| Agent | 输入 | 输出 |
| --- | --- | --- |
| Agent1 Coordinator | brief, project_state | run_plan |
| Agent2 Market Analyst | brief | market_report, genre_rules |
| Agent3 Character Designer | market_report, genre_rules | characters, character_matrix |
| Agent4 Outline Architect | characters, rules | volume_outline, arc_plan |
| Agent5 Plot Planner | outline, state | chapter_intent, scene_cards, context_package, rule_stack |
| Agent6 Lead Writer | intent, cards, context, rules | chapter_draft, state_delta |
| Agent7 Editor | draft, audit rules, state | audit_report, chapter_final |

`humanizer-zh` 只作为通用 adapter：

- Agent3-5：检查设定/大纲/场景卡模板感。
- Agent6：约束正文生成。
- Agent7：审稿、改写、评分。

## State 策略

权威状态只放结构化 JSON：

- `ProjectState`
- `ChapterMeta`
- `ArtifactRef`
- `memory.facts`
- `memory.hooks`
- `memory.summaries`

Agent 不能直接改 state。只能产出 artifact 或 `state_delta`，由 orchestrator 统一应用。

## Artifact Store 策略

第一版接口：

- `put`
- `get`
- `list`
- `saveProject`
- `loadProject`
- `appendEvent`
- `listEvents`

当前实现用 `localStorage`，后续加 Node FS store 时不需要改 Agent 和 UI。

## 审计与修订闭环

最小规则：

- draft 后必须 audit。
- critical issue 不自动通过。
- revise 只跑一轮。
- revise 后仍需 human gate。
- export 默认只导出 approved 章节。

这覆盖当前目标。等真实生成稳定后，再加 token budget、并发队列、SQLite memory。
