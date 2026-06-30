# InkOS Reference Clean-Room Design

日期：2026-06-30

## 0. 边界声明

本文件把 `G:\inkos` 作为参考项目做能力分析，但不复制 InkOS 源码、Prompt 模板、长文本规则、正则词表、测试样例、文件结构或命令实现。本文只提炼可迁移的产品与架构思想，并用 AI 小说工坊自己的数据结构、接口、命名和实现路径重建设计。

当前项目优先级顺序：

1. 当前项目规格、`AGENTS.md` 和未来 StoryForge 架构约束优先。
2. Flutter + Dart Windows 桌面应用、SQLite 本地持久化、真实数据约束优先。
3. InkOS 仅作为行为参考，不能反向决定本项目的包结构、文件名、Prompt、规则文本或 UI 形态。

已阅读的参考范围以能力定位为主，包括 InkOS 的文风分析、风格工件、写后规则验证、局部修复、审计修订循环、审查命令和相关测试。阅读方式遵循 clean-room：记录职责、输入输出、状态流和失败保护，不摘录可直接复用的实现正文。

## 1. InkOS 能力分析

### 1.1 文风分析与风格工件

InkOS 把风格拆成两层：

- 统计型画像：纯文本分析，不依赖 LLM。主要统计句长、段落长度、段落范围、词汇多样性、重复开头/节奏模式、可见修辞信号、来源名和分析时间。
- 定性型指南：使用 LLM 从参考文本中总结叙事声音、对话、场景描写、衔接、节奏、词汇和情绪表达等可模仿特征；当样本文本太短、LLM 不可用或返回空结果时，降级为基于统计画像的简版指南。

这个设计的关键价值不是具体字段名，而是“双轨风格记忆”：

- 统计画像可测试、低成本、可重复。
- 定性指南可读、适合给写作 agent 使用。
- 两者都落盘到书籍级上下文，使后续写作、改写、润色可以读取。
- AI 失败时不伪造能力，而是明确生成降级版指南。

### 1.2 写后验证器

InkOS 有一个确定性的写后验证器，目标是在每章生成后捕捉 Prompt 无法稳定保证的规则。它有三个明显特点：

- 零 LLM 成本：基于本地文本检查。
- 结构化返回：每个问题有规则名、严重度、描述和建议。
- 可并入审稿：严重问题会被提升为阻塞项，警告用于提示改进。

它覆盖的类别包括：

- 输出表面清理：移除模型附带的备注行、统一部分标点表面。
- 禁用句式与禁用符号。
- 高频疲劳词、公式化转折、元叙事、报告腔、作者说教。
- 集体反应、章节号指称、叙事人称漂移。
- 段落形状：过长、过碎、连续短段、密度漂移。
- 跨章重复、标题重复或标题信息坍缩。
- 书籍自定义禁忌。
- 中英文分支检查。

适合迁移的是“确定性写后守门”这个层级；不适合迁移的是具体词表、具体正则、中文规则文案、阈值和命名。

### 1.3 Spot-Fix 局部修复

InkOS 的局部修复思路是让修订器输出“目标片段 -> 替换片段”的小补丁，然后由本地代码负责应用。应用策略有几个安全点：

- 只应用能唯一定位的目标片段。
- 优先精确匹配，必要时允许空白差异的保守匹配。
- 匹配不到或匹配不唯一时跳过该补丁，而不是强行改文。
- 返回应用数量、跳过数量、触及字符数和拒绝原因。
- 局部问题只走局部补丁，避免整章重写带来新漂移。

这个模式很适合迁移到桌面编辑器，因为它天然支持差异预览、撤销、局部接受/拒绝和审计记录。

### 1.4 审计-修订闭环

InkOS 的核心闭环是：

1. 写出草稿。
2. 对长度做硬范围修正。
3. 正常化写后表面。
4. 运行 LLM 审计。
5. 合并确定性检查、AI 痕迹检查、敏感词检查和写后验证。
6. 如果审计解析失败，不自动修稿。
7. 根据问题类型决定修复方式：
   - 局部表层问题：只允许局部补丁。
   - 结构/语义问题：要求更大范围重写。
   - 混合或未知问题：允许路由器选择或交给人工。
