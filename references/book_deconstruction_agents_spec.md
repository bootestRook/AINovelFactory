# 拆书主链 Agent 完整设定规格

> 版本：v0.1  
> 范围：仅包含“拆书主链”Agent，不包含实验写作 Agent、Skill 效果验证 Agent、Skill 修订 Agent。  
> 目标：把一本参考小说拆解为结构化分析资产，并最终编译为可被独立写作 Agent 调用的 `.skill` 包。

---

## 0. 总体原则

### 0.1 拆书主链的目标

拆书主链不负责写新文本，不负责仿写，不负责实验写作。

拆书主链只负责：

```text
原始小说
→ 清洗分章
→ 章节级客观拆解
→ 全书总览
→ 情节结构拆解
→ 商业机制拆解
→ 人物关系拆解
→ 伏笔悬念拆解
→ 文风指纹拆解
→ 可迁移模板蒸馏
→ Skill 编译
→ 拆书质检
```

最终产物不是普通分析报告，而是：

```text
compiled_skill/{book_id}.skill/
```

该 Skill 后续可被独立的实验写作 Agent 调用。

---

### 0.2 拆书主链不做的事

拆书主链禁止做以下事情：

1. 直接生成原创小说正文；
2. 直接仿写参考小说；
3. 复刻原书剧情、人名、组织、专有设定；
4. 将大段原文塞入 Skill；
5. 将推测当成事实；
6. 把未质检的产物编译为正式 Skill；
7. 把实验写作结果反向污染原始拆书产物。

---

### 0.3 每个 Agent 的统一输出规则

除非特别说明，每个主链 Agent 至少输出两类文件：

```text
.md    给人阅读、复核、编辑
.json  给系统读取、检索、编译和评测
```

原则：

- Markdown 负责可读性；
- JSON 负责结构化、检索、编译、自动质检；
- Markdown 不得作为唯一产物；
- JSON 不得只有自然语言大段文本；
- 长篇内容必须分文件，不允许堆成一个超大文件。

---

### 0.4 长文本拆分规则

| 内容类型 | 存储方式 | 原因 |
|---|---|---|
| 全书总览 | 单独 md/json | 全局快速理解 |
| 每章拆解 | index + 每章独立 md/json | 防止爆文件，便于单章检索 |
| 每章风格 | index + 每章独立 json | 追踪风格变化 |
| 人物资料 | index + 每人物独立 md/json | 人物常被单独读取 |
| 人物声纹 | index + 每人物独立 json | 写作时按角色调用 |
| 重要伏笔 | index + 每伏笔独立 md/json | 伏笔有生命周期 |
| 模板 | 总模板 + 分类模板 | 后续可独立调用 |
| Skill | 独立目录 | 作为最终可调用资产 |

---

## 1. 推荐项目目录结构

```text
book_lab/
├── agents/
│   ├── 00_orchestrator.md
│   ├── 01_text_cleaner.md
│   ├── 02_chapter_content_analyst.md
│   ├── 03_book_overview_analyst.md
│   ├── 04_plot_structure_analyst.md
│   ├── 05_commercial_mechanics_analyst.md
│   ├── 06_character_relationship_analyst.md
│   ├── 07_foreshadow_suspense_analyst.md
│   ├── 08_style_fingerprint_analyst.md
│   ├── 09_template_distiller.md
│   ├── 10_skill_compiler.md
│   └── 11_analysis_qa_auditor.md
│
├── skills/
│   ├── workflow_router.skill/
│   ├── text_cleaning.skill/
│   ├── chapter_analysis.skill/
│   ├── book_overview.skill/
│   ├── plot_analysis.skill/
│   ├── commercial_analysis.skill/
│   ├── character_analysis.skill/
│   ├── foreshadow_analysis.skill/
│   ├── style_fingerprint.skill/
│   ├── template_distillation.skill/
│   ├── skill_compile.skill/
│   └── analysis_qa.skill/
│
├── books/
│   └── book_001/
│       ├── meta/
│       ├── source/
│       ├── analysis/
│       └── compiled_skill/
│
└── templates/
    ├── agent_output_schema/
    ├── skill_schema/
    └── analysis_schema/
```

---

## 2. 单本书目录结构

```text
books/book_001/
├── meta/
│   ├── book_info.json
│   ├── source_manifest.json
│   ├── analysis_manifest.json
│   └── quality_report.json
│
├── source/
│   ├── raw.txt
│   ├── cleaned.txt
│   └── chapters/
│       ├── index.md
│       ├── index.json
│       ├── ch001.txt
│       ├── ch002.txt
│       └── ...
│
├── analysis/
│   ├── overview/
│   │   ├── book_overview.md
│   │   └── book_overview.json
│   │
│   ├── chapters/
│   │   ├── index.md
│   │   ├── index.json
│   │   ├── ch001.md
│   │   ├── ch001.json
│   │   ├── ch002.md
│   │   ├── ch002.json
│   │   └── ...
│   │
│   ├── plot/
│   │   ├── index.md
│   │   ├── global_plot_arc.md
│   │   ├── global_plot_arc.json
│   │   ├── chapter_function_map.json
│   │   └── rhythm_curve.json
│   │
│   ├── commercial/
│   │   ├── commercial_mechanics.md
│   │   ├── commercial_mechanics.json
│   │   ├── hook_map.json
│   │   ├── payoff_map.json
│   │   └── reader_expectation_curve.json
│   │
│   ├── characters/
│   │   ├── index.md
│   │   ├── index.json
│   │   ├── character_network.json
│   │   ├── char_001.md
│   │   ├── char_001.json
│   │   └── ...
│   │
│   ├── foreshadowing/
│   │   ├── index.md
│   │   ├── index.json
│   │   ├── foreshadow_map.json
│   │   ├── fs_001.md
│   │   ├── fs_001.json
│   │   └── ...
│   │
│   ├── style/
│   │   ├── style_fingerprint_global.json
│   │   ├── style_guide.md
│   │   ├── chapter_style_index.md
│   │   ├── chapters/
│   │   │   ├── ch001_style.json
│   │   │   └── ...
│   │   ├── character_voice/
│   │   │   ├── index.md
│   │   │   ├── char_001_voice.json
│   │   │   └── ...
│   │   └── scene_style/
│   │       ├── suspense_scene.json
│   │       ├── dialogue_scene.json
│   │       ├── action_scene.json
│   │       ├── reveal_scene.json
│   │       └── daily_scene.json
│   │
│   ├── templates/
│   │   ├── transfer_templates.md
│   │   ├── transfer_templates.json
│   │   ├── opening_templates.md
│   │   ├── chapter_templates.json
│   │   ├── dialogue_templates.json
│   │   └── hook_templates.json
│   │
│   └── qa/
│       ├── analysis_quality_report.md
│       ├── analysis_quality_report.json
│       └── missing_items.json
│
└── compiled_skill/
    └── book_001.skill/
        ├── skill_manifest.json
        ├── README.md
        ├── style_guide.md
        ├── structure_patterns.md
        ├── commercial_patterns.md
        ├── character_patterns.md
        ├── foreshadow_patterns.md
        ├── chapter_rhythm.json
        ├── character_voice_patterns.json
        ├── scene_style_patterns.json
        ├── writing_constraints.json
        ├── forbidden_copy_rules.md
        └── usage_examples.md
```

