# 拆书流程逻辑规格

版本：v0.1  
适用范围：拆书主链 Agent 流程，不包含实验写作链与验证链。  
目标：明确拆书顺序、并行关系、前置依赖、阶段门禁和产物流转规则。

---

## 1. 核心原则

拆书流程不是简单线性流程，而是：

> **阶段门禁 + 并行分支 + 汇总编译**

核心执行原则：

1. **客观内容先行**：先清洗、分章、做每章事实拆解。
2. **章节级并行**：每章内容拆解、章节风格统计可以并行。
3. **全书级等待**：情节结构、人物关系、伏笔、商业机制、全书总览必须等待足够章节资产完成。
4. **抽象模板最后**：模板蒸馏和 Skill 编译必须在多维拆解完成后执行。
5. **质检最后兜底**：所有产物完成后再统一检查完整性、引用关系和复制风险。

---

## 2. 总流程顺序

```text
0. 建书任务初始化
        ↓
1. 文本清洗 / 分章
        ↓
2. 每章内容拆解 + 每章风格初拆
        ↓
3. 基础索引归一化
        ↓
4. 多维拆解并行
        ↓
5. 全书级汇总
        ↓
6. 模板蒸馏
        ↓
7. Skill 编译
        ↓
8. 拆书质检
```

最终产物不是实验正文，而是：

```text
compiled_skill/book_001.skill/
```

---

## 3. 完整流程 DAG

```text
[00 拆书总控 Agent]
        ↓
[01 文本清洗 Agent]
        ↓
 ┌───────────────────────────────┐
 │ source/chapters/*.txt 已生成   │
 └───────────────────────────────┘
        ↓
 ┌───────────────并行───────────────┐
 ↓                                  ↓
[02 每章内容 Agent]          [08 文风指纹 Agent - 章节统计]
 ↓                                  ↓
[章节内容 index]             [章节风格 index]
        ↓
[基础索引归一化 / 实体对齐]
        ↓
 ┌───────────────并行拆解───────────────┐
 ↓              ↓              ↓        ↓
[04 情节结构]  [06 人物关系]  [07 伏笔悬念初拆] [08 全局文风]
 ↓              ↓              ↓        ↓
[章节功能图]   [人物索引]      [伏笔候选]    [全局风格]
 ↓              ↓              ↓        ↓
 ↓              └────→ [08 角色声纹]     ↓
 ↓                                     ↓
 └────→ [05 商业机制] ←─────────────────┘
        ↓
[03 全书总览 Agent - 最终版]
        ↓
[09 模板蒸馏 Agent]
        ↓
[10 Skill 编译 Agent]
        ↓
[11 拆书质检 Agent]
```

---

## 4. Agent 执行依赖表

| 阶段 | Agent | 是否可并行 | 硬前置 | 主要输出 |
|---|---|---:|---|---|
| 0 | 00 拆书总控 Agent | 否 | 用户任务、原文文件 | `analysis_manifest.json` |
| 1 | 01 文本清洗 Agent | 否 | `raw.txt` | `cleaned.txt`、章节文件 |
| 2A | 02 章节内容 Agent | 是，按章节并行 | 分章完成 | 每章 `chXXX.md/json` |
| 2B | 08 文风指纹 Agent：章节统计 | 是，按章节并行 | 分章完成 | 每章 `chXXX_style.json` |
| 3 | 基础索引归一化 | 否 | 章节内容拆解完成 | 实体、事件、地点索引 |
| 4A | 04 情节结构 Agent | 是 | 章节内容完成 | 情节弧、章节功能图 |
| 4B | 06 人物关系 Agent | 是 | 章节内容完成 | 人物索引、关系图 |
| 4C | 07 伏笔悬念 Agent：初拆 | 是 | 章节内容完成 | 伏笔候选 |
| 4D | 08 文风指纹 Agent：全局文风 | 是 | 章节风格统计完成 | 全局风格指纹 |
| 5A | 05 商业机制 Agent | 是 | 情节结构完成 | 商业机制、爽点图 |
| 5B | 08 文风指纹 Agent：角色声纹 | 是 | 人物关系完成 | 角色声纹 |
| 5C | 08 文风指纹 Agent：场景声纹 | 是 | 情节结构 + 章节风格 | 场景风格 |
| 5D | 07 伏笔悬念 Agent：复核 | 是 | 情节结构 + 人物关系 | 伏笔生命周期 |
| 6 | 03 全书总览 Agent | 否 | 多维拆解完成 | 全书总览 |
| 7 | 09 模板蒸馏 Agent | 否 | 全书总览 + 多维拆解 | 可迁移模板 |
| 8 | 10 Skill 编译 Agent | 否 | 模板蒸馏完成 | `.skill` 包 |
| 9 | 11 拆书质检 Agent | 否 | Skill 编译完成 | 质检报告 |