8. 修订后重新审计。
9. 只有通过或净提升时接受新版本；否则保留原版本或回退到最佳快照。

这个闭环的关键价值是“修订也受审计约束”。它不是简单地让模型改稿，而是把每次改稿变成可评分、可回退、可追踪的版本过程。

### 1.5 审查状态与人工介入

InkOS 同时支持自动和手动模式：

- 自动模式：写完后进入审计和有限轮自动修复。
- 手动模式：写完即停，用户随后审查、修订、通过或拒绝。
- 章节索引里记录待审、审计失败、通过、拒绝等状态。
- 拒绝可以触发状态回滚，避免后续章节建立在错误版本上。

对当前 Flutter 桌面应用而言，先做手动可视化闭环更合适：用户能看到问题、差异、版本和风险；自动闭环可作为后续可选开关。

## 2. 适合迁移到当前项目的设计

### 2.1 应迁移

- 双轨文风记忆：一个可计算的文风指纹，一个可读的写作声音指南。
- AI 可用时增强，AI 不可用时降级：不显示假指南，不伪造模型能力。
- 确定性写后验证器：先覆盖表面规则、结构化问题和项目自定义禁忌。
- 结构化问题模型：严重度、作用域、位置证据、建议、来源。
- 局部修复补丁：只改可定位片段，匹配不安全则跳过。
- 审计-修订-复审闭环：修订后必须复审，不能只相信修订器。
- 最佳版本保留：自动修订变差时回退。
- 手动优先：桌面 UI 先提供用户可控的审查台，再做自动修复。
- 角色分工：正文写手、内容审核、读者模拟、叙事节奏师、主题守护者可分别消费不同上下文。

### 2.2 只可借鉴，不应照搬

- InkOS 的 TypeScript monorepo/CLI 组织方式。
- `story/` 目录里的文件工件体系。
- 具体 CLI 命令名、输出格式和状态名。
- Prompt 输出块分隔符。
- 具体审计维度标签、正则分类、中文词表和阈值。
- InkOS 的测试文本、样例断言和长规则正文。

### 2.3 暂不迁移

- 全自动多轮修稿默认开启。
- 复杂跨书/同人正典维度。
- 大量题材专用规则库。
- 针对 AI 检测的专门改写模式。
- CLI 审查工作流。

这些能力可以作为远期方向，但当前项目仍处于 Windows 桌面主界面、设置、SQLite 基础能力阶段。按 Ponytail 原则，先做最小可用闭环。

## 3. Clean-Room 重建设计

### 3.1 本项目命名

为了避免复制 InkOS 合同，当前项目使用自己的命名：

| InkOS 概念 | AI 小说工坊 clean-room 命名 | 说明 |
| --- | --- | --- |
| style_profile | `ProseFingerprint` | 可计算文风指纹 |
| style_guide | `VoiceGuide` | 可读写作声音指南 |
| post-write validator | `DraftSurfaceValidator` | 写后表面与规则验证 |
| spot-fix | `LocalizedEdit` | 局部文本编辑建议 |
| audit result | `DraftReviewReport` | 草稿审查报告 |
| review cycle | `RevisionCoordinator` | 审计-修订-复审协调器 |
| polisher | `SurfacePolishService` | 结构通过后的表层润色 |

### 3.2 领域对象

下面是建议的数据结构形状，字段名为本项目自定义，不来自 InkOS。