---

# 3. 拆书主链 Agent 总表

| 编号 | Agent | 核心职责 | 主要产物 |
|---|---|---|---|
| 00 | 拆书总控 Agent | 编排流程、分发任务、登记产物 | `analysis_manifest.json` |
| 01 | 文本清洗 Agent | 清洗原文、分章、建索引 | `cleaned.txt`、章节 txt |
| 02 | 章节内容 Agent | 每章客观内容拆解 | `chapters/chXXX.md/json` |
| 03 | 全书总览 Agent | 全书级作品地图 | `book_overview.md/json` |
| 04 | 情节结构 Agent | 情节骨架、章节功能、节奏曲线 | `plot/*.json` |
| 05 | 商业机制 Agent | 爽点、期待、付费点、情绪奖励 | `commercial/*.json` |
| 06 | 人物关系 Agent | 人物档案、关系网、人物弧线 | `characters/*.json` |
| 07 | 伏笔悬念 Agent | 伏笔、秘密、误导、回收 | `foreshadowing/*.json` |
| 08 | 文风指纹 Agent | 叙述风格、声纹、场景风格 | `style/*.json` |
| 09 | 模板蒸馏 Agent | 可迁移模板 | `templates/*.json` |
| 10 | Skill 编译 Agent | 编译 `.skill` 包 | `compiled_skill/*.skill/` |
| 11 | 拆书质检 Agent | 完整性、一致性、复制风险检查 | `qa/*.json` |

---

# 4. Agent 00：拆书总控 Agent

## 4.1 定位

拆书系统的流程总导演。

它不直接做具体分析，而是负责编排、调度、依赖检查、产物登记和阶段推进。

---

## 4.2 负责范围

1. 创建拆书任务；
2. 检查输入文件是否齐全；
3. 创建 book 目录；
4. 调用文本清洗 Agent；
5. 根据章节索引创建章节分析队列；
6. 调用各分析 Agent；
7. 记录每个 Agent 的输入、输出、状态；
8. 检查关键产物是否缺失；
9. 触发 Skill 编译；
10. 触发拆书质检；
11. 生成 `analysis_manifest.json`。

---

## 4.3 禁止事项

1. 不直接分析文风；
2. 不直接分析人物；
3. 不直接总结章节；
4. 不直接生成实验文本；
5. 不擅自改写原文；
6. 不把失败任务标记为成功；
7. 不跳过质检直接编译正式 Skill。

---

## 4.4 输入

```text
books/{book_id}/source/raw.txt
books/{book_id}/meta/book_info.json
用户指定的拆书目标
用户指定的拆书深度
```

---

## 4.5 可调用 Skill 集

### 必需 Skill

```text
workflow_router.skill
```

用途：判断当前阶段应调用哪个 Agent。

```text
task_queue_manager.skill
```

用途：创建章节级任务队列，支持失败重试。

```text
file_manifest_writer.skill
```

用途：登记输入输出文件路径、hash、状态、版本。

```text
dependency_checker.skill
```

用途：检查某个 Agent 执行前所需产物是否存在。

```text
result_merger.skill
```

用途：合并各 Agent 的摘要结果，供全书级 Agent 使用。

```text
analysis_progress_tracker.skill
```

用途：跟踪拆书进度。

```text
conflict_detector.skill
```

用途：检测不同 Agent 产物之间的明显矛盾。

### 缺失处理

如果以上 Skill 不存在，Codex 应先在 `skills/` 下创建对应 Skill 目录，并补充：

```text
SKILL.md
schema/input.schema.json
schema/output.schema.json
README.md
```

---

## 4.6 输出产物

### JSON

```text
books/{book_id}/meta/analysis_manifest.json
books/{book_id}/meta/quality_report.json
```

### Markdown

```text
books/{book_id}/analysis/qa/analysis_quality_report.md
```

---

## 4.7 analysis_manifest.json 结构

```json
{
  "book_id": "book_001",
  "pipeline_version": "0.1.0",
  "status": "running",
  "source": {
    "raw_file": "source/raw.txt",
    "cleaned_file": "source/cleaned.txt",
    "chapter_index": "source/chapters/index.json"
  },
  "agents": [
    {
      "agent_id": "01_text_cleaner",
      "status": "completed",
      "inputs": [],
      "outputs": [],
      "errors": []
    }
  ],
  "required_outputs": [],
  "missing_outputs": [],
  "created_at": "",
  "updated_at": ""
}
```

---

## 4.8 质量标准

1. 每个 Agent 执行前必须检查依赖；
2. 每个 Agent 执行后必须登记产物；
3. 每章必须有 `md + json`；
4. 每个人物必须有 `md + json`；
5. 每个重要伏笔必须有 `md + json`；
6. Skill 编译前不得存在 blocker 级缺失；
7. 任何失败任务都必须记录失败原因。

---

## 4.9 失败处理

| 问题 | 处理 |
|---|---|
| 缺少 raw.txt | 停止流程，要求补输入 |
| 章节切分失败 | 回退给文本清洗 Agent 重试 |
| 某章分析失败 | 标记该章 failed，不影响其他章节继续 |
| 全书总览缺依赖 | 等待章节分析完成 |
| Skill 编译前缺关键文件 | 阻止编译 |
| 质检失败 | 输出 blocker，不进入实验阶段 |

---

# 5. Agent 01：文本清洗 Agent

## 5.1 定位

把原始小说文本处理成可分析的干净章节文件。

它是所有后续 Agent 的基础。

---

## 5.2 负责范围

1. 识别文本编码；
2. 修正常见乱码；
3. 清除广告、网址、无关页眉页脚；
4. 标准化空行；
5. 标准化章节标题；
6. 识别重复章节；
7. 可选繁简转换；
8. 可选标点标准化；
9. 分章；
10. 生成章节索引；
11. 输出清洗报告。

---

## 5.3 禁止事项

1. 不改写正文；
2. 不润色原文；
3. 不总结剧情；
4. 不删除疑似正文的内容，除非标记为 `uncertain_noise`；
5. 不合并不同章节的正文；
6. 不把目录误当正文。

---

## 5.4 输入

```text
books/{book_id}/source/raw.txt
books/{book_id}/meta/book_info.json
```

---

## 5.5 可调用 Skill 集

```text
encoding_detector.skill
```

检测编码、异常字符、乱码比例。