---

## 5. 必须等待前置完成的流程

### 5.1 文本清洗是所有流程硬前置

必须等以下产物完成：

```text
source/cleaned.txt
source/chapters/index.json
source/chapters/ch001.txt
source/chapters/ch002.txt
...
meta/source_manifest.json
```

没有稳定分章，后续 Agent 不允许正式运行。

---

### 5.2 每章内容拆解必须等分章完成

`02 章节内容 Agent` 的输入是单章文本。

可并行运行：

```text
ch001
ch002
ch003
...
```

但必须等全部章节拆解完成后，才能进入全书级分析。

---

### 5.3 情节结构必须等章节内容完成

`04 情节结构 Agent` 依赖：

```text
每章摘要
每章事件
每章冲突
每章信息增量
每章结尾钩子
```

所以它不能早于 `02 章节内容 Agent`。

---

### 5.4 商业机制最好等情节结构完成

商业机制要判断：

```text
爽点在哪里
付费点在哪里
冲突怎么升级
读者期待如何建立
章节钩子如何分布
```

这些依赖 `chapter_function_map.json`。

推荐依赖链：

```text
02 章节内容
    ↓
04 情节结构
    ↓
05 商业机制
```

---

### 5.5 角色声纹必须等人物索引完成

文风 Agent 可以先做：

```text
全局风格
章节风格
句长统计
段落统计
对白比例
```

但角色声纹必须等：

```text
06 人物关系 Agent
```

产出：

```text
analysis/characters/index.json
analysis/characters/char_001.json
analysis/characters/char_002.json
...
```

否则无法稳定识别人物对白归属。

---

### 5.6 模板蒸馏必须等所有核心拆解完成

`09 模板蒸馏 Agent` 的输入是综合结果：

```text
全书总览
情节结构
商业机制
人物关系
伏笔悬念
文风指纹
```

所以它必须在多维拆解之后执行。

---

### 5.7 Skill 编译必须等模板蒸馏完成

Skill 不是原始分析的简单打包，而是：

```text
分析结果
    ↓
可调用写作规则
    ↓
xxx.skill
```

因此必须等：

```text
09 模板蒸馏 Agent
```

---

### 5.8 拆书质检必须最后执行

质检需要检查：

```text
分析文件是否完整
JSON 是否符合 schema
索引是否对齐
Skill 是否可调用
是否有复制风险
是否缺少关键维度
```

所以最后执行。

---

## 6. 可以同步执行的流程

### 6.1 第一批并行：章节级任务

前置：

```text
01 文本清洗 Agent 完成
```

可并行：

```text
02 章节内容 Agent：ch001 / ch002 / ch003 ...
08 文风指纹 Agent：每章基础统计
```

包含：

```text
每章内容拆解
每章句长统计
每章段落统计
每章对白比例
每章叙述比例
每章场景切分初判
```

---

### 6.2 第二批并行：全书拆解维度

前置：

```text
所有章节内容拆解完成
基础索引归一化完成
```

可并行：

```text
04 情节结构 Agent
06 人物关系 Agent
07 伏笔悬念 Agent 初拆
08 文风指纹 Agent 全局风格
```

说明：

- 情节结构看章节功能；
- 人物关系看人物出场与事件；
- 伏笔悬念看异常信息与后续回收；
- 文风指纹看原文统计和章节风格。

---

### 6.3 第三批并行：依赖分支任务

前置依赖完成后，可继续并行：

```text
05 商业机制 Agent
08 角色声纹 Agent
08 场景声纹 Agent
07 伏笔悬念 Agent 复核
```

依赖关系：

```text
05 商业机制 ← 04 情节结构
08 角色声纹 ← 06 人物关系
08 场景声纹 ← 04 情节结构 + 08 章节风格
07 伏笔复核 ← 04 情节结构 + 06 人物关系
```

---

## 7. 阶段门禁设计

### Gate 0：任务初始化通过

必须有：

```text
meta/book_info.json
source/raw.txt
用户指定拆书目标
输出目录
```

检查项：

```text
书籍 ID 唯一
原文文件存在
输出目录可写
拆书模式已指定
```

未通过则不启动。

---

### Gate 1：文本清洗通过

必须有：

```text
source/cleaned.txt
source/chapters/index.json
source/chapters/ch001.txt
source/chapters/ch002.txt
...
meta/source_manifest.json
```