```dart
enum StoryLanguage { zh, en }

enum GuideGenerationMode { statistical, aiAssisted, manual }

enum DraftIssueSeverity { blocker, advice, note }

enum DraftIssueScope { surface, localText, structure, continuity, projectRule }

enum RevisionMode { localizedEdit, rewriteSection, rewriteChapter, polishOnly, manual }

class ProseFingerprint {
  final int id;
  final int novelId;
  final String sourceLabel;
  final StoryLanguage language;
  final String sampleDigest;
  final double averageSentenceUnits;
  final double sentenceUnitDeviation;
  final double averageParagraphUnits;
  final int shortestParagraphUnits;
  final int longestParagraphUnits;
  final double lexicalVariety;
  final List<String> cadenceSignals;
  final List<String> expressionSignals;
  final DateTime createdAt;
}

class VoiceGuide {
  final int id;
  final int novelId;
  final int? fingerprintId;
  final GuideGenerationMode mode;
  final List<VoiceGuideSection> sections;
  final String fallbackReason;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class VoiceGuideSection {
  final String key;
  final String title;
  final String body;
  final int position;
}

class DraftIssue {
  final String kind;
  final DraftIssueSeverity severity;
  final DraftIssueScope scope;
  final String message;
  final String suggestion;
  final TextRange? evidenceRange;
}

class DraftReviewReport {
  final int id;
  final int chapterId;
  final bool passed;
  final bool parsedOk;
  final int? score;
  final List<DraftIssue> issues;
  final String summary;
  final DateTime createdAt;
}

class LocalizedEdit {
  final String targetSnippet;
  final String replacementText;
  final String reason;
  final int? expectedOccurrence;
}

class LocalizedEditResult {
  final bool changed;
  final int appliedCount;
  final int skippedCount;
  final List<TextRange> changedRanges;
  final String? skippedReason;
  final String revisedText;
}
```

### 3.3 SQLite 持久化

当前项目已经使用 SQLite，并要求所有业务内容来自真实本地数据。建议新增表时沿用本地数据库，不引入平行文件工件体系。

建议表：

- `style_sources`
  - `id`
  - `novel_id`
  - `label`
  - `language`
  - `source_kind`
  - `sample_digest`
  - `created_at`
- `prose_fingerprints`
  - `id`
  - `novel_id`
  - `source_id`
  - `metrics_json`
  - `created_at`
- `voice_guides`
  - `id`
  - `novel_id`
  - `fingerprint_id`
  - `mode`
  - `fallback_reason`
  - `created_at`
  - `updated_at`
- `voice_guide_sections`
  - `id`
  - `guide_id`
  - `section_key`
  - `title`
  - `body`
  - `position`
- `draft_review_reports`
  - `id`
  - `chapter_id`
  - `passed`
  - `parsed_ok`
  - `score`
  - `summary`
  - `created_at`
- `draft_review_issues`
  - `id`
  - `report_id`
  - `kind`
  - `severity`
  - `scope`
  - `message`
  - `suggestion`
  - `range_start`
  - `range_end`
- `revision_sessions`
  - `id`
  - `chapter_id`
  - `input_report_id`
  - `mode`
  - `before_text_digest`
  - `after_text_digest`
  - `before_score`
  - `after_score`
  - `accepted`
  - `created_at`

不建议把完整参考原文长期复制到数据库。可优先存来源标签、摘要、hash 和用户明确导入的短样本；如果后续要保存全文，应有明确用户授权、删除入口和版权提示。

### 3.4 服务接口

建议在未来 StoryForge 层新增服务，而不是把逻辑塞进 UI Widget。

```dart
abstract class ProseFingerprintService {
  ProseFingerprint analyze({
    required int novelId,
    required String sourceLabel,
    required String text,
    required StoryLanguage language,
  });
}

abstract class VoiceGuideService {
  Future<VoiceGuide> buildGuide({
    required int novelId,
    required ProseFingerprint fingerprint,
    required String referenceText,
    required AppAiSettings aiSettings,
  });
}

abstract class DraftSurfaceValidator {
  List<DraftIssue> validate({
    required String chapterText,
    required StoryLanguage language,
    required NovelRuleSet rules,
    ProseFingerprint? fingerprint,
  });
}

abstract class DraftReviewService {
  Future<DraftReviewReport> review({
    required int chapterId,
    required String chapterText,
    required StoryContextBundle context,
    required AppAgentSettings agentSettings,
    required AppAiSettings aiSettings,
  });
}

abstract class LocalizedEditApplier {
  LocalizedEditResult apply({
    required String originalText,
    required List<LocalizedEdit> edits,
  });
}

abstract class RevisionCoordinator {
  Future<RevisionRunResult> run({
    required int chapterId,
    required RevisionMode mode,
    required DraftReviewReport report,
    required StoryContextBundle context,
  });
}
```