```text
text_normalizer.skill
```

处理空行、全角半角、异常空格、换行。

```text
chapter_splitter.skill
```

按章节标题、序号、格式规则分章。

```text
duplicate_detector.skill
```

检测重复章节、重复段落、重复目录。

```text
noise_remover.skill
```

删除广告、网站提示、无关版权页、爬虫残留。

```text
punctuation_normalizer.skill
```

可选：统一中文标点。

```text
source_integrity_checker.skill
```

检查清洗前后字符数变化、章节连续性、异常缺口。

---

## 5.6 输出产物

### 文本

```text
books/{book_id}/source/cleaned.txt
books/{book_id}/source/chapters/ch001.txt
books/{book_id}/source/chapters/ch002.txt
...
```

### Markdown

```text
books/{book_id}/source/chapters/index.md
```

### JSON

```text
books/{book_id}/source/chapters/index.json
books/{book_id}/meta/source_manifest.json
```

---

## 5.7 index.json 结构

```json
{
  "book_id": "book_001",
  "chapter_count": 0,
  "chapters": [
    {
      "chapter_id": "ch001",
      "title": "第一章",
      "source_file": "source/chapters/ch001.txt",
      "char_count": 3500,
      "start_offset": 0,
      "end_offset": 3500,
      "hash": "",
      "quality_flags": []
    }
  ],
  "cleaning_flags": [],
  "uncertain_noise_ranges": []
}
```

---

## 5.8 质量标准

1. 章节 ID 必须连续，例如 `ch001`、`ch002`；
2. 每章必须有独立 `.txt`；
3. `index.md` 与 `index.json` 必须一致；
4. 清洗后正文总长度不得异常缩减；
5. 未确定是否为广告的内容不得直接删除；
6. 清洗报告必须记录所有删除规则。

---

## 5.9 失败处理

| 问题 | 处理 |
|---|---|
| 无法识别章节 | 生成 `single_block.txt` 并标记 `chapter_split_failed` |
| 重复章节 | 保留首个版本，重复版本登记到 manifest |
| 广告识别不确定 | 标记为 uncertain，不直接删除 |
| 编码异常 | 输出错误报告，保留原始 raw.txt |

---

# 6. Agent 02：章节内容 Agent

## 6.1 定位

负责每章的客观内容拆解。

它只拆“发生了什么”，不拆“为什么好看”，也不拆“文风如何”。

---

## 6.2 负责范围

1. 一句话摘要；
2. 详细摘要；
3. 出场人物；
4. 出现地点；
5. 关键事件；
6. 主要冲突；
7. 信息增量；
8. 人物状态变化；
9. 道具、资源、能力变化；
10. 章节结尾状态；
11. 与上一章的连接；
12. 对下一章的拉力；
13. 不确定项标注。

---

## 6.3 禁止事项

1. 不评价文风；
2. 不判断商业价值；
3. 不分析全书主题；
4. 不把角色谎言当客观事实；
5. 不把读者猜测当事实；
6. 不替作者补设定；
7. 不生成新剧情。

---

## 6.4 输入

```text
books/{book_id}/source/chapters/chXXX.txt
books/{book_id}/source/chapters/index.json
books/{book_id}/analysis/chapters/chXXX-1.json，可选
```

---

## 6.5 可调用 Skill 集

```text
chapter_summarizer.skill
```

生成一句话摘要和详细摘要。

```text
entity_extractor.skill
```

抽取人物、地点、组织、道具、专有名词。

```text
event_extractor.skill
```

抽取本章事件序列。

```text
conflict_extractor.skill
```

识别本章显性冲突和隐性冲突。

```text
state_delta_extractor.skill
```

识别人物、地点、道具、关系的状态变化。

```text
information_gain_detector.skill
```

识别本章新增信息。

```text
timeline_marker.skill
```

识别时间、日期、顺序、前后关系。

---

## 6.6 输出产物

### Markdown

```text
books/{book_id}/analysis/chapters/ch001.md
```

### JSON

```text
books/{book_id}/analysis/chapters/ch001.json
```

### Index 更新

```text
books/{book_id}/analysis/chapters/index.md
books/{book_id}/analysis/chapters/index.json
```

---

## 6.7 chXXX.md 结构

```text
# ch001 章节内容拆解

## 一句话摘要

## 详细摘要

## 本章客观事件

## 出场人物

## 地点与场景

## 冲突

## 信息增量

## 状态变化

## 道具 / 资源 / 能力变化

## 章节结尾状态

## 与上一章连接

## 对下一章拉力

## 不确定项
```

---

## 6.8 chXXX.json 结构

```json
{
  "book_id": "book_001",
  "chapter_id": "ch001",
  "title": "",
  "one_line_summary": "",
  "detailed_summary": "",
  "characters_present": [],
  "locations": [],
  "organizations": [],
  "items_or_resources": [],
  "main_events": [
    {
      "event_id": "ch001_evt001",
      "summary": "",
      "participants": [],
      "location": "",
      "time_marker": "",
      "evidence_ref": ""
    }
  ],
  "conflicts": [],
  "new_information": [],
  "state_changes": [],
  "chapter_ending_state": "",
  "links_to_previous_chapter": [],
  "next_chapter_pull": "",
  "uncertain_points": [],
  "confidence": 0.0
}
```

---

## 6.9 质量标准

1. 摘要必须具体，不能只有“推进剧情”；
2. 所有状态变化必须有证据来源；
3. 角色主观认知必须标记为 `subjective`；
4. 角色谎言必须标记为 `claimed_by_character`；
5. 每章至少输出一个 `chapter_ending_state`；
6. 不确定内容必须进入 `uncertain_points`。

---

# 7. Agent 03：全书总览 Agent

## 7.1 定位

生成全书级作品地图。

它不是逐章复述，而是把整本书压缩成可理解、可迁移、可用于 Skill 编译的总览资产。

---

## 7.2 负责范围

1. 全书一句话定位；
2. 题材类型；
3. 核心卖点；
4. 主线目标；
5. 世界观基底；
6. 主角成长路径；
7. 主要人物与阵营；
8. 主要矛盾；
9. 全书阶段划分；
10. 情绪体验曲线；
11. 读者期待管理；
12. 全书最强机制；
13. 可迁移价值；
14. 不建议迁移内容。

---

## 7.3 禁止事项

1. 不逐章复述；
2. 不输出空泛评价，例如“节奏紧凑、人物鲜明”；
3. 不复刻原书设定；
4. 不替原书拔高主题；
5. 不直接生成写作模板；
6. 不把自身偏好当成作品结论。

---

## 7.4 输入

```text
books/{book_id}/analysis/chapters/index.json
books/{book_id}/analysis/chapters/*.json
books/{book_id}/analysis/plot/global_plot_arc.json，可选
books/{book_id}/analysis/commercial/commercial_mechanics.json，可选
books/{book_id}/analysis/characters/index.json，可选
```

