import type { AgentId, ArtifactKind } from "./schemas";

export interface AgentSpec {
  readonly id: AgentId;
  readonly name: string;
  readonly title: string;
  readonly inputs: ReadonlyArray<ArtifactKind>;
  readonly outputs: ReadonlyArray<ArtifactKind>;
  readonly responsibilities: ReadonlyArray<string>;
  readonly humanizerMode?: "check" | "generate" | "revise";
}

export const agentSpecs: ReadonlyArray<AgentSpec> = [
  {
    id: "coordinator",
    name: "Agent1",
    title: "协调-总导演",
    inputs: ["project_brief", "project_state"],
    outputs: ["run_plan"],
    responsibilities: ["编排全局流程", "决定调用顺序", "处理失败重试", "设置审批点"],
  },
  {
    id: "marketAnalyst",
    name: "Agent2",
    title: "市场研究-市场分析",
    inputs: ["project_brief"],
    outputs: ["market_report", "genre_rules"],
    responsibilities: ["题材定位", "爽点", "竞品", "禁区", "卖点"],
  },
  {
    id: "characterDesigner",
    name: "Agent3",
    title: "人物设计-角色设计",
    inputs: ["market_report", "genre_rules"],
    outputs: ["characters", "character_matrix"],
    responsibilities: ["主角", "配角", "反派", "人物弧", "关系网"],
    humanizerMode: "check",
  },
  {
    id: "outlineArchitect",
    name: "Agent4",
    title: "大纲设计-大纲架构",
    inputs: ["characters", "character_matrix", "genre_rules"],
    outputs: ["volume_outline", "arc_plan"],
    responsibilities: ["卷纲", "主线", "阶段目标", "钩子回收"],
    humanizerMode: "check",
  },
  {
    id: "plotPlanner",
    name: "Agent5",
    title: "情节扩展-情节策划",
    inputs: ["volume_outline", "arc_plan", "project_state"],
    outputs: ["chapter_intent", "scene_cards", "context_package", "rule_stack"],
    responsibilities: ["单章目标", "场景卡", "冲突", "节奏", "悬念"],
    humanizerMode: "check",
  },
  {
    id: "leadWriter",
    name: "Agent6",
    title: "写作-主笔",
    inputs: ["chapter_intent", "scene_cards", "context_package", "rule_stack"],
    outputs: ["chapter_draft", "state_delta"],
    responsibilities: ["正文", "对白", "动作", "情绪", "节奏"],
    humanizerMode: "generate",
  },
  {
    id: "editor",
    name: "Agent7",
    title: "修订-责编",
    inputs: ["chapter_draft", "audit_report", "project_state"],
    outputs: ["audit_report", "chapter_final"],
    responsibilities: ["连贯性", "爽点", "节奏", "去 AI 味", "修订"],
    humanizerMode: "revise",
  },
  {
    id: "actor",
    name: "Agent8",
    title: "演员-角色代入",
    inputs: ["characters", "character_matrix", "chapter_intent", "scene_cards"],
    outputs: ["chapter_draft", "state_delta"],
    responsibilities: ["角色口吻", "即兴对白", "动作反应", "情绪外化", "关系张力"],
    humanizerMode: "generate",
  },
];

export const agentById = Object.fromEntries(agentSpecs.map((agent) => [agent.id, agent])) as Record<AgentId, AgentSpec>;