接口设计原则：

- UI 只调用服务，不直接拼 Prompt。
- 服务只读取真实项目、章节、设置、agent 模型配置。
- AI 设置未就绪时返回明确状态，不生成假报告。
- 所有修订结果先进入候选版本，由用户或协调器接受后再覆盖章节正文。

### 3.5 文风导入流程

建议流程：

1. 用户在小说项目里导入或粘贴参考文本。
2. `ProseFingerprintService` 生成统计指纹。
3. 指纹立即落库，作为可用低成本能力。
4. 如果 AI 可用，`VoiceGuideService` 生成定性指南。
5. 如果 AI 不可用、样本太短或调用失败，生成统计版指南，并写入 `fallbackReason`。
6. 正文写手读取 `VoiceGuide` 的短摘要和 `ProseFingerprint` 的节奏指标。

UI 建议：

- 项目内新增“文风”或“写作声音”页。
- 显示来源、分析时间、统计指标和指南段落。
- 明确标注“统计版/AI 辅助版/手动版”。
- 提供重新生成和删除入口。
- 不使用假样本文本撑版面。

### 3.6 写后验证流程

建议最小版本只做确定性规则：

1. 写作完成或用户保存章节。
2. `DraftSurfaceValidator` 清理非正文元信息。
3. 本地检查段落长度、重复片段、禁用项目词、标题重复、章节引用、基础标点和人称一致性。
4. 生成 `DraftIssue` 列表。
5. 阻塞项进入 `DraftReviewReport`；建议项显示在 UI 但不阻止保存。

首版不要建立庞大词表。先支持：

- 项目自定义禁用词/禁用句式。
- 章节标题重复。
- 段落极端过长或过碎。
- 明显的非正文备注行。
- 章节内重复段落。
- 当前项目明确要求的文本规范。

### 3.7 审查与修订流程

推荐先实现手动审查台：

```text
草稿保存
  -> 本地写后验证
  -> 可选 AI 审查
  -> 生成 DraftReviewReport
  -> 用户查看问题
  -> 用户选择：
       接受当前版本
       局部修复
       结构重写
       仅润色
       拒绝并回到上一版本
```

自动修订策略：

- `parsedOk == false`：禁止自动修订。
- 只有 `surface` 或 `localText` 阻塞项：优先 `localizedEdit`。
- 存在 `structure`、`continuity`、`projectRule` 阻塞项：要求章节级或段落级重写，并提示风险。
- 修订后必须重新运行验证和审查。
- 新版本分数没有提升、阻塞项增加或长度越界时，不自动接受。
- 保留修订前版本，支持撤销。

### 3.8 局部编辑应用器

本项目的 `LocalizedEditApplier` 应保持保守：

- 目标片段为空：跳过。
- 目标片段匹配不到：跳过。
- 目标片段匹配多次且没有 `expectedOccurrence`：跳过。
- 替换后文本为空或异常缩短：跳过并报告。
- 应用后返回改动范围，供 Flutter UI 做差异高亮。

首版不需要复杂 diff 算法。可以使用精确匹配加最小空白归一匹配；当安全性不确定时交给用户手动确认。

### 3.9 Agent 对接

当前项目已有默认 agent 定义，迁移时建议这样对齐：

- `prose_writer`：读取 `VoiceGuide`、章节目标、上下文包，生成草稿。
- `content_reviewer`：生成 `DraftReviewReport`，只负责结构、连续性、项目规则。
- `reader_simulator`：输出读者侧反馈，默认作为 `note`，不直接阻塞。
- `narrative_pacing`：提供节奏类审查或修订建议。
- `theme_guardian`：审查主题偏离。
- `character_designer`：提供角色一致性依据。

不要新增一批 InkOS 同名 agent。StoryForge 需要的是能力插槽，不是参考项目角色表。

## 4. 不得复制的部分

明确禁止复制或近似搬运：