---

## 7.5 可调用 Skill 集

```text
book_summarizer.skill
```

汇总全书信息。

```text
genre_classifier.skill
```

判断题材、类型、叙事类别。

```text
core_hook_extractor.skill
```

抽取最核心的阅读钩子。

```text
theme_detector.skill
```

识别作品真实主题，但不得过度拔高。

```text
macro_arc_synthesizer.skill
```

合成全书阶段结构。

```text
transferability_analyzer.skill
```

判断哪些机制可迁移，哪些不应迁移。

---

## 7.6 输出产物

### Markdown

```text
books/{book_id}/analysis/overview/book_overview.md
```

### JSON

```text
books/{book_id}/analysis/overview/book_overview.json
```

---

## 7.7 book_overview.md 结构

```text
# 全书总览

## 作品一句话定位

## 题材与类型

## 核心卖点

## 主线目标

## 世界观基底

## 主角成长路径

## 主要人物与阵营

## 全书阶段划分

## 主要矛盾

## 情绪体验曲线

## 读者期待管理

## 全书最强机制

## 可迁移价值

## 不建议迁移内容
```

---

## 7.8 book_overview.json 结构

```json
{
  "book_id": "book_001",
  "logline": "",
  "genre": [],
  "subgenres": [],
  "target_reader_experience": [],
  "core_selling_points": [],
  "main_plot_goal": "",
  "world_base": "",
  "protagonist_arc": "",
  "major_conflicts": [],
  "major_factions": [],
  "macro_phases": [
    {
      "phase_id": "phase_001",
      "name": "",
      "chapter_range": [],
      "function": "",
      "reader_experience": ""
    }
  ],
  "emotional_curve": [],
  "reader_expectation_management": [],
  "strongest_mechanisms": [],
  "transferable_mechanisms": [],
  "non_transferable_elements": [],
  "confidence": 0.0
}
```

---

## 7.9 质量标准

1. 每个结论都要能追溯到章节分析或其他分析产物；
2. 不得只给抽象评价；
3. 可迁移机制必须抽象到机制层，而不是剧情层；
4. 不建议迁移内容必须明确原因；
5. 读者体验必须具体，例如“压抑后释放”“秘密揭示奖励”，而不是“好看”。

---

# 8. Agent 04：情节结构 Agent

## 8.1 定位

拆解故事骨架、章节功能、冲突升级和节奏曲线。

它回答的问题是：

```text
这本书的故事是怎么搭起来的？
每一章在结构上起什么作用？
读者为什么会被下一章牵引？
```

---

## 8.2 负责范围

1. 全书情节阶段；
2. 每章功能分类；
3. 主线推进路径；
4. 支线插入方式；
5. 冲突升级链；
6. 高潮分布；
7. 反转节点；
8. 信息释放节奏；
9. 开场钩子；
10. 章节结尾钩子；
11. 章节间因果链；
12. 节奏曲线。

---

## 8.3 禁止事项

1. 不分析文风细节；
2. 不分析角色对白声纹；
3. 不判断商业爽点价值；
4. 不生成新剧情；
5. 不把普通事件强行归类为反转；
6. 不给没有证据的结构标签。

---

## 8.4 输入

```text
books/{book_id}/analysis/chapters/*.json
books/{book_id}/analysis/overview/book_overview.json
```

---

## 8.5 可调用 Skill 集

```text
plot_arc_detector.skill
```

识别全书起承转合、卷结构、阶段结构。

```text
chapter_function_classifier.skill
```

判断每章功能，例如开局钩子、信息揭示、冲突升级、阶段收束。

```text
conflict_escalation_mapper.skill
```

绘制冲突升级链。

```text
rhythm_curve_builder.skill
```

生成节奏曲线。

```text
hook_detector.skill
```

识别开头钩子、结尾钩子和下一章拉力。

```text
reversal_detector.skill
```

识别反转、伪反转、信息重估。

```text
subplot_mapper.skill
```

识别支线插入、支线回收。

---

## 8.6 输出产物

### Markdown

```text
books/{book_id}/analysis/plot/index.md
books/{book_id}/analysis/plot/global_plot_arc.md
```

### JSON

```text
books/{book_id}/analysis/plot/global_plot_arc.json
books/{book_id}/analysis/plot/chapter_function_map.json
books/{book_id}/analysis/plot/rhythm_curve.json
```

---

## 8.7 chapter_function_map.json 结构

```json
{
  "book_id": "book_001",
  "chapters": [
    {
      "chapter_id": "ch001",
      "primary_function": "opening_hook",
      "secondary_functions": ["character_intro", "world_abnormality"],
      "conflict_level": 3,
      "information_gain_level": 4,
      "tension_level_start": 2,
      "tension_level_end": 5,
      "hook_type": "abnormal_event",
      "ending_hook": "",
      "next_chapter_pull": "",
      "structural_notes": []
    }
  ]
}
```

---

## 8.8 global_plot_arc.json 结构

```json
{
  "book_id": "book_001",
  "macro_structure": [],
  "mainline_path": [],
  "subplot_threads": [],
  "conflict_escalation_chain": [],
  "major_reversals": [],
  "climax_distribution": [],
  "information_release_pattern": [],
  "chapter_transition_patterns": []
}
```

---

## 8.9 质量标准

1. 每章必须有明确功能；
2. 章节功能不能全部相同；
3. 反转必须有“旧认知”和“新认知”的变化；
4. 冲突升级必须体现压力变化；
5. 节奏曲线必须可视化为数值或阶段；
6. 结构分析必须能服务模板蒸馏。

---

# 9. Agent 05：商业机制 Agent

## 9.1 定位

拆解“为什么读者想继续看”。

它主要服务网文、类型小说、商业叙事研究。

---

## 9.2 负责范围

1. 核心读者承诺；
2. 爽点机制；
3. 压抑-释放结构；
4. 期待感管理；
5. 危机升级；
6. 付费钩子；
7. 主角收益；
8. 情绪奖励；
9. 读者代入点；
10. 类型套路；
11. 反套路；
12. 留存机制。

---

## 9.3 禁止事项

1. 不评价文学性；
2. 不复述剧情；
3. 不分析句式；
4. 不直接写模板；
5. 不把“我觉得爽”当成机制；
6. 不把所有冲突都归类为爽点。

---

## 9.4 输入

```text
books/{book_id}/analysis/chapters/*.json
books/{book_id}/analysis/plot/chapter_function_map.json
books/{book_id}/analysis/overview/book_overview.json
```

---

## 9.5 可调用 Skill 集

```text
hook_value_analyzer.skill
```

分析钩子的吸引力来源。

```text
payoff_detector.skill
```

识别读者获得满足的节点。

```text
reader_expectation_modeler.skill
```

建模读者期待的建立、延迟、满足。