检查项：

```text
章节编号连续
章节数量合理
空章节比例为 0
重复章节低于阈值
正文没有明显广告噪声
章节标题可追踪
```

未通过则不进入章节拆解。

---

### Gate 2：章节内容拆解通过

必须有：

```text
analysis/chapters/index.md
analysis/chapters/index.json
analysis/chapters/ch001.md
analysis/chapters/ch001.json
analysis/chapters/ch002.md
analysis/chapters/ch002.json
...
```

检查项：

```text
每章都有一句话摘要
每章都有详细摘要
每章都有关键事件
每章都有出场人物
每章都有信息增量
每章都有状态变化或明确标记无变化
不确定项已标记
```

未通过则不进入全书级拆解。

---

### Gate 3：基础索引归一化通过

这是独立阶段，建议必须存在。

处理内容：

```text
人物别名合并
地点名称合并
组织名称合并
道具名称合并
事件 ID 生成
章节 ID 对齐
术语别名映射
```

产物：

```text
analysis/indexes/entity_index.json
analysis/indexes/event_index.json
analysis/indexes/location_index.json
analysis/indexes/organization_index.json
analysis/indexes/item_index.json
analysis/indexes/term_alias_map.json
```

检查项：

```text
主要人物 ID 稳定
主要地点 ID 稳定
主要事件 ID 稳定
别名能追溯来源章节
不存在大量重复实体
```

未通过则不进入多维拆解。

---

### Gate 4：多维拆解通过

必须有：

```text
analysis/plot/global_plot_arc.json
analysis/plot/chapter_function_map.json
analysis/commercial/commercial_mechanics.json
analysis/characters/index.json
analysis/characters/character_network.json
analysis/foreshadowing/foreshadow_map.json
analysis/style/style_fingerprint_global.json
analysis/style/style_guide.md
```

检查项：

```text
人物索引能对应章节出场
伏笔节点能对应章节
情节节点能对应章节
风格统计样本足够
商业机制不是空泛总结
章节功能分类覆盖率足够
```

---

### Gate 5：全书总览通过

产物：

```text
analysis/overview/book_overview.md
analysis/overview/book_overview.json
```

检查项：

```text
不是逐章复述
能总结核心卖点
能总结故事结构
能总结人物结构
能总结风格特征
能总结可迁移机制
能标记不可迁移内容
```

---

### Gate 6：模板蒸馏通过

产物：

```text
analysis/templates/transfer_templates.md
analysis/templates/transfer_templates.json
analysis/templates/chapter_templates.json
analysis/templates/dialogue_templates.json
analysis/templates/hook_templates.json
```

检查项：

```text
模板足够抽象
没有复制原书设定
没有复制原书人物
没有复制原书专有名词
没有大段复刻原文表达
能被写作 Agent 调用
```

---

### Gate 7：Skill 编译通过

产物目录：

```text
compiled_skill/book_001.skill/
```

必须包含：

```text
skill_manifest.json
README.md
style_guide.md
structure_patterns.md
commercial_patterns.md
character_patterns.md
foreshadow_patterns.md
chapter_rhythm.json
character_voice_patterns.json
scene_style_patterns.json
writing_constraints.json
forbidden_copy_rules.md
usage_examples.md
```

检查项：

```text
manifest 字段完整
入口文件存在
Skill 可被写作 Agent 调用
禁止复制规则明确
没有原文大段内容
没有高风险专有表达
版本号存在
```

---

### Gate 8：拆书质检通过

产物：

```text
analysis/qa/analysis_quality_report.md
analysis/qa/analysis_quality_report.json
meta/quality_report.json
```

结论只能是：

```text
pass
pass_with_warnings
fail
```

规则：

```text
pass：允许进入实验写作
pass_with_warnings：允许进入实验写作，但必须记录风险
fail：禁止进入实验写作
```

---

## 8. 标准执行顺序

```text
00 拆书总控
↓
01 文本清洗
↓
02 章节内容拆解，按章节并行
+
08 章节风格统计，按章节并行
↓
基础索引归一化
↓
04 情节结构
06 人物关系
07 伏笔悬念初拆
08 全局文风
并行
↓
05 商业机制
08 角色声纹 / 场景声纹
07 伏笔悬念复核
并行
↓
03 全书总览最终版
↓
09 模板蒸馏
↓
10 Skill 编译
↓
11 拆书质检
```

---

## 9. 特殊流程规则

### 9.1 全书总览不要过早最终化

建议全书总览分两版：

```text
book_overview_draft.json
book_overview_final.json
```

推荐流程：