- InkOS 的源码实现、函数体、解析器实现、正则表达式、词表和阈值。
- InkOS 的 Prompt 模板、系统提示词、用户提示词、输出格式说明和长段规则正文。
- InkOS 的 Markdown section 标题体系作为固定合同。
- InkOS 的文件名和目录结构作为本项目持久化标准，例如直接复用它的故事目录工件体系。
- InkOS 的 CLI 命令、参数名、命令输出文本和错误文案。
- InkOS 的测试样例文本、断言布局和 fixture。
- InkOS 的审计维度编号、标签集合和题材规则库。
- InkOS 的状态名、阶段日志文案和分数阈值。
- InkOS 的图片、README 表述、架构图和品牌资产。

允许迁移的只有抽象思想：

- 统计画像 + 定性指南双轨。
- 确定性写后验证。
- 问题结构化、严重度和修复作用域。
- 局部编辑优先且保守应用。
- 修订后复审、保留最佳版本、解析失败不自动修。

## 5. 推荐落地顺序

### Phase 1：规格先行

- 新增 OpenSpec change：`add-storyforge-review-loop` 或类似命名。
- 定义能力边界：文风导入、写后验证、审查报告、局部修订。
- 明确 AI 不可用时的 UI 和数据状态。

成功标准：

- specs 覆盖无 AI、有 AI、空项目、有章节、审查失败、局部修复跳过等状态。

### Phase 2：纯 Dart 确定性能力

- 实现 `ProseFingerprintService`。
- 实现首版 `DraftSurfaceValidator`。
- 实现 `LocalizedEditApplier`。
- 加最小单元测试。

成功标准：

- 不需要模型配置即可跑通。
- 测试覆盖短文本、空文本、多语言、重复匹配、匹配不唯一。

### Phase 3：SQLite 持久化

- 新增 migration。
- 保存指纹、指南、审查报告、问题和修订会话。
- Repository 查询必须返回真实数据或空状态。

成功标准：

- Dashboard 真实数据原则不被破坏。
- 不创建假项目、假章节、假指南。

### Phase 4：手动审查 UI

- 项目内增加审查面板。
- 展示问题列表、严重度、作用域、差异预览。
- 用户可接受当前版本、应用局部修复、拒绝修订。

成功标准：

- 遵循 `docs/ui-design-dna.md`。
- 桌面默认窗口截图验证无重叠、溢出或遮挡。

### Phase 5：AI 辅助审查与修订

- 接入 `AppAiSettings` 和 `AppAgentSettings`。
- `content_reviewer` 生成结构化审查报告。
- `RevisionCoordinator` 调用对应 agent 生成候选修订。
- 修订后复审，低质量结果不自动覆盖正文。

成功标准：

- AI 未配置时功能可解释地降级。
- 审查解析失败不触发自动修订。
- 修订候选可回滚。

## 6. 风险与约束

- 文风参考可能涉及第三方文本：默认做“写作声音约束”，不要宣传为逐句仿写；不要长期保存未授权全文。
- 规则库容易膨胀：首版只做项目明确需要且可测试的规则。
- 自动修订可能改坏正文：必须候选版本化、复审、可回退。
- AI 报告可能不稳定：必须有 `parsedOk` 和结构化校验。
- UI 不应成为新系统外壳：所有数据来自 SQLite 和真实设置。
- 后续如果 StoryForge 规格与本文冲突，以 StoryForge 规格为准，本文作为参考设计更新或废弃。

## 7. 最小可行版本

最小可行版本只包含：

1. `ProseFingerprintService`：统计文本节奏和段落指标。
2. `DraftSurfaceValidator`：项目禁用词、段落极端形状、标题重复、非正文备注。
3. `LocalizedEditApplier`：保守应用局部替换。
4. `DraftReviewReport` SQLite 表：保存本地验证结果。
5. 项目内审查面板：显示问题和局部修复差异。

这能先建立“写后验证与修订可追踪”的骨架。AI 生成定性指南、AI 审查、自动修订和润色服务都可以在骨架稳定后逐步接入。