```text
tension_reward_mapper.skill
```

分析压抑、危机、释放、奖励之间的关系。

```text
commercial_pattern_classifier.skill
```

识别商业类型套路。

```text
chapter_retention_analyzer.skill
```

判断章节末尾留存拉力。

---

## 9.6 输出产物

### Markdown

```text
books/{book_id}/analysis/commercial/commercial_mechanics.md
```

### JSON

```text
books/{book_id}/analysis/commercial/commercial_mechanics.json
books/{book_id}/analysis/commercial/hook_map.json
books/{book_id}/analysis/commercial/payoff_map.json
books/{book_id}/analysis/commercial/reader_expectation_curve.json
```

---

## 9.7 commercial_mechanics.json 结构

```json
{
  "book_id": "book_001",
  "core_reader_promises": [],
  "main_reward_loops": [],
  "suppression_release_patterns": [],
  "upgrade_patterns": [],
  "mystery_reward_patterns": [],
  "relationship_reward_patterns": [],
  "paid_chapter_hook_patterns": [],
  "retention_patterns": [],
  "risk_of_overuse": []
}
```

---

## 9.8 hook_map.json 结构

```json
{
  "book_id": "book_001",
  "hooks": [
    {
      "hook_id": "hook_001",
      "chapter_id": "ch001",
      "hook_type": "mystery",
      "reader_question": "",
      "promise": "",
      "expected_payoff": "",
      "actual_payoff_ref": "",
      "retention_strength": 0
    }
  ]
}
```

---

## 9.9 质量标准

1. 商业机制必须具体到“触发—延迟—满足”；
2. 钩子必须说明读者问题是什么；
3. 爽点必须说明前置压抑或预期；
4. 不得把所有高潮都叫付费点；
5. 必须区分短期钩子和长期承诺。

---

# 10. Agent 06：人物关系 Agent

## 10.1 定位

拆人物、人物功能、人物关系和人物变化。

它回答的问题是：

```text
人物是谁？
人物想要什么？
人物之间如何变化？
人物在故事结构里承担什么作用？
```

---

## 10.2 负责范围

1. 人物索引；
2. 主角档案；
3. 配角档案；
4. 反派档案；
5. 人物目标；
6. 表层欲望；
7. 深层欲望；
8. 弱点与恐惧；
9. 能力与资源；
10. 人物关系变化；
11. 阵营关系；
12. 人物弧线；
13. 角色叙事功能；
14. 代表性对白索引。

---

## 10.3 禁止事项

1. 不替人物新增设定；
2. 不把读者猜测写成事实；
3. 不把角色自述直接当真；
4. 不分析全书商业机制；
5. 不做完整文风指纹；
6. 不评价角色是否讨喜，除非转化为明确机制。

---

## 10.4 输入

```text
books/{book_id}/analysis/chapters/*.json
books/{book_id}/source/chapters/*.txt，按需读取
```

---

## 10.5 可调用 Skill 集

```text
character_profile_builder.skill
```

构建人物档案。

```text
relationship_graph_builder.skill
```

生成人物关系网。

```text
motivation_extractor.skill
```

提取人物目标、欲望、恐惧、弱点。

```text
character_arc_analyzer.skill
```

分析人物弧线阶段。

```text
faction_mapper.skill
```

分析阵营和组织关系。

```text
dialogue_sample_collector.skill
```

收集少量代表性对白索引，不保留大段原文。

---

## 10.6 输出产物

### Markdown

```text
books/{book_id}/analysis/characters/index.md
books/{book_id}/analysis/characters/char_001.md
books/{book_id}/analysis/characters/char_002.md
```

### JSON

```text
books/{book_id}/analysis/characters/index.json
books/{book_id}/analysis/characters/character_network.json
books/{book_id}/analysis/characters/char_001.json
```

---

## 10.7 char_001.json 结构

```json
{
  "character_id": "char_001",
  "name": "",
  "aliases": [],
  "role_type": "protagonist",
  "first_appearance": "ch001",
  "last_appearance": "",
  "surface_goal": "",
  "core_goal": "",
  "hidden_desire": "",
  "fear_or_flaw": "",
  "personality_traits": [],
  "abilities_or_resources": [],
  "relationships": [
    {
      "target_character_id": "char_002",
      "relationship_type": "",
      "initial_state": "",
      "latest_state": "",
      "change_points": []
    }
  ],
  "arc_stages": [],
  "narrative_function": [],
  "representative_dialogue_refs": [],
  "uncertain_points": []
}
```

---

## 10.8 character_network.json 结构

```json
{
  "book_id": "book_001",
  "nodes": [
    {
      "character_id": "char_001",
      "name": "",
      "role_type": ""
    }
  ],
  "edges": [
    {
      "source": "char_001",
      "target": "char_002",
      "relationship_type": "ally",
      "strength": 0,
      "change_history": []
    }
  ]
}
```

---

## 10.9 质量标准

1. 人物档案必须区分事实、推测、角色自述；
2. 人物弧线必须有章节证据；
3. 关系变化必须标注触发事件；
4. 代表性对白只保存索引和短摘，不保存大段原文；
5. 主角、核心配角、主要反派必须独立成文件。

---

# 11. Agent 07：伏笔悬念 Agent

## 11.1 定位

拆伏笔、秘密、悬念、误导和回收。

它回答的问题是：

```text
读者被什么问题牵引？
秘密是怎样被隐藏、强化、误导、揭示和回收的？
```

---

## 11.2 负责范围

1. 伏笔首次出现；
2. 悬念提出；
3. 秘密隐藏；
4. 误导节点；
5. 强化节点；
6. 揭示节点；
7. 回收节点；
8. 未回收悬念；
9. 伏笔类型分类；
10. 伏笔生命周期；
11. 伏笔迁移价值。

---

## 11.3 禁止事项

1. 不替作者补回收；
2. 不把普通细节全部判成伏笔；
3. 不负责商业爽点判断；
4. 不直接生成新伏笔；
5. 不把读者脑补当伏笔；
6. 不在证据不足时强行闭环。

---

## 11.4 输入

```text
books/{book_id}/analysis/chapters/*.json
books/{book_id}/source/chapters/*.txt，按需读取
books/{book_id}/analysis/plot/chapter_function_map.json
```

---

## 11.5 可调用 Skill 集

```text
foreshadow_detector.skill
```

识别疑似伏笔。

```text
mystery_tracker.skill
```

追踪悬念问题。

```text
reveal_mapper.skill
```

匹配揭示和回收节点。

```text
misdirection_analyzer.skill
```

分析误导方式。

```text
unresolved_thread_finder.skill
```

识别未回收悬念。

```text
clue_lifecycle_tracker.skill
```

记录伏笔生命周期。

---

## 11.6 输出产物

### Markdown