```text
章节内容完成后 → 生成初版全书总览
所有维度拆完后 → 生成最终全书总览
```

原因：

- 章节内容完成后可以快速形成全局认知；
- 但商业机制、文风、人物关系、伏笔复核未完成时，全书总览不够准确；
- 最终版必须整合所有维度。

---

### 9.2 文风 Agent 分三段跑

不要一次跑完。

```text
第一段：章节风格统计
第二段：全局风格汇总
第三段：角色声纹 / 场景声纹
```

原因：

- 章节风格只依赖原文；
- 全局风格依赖章节统计；
- 角色声纹依赖人物索引；
- 场景声纹依赖情节结构和章节场景分类。

---

### 9.3 伏笔 Agent 分两段跑

推荐：

```text
第一段：从章节中找伏笔候选
第二段：结合情节结构和人物关系做生命周期复核
```

原因：

- 第一遍容易把普通细节误判成伏笔；
- 第二遍可以通过后续回收、误导、强化节点判断是否是真伏笔；
- 伏笔生命周期必须依赖全书视角。

---

### 9.4 商业机制不能早于情节结构

否则容易输出空泛评价：

```text
节奏紧凑
爽点明显
悬念强
人物鲜明
```

商业机制必须依赖：

```text
chapter_function_map.json
rhythm_curve.json
hook_map.json
payoff_map.json
```

---

### 9.5 Skill 编译前必须做复制风险过滤

尤其是拆高辨识度作品时，Skill 中只能保留：

```text
结构机制
节奏规律
风格规则
商业机制
对白倾向
场景写法
抽象模板
```

不能保留：

```text
原书专有名词
原书标志性设定
原书角色关系原型
大段原文句式
高度可识别桥段
```

---

## 10. 失败处理规则

### 10.1 文本清洗失败

处理方式：

```text
1. 标记 source_manifest.json 为 failed
2. 输出失败原因
3. 保留 raw.txt
4. 不进入后续流程
```

常见原因：

```text
无法识别章节
章节过少
乱码严重
重复率过高
正文缺失
```

---

### 10.2 单章拆解失败

处理方式：

```text
1. 标记该章节 chXXX.json 为 failed
2. 允许重跑该章节
3. 不影响其他章节并行
4. 但 Gate 2 不通过
```

---

### 10.3 多维拆解失败

处理方式：

```text
1. 标记对应维度失败
2. 允许该维度重跑
3. 不删除其他维度产物
4. 不进入模板蒸馏
```

---

### 10.4 Skill 编译失败

处理方式：

```text
1. 保留全部分析产物
2. 输出 skill_compile_error.json
3. 不进入实验写作
4. 允许修改模板或复制风险规则后重编译
```

---

### 10.5 质检失败

处理方式：

```text
1. quality_report.json 标记 fail
2. 禁止进入实验写作
3. 输出 blocker 清单
4. 修复后重新质检
```

---

## 11. 产物依赖关系

```text
source/raw.txt
    ↓
source/cleaned.txt
    ↓
source/chapters/*.txt
    ↓
analysis/chapters/*.json
    ↓
analysis/indexes/*.json
    ↓
analysis/plot/*.json
analysis/characters/*.json
analysis/foreshadowing/*.json
analysis/style/*.json
    ↓
analysis/commercial/*.json
    ↓
analysis/overview/book_overview.json
    ↓
analysis/templates/*.json
    ↓
compiled_skill/book_001.skill/
    ↓
analysis/qa/analysis_quality_report.json
```

---

## 12. 推荐任务调度策略

### 12.1 小书

适合：

```text
10 万字以内
50 章以内
```

策略：

```text
章节内容拆解全并行
章节风格统计全并行
全书级 Agent 一次性运行
```

---

### 12.2 中长篇

适合：

```text
10 万 - 100 万字
50 - 500 章
```

策略：

```text
按卷 / 每 50 章为 batch
batch 内章节并行
每个 batch 生成局部索引
全书级 Agent 读取 batch 汇总
```

---

### 12.3 超长篇

适合：

```text
100 万字以上
500 章以上
```

策略：

```text
先按卷拆
每卷独立产物
再做全书级汇总
伏笔和人物关系必须分层索引
文风指纹需要抽样 + 重点章节全量分析
```

超长篇不建议一次性全量塞给 LLM。

---

## 13. 最终定义

拆书流程的正确形态是：

> **先把原书拆成稳定章节资产，再并行提取结构、人物、伏笔、文风和商业机制，最后汇总为全书总览与可调用 Skill。**

最重要的执行原则是：

> **章节级并行，全书级等待；客观事实先行，抽象模板最后。**