```text
books/{book_id}/analysis/foreshadowing/index.md
books/{book_id}/analysis/foreshadowing/fs_001.md
books/{book_id}/analysis/foreshadowing/fs_002.md
```

### JSON

```text
books/{book_id}/analysis/foreshadowing/index.json
books/{book_id}/analysis/foreshadowing/foreshadow_map.json
books/{book_id}/analysis/foreshadowing/fs_001.json
```

---

## 11.7 fs_001.json 结构

```json
{
  "foreshadow_id": "fs_001",
  "title": "",
  "type": "secret_identity",
  "first_seed_chapter": "ch003",
  "reinforcement_chapters": [],
  "misdirection_chapters": [],
  "reveal_chapter": "",
  "payoff_chapter": "",
  "reader_question": "",
  "true_answer": "",
  "surface_explanation": "",
  "transferable_mechanism": "",
  "status": "resolved",
  "evidence_refs": [],
  "confidence": 0.0
}
```

---

## 11.8 伏笔状态枚举

```text
seeded       已埋设
reinforced   已强化
misdirected  已误导
revealed     已揭示
paid_off     已回收
unresolved   未回收
false_alarm   疑似但不是伏笔
```

---

## 11.9 质量标准

1. 每条重要伏笔必须有首次出现章节；
2. 每条 resolved 伏笔必须有揭示或回收章节；
3. 未回收伏笔必须标记为 unresolved；
4. 不确定伏笔必须标记置信度；
5. 迁移价值必须抽象为机制，而不是复刻细节。

---

# 12. Agent 08：文风指纹 Agent

## 12.1 定位

拆文风，生成可被写作 Agent 调用的风格资产。

这是拆书系统的核心 Agent 之一。

它不是输出“文风细腻、节奏紧凑”这种空话，而是输出可执行、可验证、可被 Skill 调用的风格指纹。

---

## 12.2 负责范围

1. 句长分布；
2. 段落长度分布；
3. 对白比例；
4. 动作描写比例；
5. 心理描写比例；
6. 环境描写比例；
7. 叙述距离；
8. 情绪表达方式；
9. 场景切入方式；
10. 场景收尾方式；
11. 意象库；
12. 感官偏好；
13. 修辞偏好；
14. 角色声纹；
15. 场景声纹；
16. 禁用表达；
17. 可迁移表达规则。

---

## 12.3 禁止事项

1. 不复刻原文句子；
2. 不直接仿写；
3. 不评价剧情好坏；
4. 不把“像某作者”作为输出结果；
5. 不输出无解释的抽象词；
6. 不保留高风险原句；
7. 不把全书文风强行应用到每个角色。

---

## 12.4 输入

```text
books/{book_id}/source/chapters/*.txt
books/{book_id}/analysis/chapters/*.json
books/{book_id}/analysis/characters/*.json
```

---

## 12.5 可调用 Skill 集

```text
sentence_stat_analyzer.skill
```

计算句长、短句比例、长句比例、句长方差。

```text
paragraph_stat_analyzer.skill
```

计算段落长度、对白段落比例、短段落比例。

```text
dialogue_ratio_analyzer.skill
```

计算对白占比、对白密度、对白中动作插入比例。

```text
narrative_distance_analyzer.skill
```

判断叙述距离，是贴身视角、中距离叙述还是远距离概述。

```text
imagery_domain_extractor.skill
```

抽取意象来源，例如水、火、旧物、工业、宗教、民俗、动物等。

```text
sensory_channel_analyzer.skill
```

分析视觉、听觉、嗅觉、触觉、味觉偏好。

```text
rhetoric_pattern_extractor.skill
```

抽取比喻、排比、反问、省略、对照等修辞模式。

```text
character_voice_fingerprint.skill
```

生成角色声纹。

```text
scene_style_classifier.skill
```

生成不同场景类型的风格模式。

```text
style_distance_calculator.skill
```

用于后续验证 Skill 调用文本与目标风格的距离。

---

## 12.6 输出产物

### Markdown

```text
books/{book_id}/analysis/style/style_guide.md
books/{book_id}/analysis/style/chapter_style_index.md
books/{book_id}/analysis/style/character_voice/index.md
```

### JSON

```text
books/{book_id}/analysis/style/style_fingerprint_global.json
books/{book_id}/analysis/style/chapters/ch001_style.json
books/{book_id}/analysis/style/character_voice/char_001_voice.json
books/{book_id}/analysis/style/scene_style/suspense_scene.json
books/{book_id}/analysis/style/scene_style/dialogue_scene.json
books/{book_id}/analysis/style/scene_style/action_scene.json
books/{book_id}/analysis/style/scene_style/reveal_scene.json
books/{book_id}/analysis/style/scene_style/daily_scene.json
```

---

## 12.7 style_fingerprint_global.json 结构

```json
{
  "book_id": "book_001",
  "scope": "global",
  "sentence_profile": {
    "avg_length": 0,
    "short_sentence_ratio": 0,
    "medium_sentence_ratio": 0,
    "long_sentence_ratio": 0,
    "sentence_variance": 0
  },
  "paragraph_profile": {
    "avg_paragraph_length": 0,
    "short_paragraph_ratio": 0,
    "long_paragraph_ratio": 0,
    "dialogue_paragraph_ratio": 0
  },
  "narration_profile": {
    "narrative_distance": "",
    "explanation_density": 0,
    "inner_monologue_style": "",
    "scene_entry_patterns": [],
    "scene_exit_patterns": []
  },
  "dialogue_profile": {
    "directness": 0,
    "ellipsis_ratio": 0,
    "interruption_ratio": 0,
    "subtext_ratio": 0,
    "action_with_dialogue_ratio": 0
  },
  "imagery_profile": {
    "dominant_domains": [],
    "sensory_channels": [],
    "recurring_objects": []
  },
  "rhythm_profile": {
    "opening_patterns": [],
    "tension_curve_patterns": [],
    "ending_hook_patterns": []
  },
  "recommended_patterns": [],
  "forbidden_patterns": []
}
```

---

## 12.8 char_001_voice.json 结构

```json
{
  "character_id": "char_001",
  "name": "",
  "dialogue_profile": {
    "sentence_length_preference": "",
    "directness": 0,
    "uses_questions": false,
    "uses_interruptions": false,
    "uses_ellipsis": false,
    "emotional_leakage_mode": "",
    "subtext_level": 0,
    "signature_moves": []
  },
  "voice_rules": [],
  "forbidden_voice_patterns": [],
  "representative_dialogue_refs": []
}
```

---

## 12.9 质量标准

1. 必须区分全书风格、章节风格、人物声纹、场景风格；
2. 不得只输出形容词；
3. 统计指标必须尽量由程序计算；
4. LLM 负责解释和抽象，不负责伪造数据；
5. 风格规则必须可执行，例如“少直接解释情绪，用动作外化”；
6. 禁用表达必须可被后续检测。

---

# 13. Agent 09：模板蒸馏 Agent

## 13.1 定位

把拆书结果抽象成可迁移写作模板。

它不写新故事，只提炼机制。

---

## 13.2 负责范围

1. 开局模板；
2. 章节节奏模板；
3. 冲突升级模板；
4. 爽点模板；
5. 悬念模板；
6. 人物关系模板；
7. 对白模板；
8. 场景切入模板；
9. 结尾钩子模板；
10. 风格迁移规则；
11. 禁止复制元素列表；
12. 适用题材和不适用题材。

---

## 13.3 禁止事项

1. 不复制原书具体剧情；
2. 不复制原书专有名词；
3. 不复制原书人物关系到不可区分；
4. 不生成正文；
5. 不输出“照着写”式模板；
6. 不把角色名替换后当原创模板。

---

## 13.4 输入

```text
books/{book_id}/analysis/overview/book_overview.json
books/{book_id}/analysis/plot/*.json
books/{book_id}/analysis/commercial/*.json
books/{book_id}/analysis/characters/*.json
books/{book_id}/analysis/foreshadowing/*.json
books/{book_id}/analysis/style/*.json
```

---

## 13.5 可调用 Skill 集

```text
template_distiller.skill
```

蒸馏模板。

```text
mechanism_abstraction.skill
```

把具体剧情抽象为机制。

```text
pattern_generalizer.skill
```

泛化适用条件。

```text
copy_risk_detector.skill
```

检测模板是否过度贴近原书。

```text
structure_transfer_mapper.skill
```

将结构机制映射到新题材。

---

## 13.6 输出产物

### Markdown

```text
books/{book_id}/analysis/templates/transfer_templates.md
books/{book_id}/analysis/templates/opening_templates.md
books/{book_id}/analysis/templates/dialogue_templates.md
```

### JSON

```text
books/{book_id}/analysis/templates/transfer_templates.json
books/{book_id}/analysis/templates/chapter_templates.json
books/{book_id}/analysis/templates/hook_templates.json
books/{book_id}/analysis/templates/dialogue_templates.json
```

---

## 13.7 transfer_templates.json 结构

```json
{
  "book_id": "book_001",
  "templates": [
    {
      "template_id": "tpl_opening_001",
      "type": "opening",
      "name": "",
      "source_mechanism": "",
      "abstract_pattern": "",
      "applicable_genres": [],
      "required_conditions": [],
      "forbidden_copy_elements": [],
      "example_usage_instruction": ""
    }
  ]
}
```

---

## 13.8 质量标准

1. 模板必须抽象到机制层；
2. 每个模板必须列出禁止复制元素；
3. 每个模板必须说明适用条件；
4. 每个模板必须说明不适用情况；
5. 模板必须能被 Skill 编译 Agent 读取；
6. 模板不能含有原文大段句子。

---

# 14. Agent 10：Skill 编译 Agent

## 14.1 定位

把拆书结果编译成可被其他 Agent 调用的 `.skill` 包。

它是拆书主链的最终产物生成者。

---

## 14.2 负责范围

1. 汇总拆书产物；
2. 删除不适合暴露给写作 Agent 的内容；
3. 转换成 Skill 结构；
4. 写入 Skill Manifest；
5. 定义调用方式；
6. 定义输入参数；
7. 定义输出约束；
8. 定义禁止复制规则；
9. 生成使用示例；
10. 生成版本号；
11. 生成 Skill README。

---

## 14.3 禁止事项

1. 不把原文大段塞入 Skill；
2. 不把具体剧情复制成模板；
3. 不保留高风险专有表达；
4. 不生成实验正文；
5. 不修改原始分析产物；
6. 不跳过复制风险过滤。

---

## 14.4 输入

```text
books/{book_id}/analysis/overview/
books/{book_id}/analysis/plot/
books/{book_id}/analysis/commercial/
books/{book_id}/analysis/characters/
books/{book_id}/analysis/foreshadowing/
books/{book_id}/analysis/style/
books/{book_id}/analysis/templates/
```

---

## 14.5 可调用 Skill 集

```text
skill_manifest_builder.skill
```

构建 `skill_manifest.json`。

```text
skill_packager.skill
```

生成 Skill 目录和文件。

```text
copy_risk_filter.skill
```

过滤过度接近原书的内容。

```text
usage_instruction_generator.skill
```

生成 Skill 使用说明。

```text
schema_validator.skill
```

检查 Skill 包字段完整性。

```text
skill_versioner.skill
```

管理 Skill 版本号。

---

## 14.6 输出产物

```text
books/{book_id}/compiled_skill/book_001.skill/skill_manifest.json
books/{book_id}/compiled_skill/book_001.skill/README.md
books/{book_id}/compiled_skill/book_001.skill/style_guide.md
books/{book_id}/compiled_skill/book_001.skill/structure_patterns.md
books/{book_id}/compiled_skill/book_001.skill/commercial_patterns.md
books/{book_id}/compiled_skill/book_001.skill/character_patterns.md
books/{book_id}/compiled_skill/book_001.skill/foreshadow_patterns.md
books/{book_id}/compiled_skill/book_001.skill/chapter_rhythm.json
books/{book_id}/compiled_skill/book_001.skill/character_voice_patterns.json
books/{book_id}/compiled_skill/book_001.skill/scene_style_patterns.json
books/{book_id}/compiled_skill/book_001.skill/writing_constraints.json
books/{book_id}/compiled_skill/book_001.skill/forbidden_copy_rules.md
books/{book_id}/compiled_skill/book_001.skill/usage_examples.md
```

---

## 14.7 skill_manifest.json 结构

```json
{
  "skill_id": "book_001_style_structure_skill",
  "skill_name": "某书拆解写作 Skill",
  "version": "0.1.0",
  "source_book_id": "book_001",
  "skill_type": [
    "style_transfer",
    "structure_transfer",
    "commercial_pattern_transfer"
  ],
  "allowed_use": [
    "原创文本实验",
    "结构迁移",
    "风格约束",
    "章节节奏参考"
  ],
  "forbidden_use": [
    "复刻原书剧情",
    "复刻原书人物",
    "复刻原书专有名词",
    "大段模仿原文句式"
  ],
  "entry_files": {
    "style": "style_guide.md",
    "structure": "structure_patterns.md",
    "commercial": "commercial_patterns.md",
    "constraints": "writing_constraints.json"
  },
  "compile_sources": [],
  "copy_risk_status": "passed"
}
```

---

## 14.8 writing_constraints.json 结构

```json
{
  "global_constraints": [],
  "style_constraints": [],
  "structure_constraints": [],
  "dialogue_constraints": [],
  "scene_constraints": [],
  "commercial_constraints": [],
  "forbidden_copy_constraints": []
}
```

---

## 14.9 质量标准

1. Skill 包必须可独立调用；
2. Skill 包不得依赖原文 raw.txt；
3. Skill 包不得包含大段原文；
4. Skill 包必须说明允许用途和禁止用途；
5. Skill 包必须有版本号；
6. Skill 包必须通过拆书质检 Agent 检查。

---

# 15. Agent 11：拆书质检 Agent

## 15.1 定位

检查拆书结果是否完整、结构是否一致、是否可以安全编译和调用。

它只检查拆书主链，不检查实验写作结果。

---

## 15.2 负责范围

1. 检查章节是否遗漏；
2. 检查每章 `md/json` 是否成对；
3. 检查人物索引与人物文件是否一致；
4. 检查伏笔索引与伏笔文件是否一致；
5. 检查全书总览是否引用关键分析；
6. 检查风格指纹是否有足够统计样本；
7. 检查模板是否存在复制风险；
8. 检查 Skill 包字段完整性；
9. 检查 JSON Schema；
10. 输出 blocker、warning、info。

---

## 15.3 禁止事项

1. 不生成新分析；
2. 不修改原文；
3. 不生成实验文本；
4. 不直接修复 Skill，除非被授权；
5. 不把 warning 当 blocker；
6. 不放过 blocker。

---

## 15.4 输入

```text
books/{book_id}/meta/analysis_manifest.json
books/{book_id}/analysis/**/*.json
books/{book_id}/analysis/**/*.md
books/{book_id}/compiled_skill/book_001.skill/
```

---

## 15.5 可调用 Skill 集

```text
analysis_completeness_checker.skill
```

检查产物是否缺失。

```text
schema_validator.skill
```

检查 JSON Schema。

```text
cross_reference_checker.skill
```

检查索引和实际文件是否一致。

```text
copy_risk_detector.skill
```

检查模板和 Skill 是否存在照搬风险。

```text
sample_size_checker.skill
```

检查风格样本是否足够。

```text
quality_gate_evaluator.skill
```

根据规则输出 pass / fail / pass_with_warnings。

---

## 15.6 输出产物

### Markdown

```text
books/{book_id}/analysis/qa/analysis_quality_report.md
```

### JSON

```text
books/{book_id}/analysis/qa/analysis_quality_report.json
books/{book_id}/analysis/qa/missing_items.json
books/{book_id}/meta/quality_report.json
```

---

## 15.7 quality_report.json 结构

```json
{
  "book_id": "book_001",
  "status": "pass_with_warnings",
  "blockers": [],
  "warnings": [],
  "infos": [],
  "skill_compile_ready": true,
  "experiment_ready": true,
  "checked_files": [],
  "missing_files": [],
  "schema_errors": [],
  "copy_risk_findings": []
}
```

---

## 15.8 blocker 规则

出现以下情况，必须阻止 Skill 正式可用：

1. 章节缺失；
2. 大量章节没有 JSON；
3. 全书总览缺失；
4. 风格指纹缺失；
5. Skill Manifest 缺失；
6. Skill 内包含大段原文；
7. 复制风险过高；
8. JSON Schema 无法解析；
9. 关键索引文件与实际文件不一致。

---

## 15.9 warning 规则

以下问题可进入 warning：

1. 少数章节置信度低；
2. 次要人物缺少独立文件；
3. 部分伏笔置信度低；
4. 商业机制分析不够细；
5. 模板适用范围未充分说明；
6. 风格样本偏少但仍可用。

---

# 16. 主链执行顺序

推荐默认顺序：

```text
00 拆书总控 Agent
→ 01 文本清洗 Agent
→ 02 章节内容 Agent
→ 03 全书总览 Agent
→ 04 情节结构 Agent
→ 05 商业机制 Agent
→ 06 人物关系 Agent
→ 07 伏笔悬念 Agent
→ 08 文风指纹 Agent
→ 09 模板蒸馏 Agent
→ 10 Skill 编译 Agent
→ 11 拆书质检 Agent
```

可并行项：

```text
章节内容完成后：
04 情节结构 Agent
05 商业机制 Agent
06 人物关系 Agent
07 伏笔悬念 Agent
08 文风指纹 Agent
可部分并行执行。
```

必须串行项：

```text
01 文本清洗必须先于所有分析 Agent
02 章节内容必须先于全书级汇总
09 模板蒸馏必须晚于核心分析产物
10 Skill 编译必须晚于模板蒸馏
11 拆书质检必须在 Skill 编译后执行
```

---

# 17. Skill 缺失时的处理原则

当某个 Agent 需要调用 Skill，但项目中不存在该 Skill 时：

1. 不允许跳过；
2. 不允许临时写死在 Agent Prompt 里；
3. 必须创建对应 Skill 目录；
4. 必须写明 Skill 的输入、输出、边界、失败处理；
5. Skill 的实现可以先是最小版本，但接口必须稳定。

Skill 目录标准：

```text
skills/{skill_name}.skill/
├── SKILL.md
├── README.md
├── schema/
│   ├── input.schema.json
│   └── output.schema.json
└── tests/
    └── examples.md
```

---

# 18. 拆书主链最终验收标准

一套拆书任务完成后，必须满足：

1. `source/chapters/index.json` 存在；
2. 每章有独立 txt；
3. 每章有独立 `md + json` 拆解；
4. 全书总览存在；
5. 情节结构产物存在；
6. 商业机制产物存在；
7. 人物索引和核心人物文件存在；
8. 伏笔索引和重要伏笔文件存在；
9. 全局文风指纹存在；
10. 角色声纹和场景声纹至少有初版；
11. 可迁移模板存在；
12. `.skill` 包存在；
13. `skill_manifest.json` 存在；
14. 复制风险检查通过；
15. 拆书质检无 blocker。

---

# 19. 第一阶段优先级建议

如果开发时需要分批实现，建议：

## 第一批

```text
00 拆书总控 Agent
01 文本清洗 Agent
02 章节内容 Agent
03 全书总览 Agent
08 文风指纹 Agent
10 Skill 编译 Agent
11 拆书质检 Agent
```

目标：先跑通“输入小说 → 拆章节 → 全书总览 → 文风指纹 → 编译 Skill → 质检”的闭环。

## 第二批

```text
04 情节结构 Agent
05 商业机制 Agent
06 人物关系 Agent
07 伏笔悬念 Agent
09 模板蒸馏 Agent
```

目标：补齐可迁移性和商业结构分析。

---

# 20. 关键结论

拆书链的最终产品不是一堆读书笔记，而是：

```text
可检索的结构化分析资产
+ 可读的人工复核报告
+ 可调用的写作 Skill 包
```

正确拆分是：

```text
拆书主链：只负责分析和 Skill 编译
实验写作链：独立调用 Skill 写测试文本
验证链：独立评估 Skill 是否生效
```

拆书主链不写新文本。  
它的终点是 `.skill`。
