import { useMemo, useState, type CSSProperties, type PointerEvent as ReactPointerEvent } from "react";
import {
  BookOpen,
  Bot,
  Check,
  FileText,
  GitBranch,
  LayoutDashboard,
  MessageSquare,
  PenLine,
  Plus,
  Settings,
  Upload,
  UserCheck,
} from "lucide-react";
import { agentSpecs, type AgentSpec } from "./core/agents";
import { BrowserArtifactStore } from "./core/artifact-store";
import { PipelineOrchestrator, type ExportBundlePayload, type PipelineRunSnapshot } from "./core/orchestrator";
import type { AgentId } from "./core/schemas";

type WorkType = "原创" | "同人" | "二创" | "资料";
type ModuleGroup = "系统" | "创作" | "设定" | "AI";
type SettingsTab = "general" | "appearance" | "editor" | "assistant" | "provider" | "model" | "dream" | "usage" | "storage" | "about";
type StyleMode = "warm" | "clean" | "night";
type PaneKey = "rail" | "module" | "workspace" | "agent";
type PaneWidths = Record<PaneKey, number>;
type StateUpdate<T> = T | ((value: T) => T);
type BaseUrlPreset = { name: string; url: string };
type DreamSettings = {
  enabled: boolean;
  intervalHours: number;
  modelAgentId: AgentId;
  lastRun: string;
  lastSummary: string;
};
type AgentModelSetting = {
  apiKey: string;
  baseUrl: string;
  models: string[];
  defaultModel: string;
  status: "idle" | "loading" | "ready" | "error";
  error: string;
};
type WorkForm = {
  id: string;
  title: string;
  coverUrl: string;
  intro: string;
  category: string;
  type: WorkType;
  tags: string[];
};
type WorkspaceModule = {
  id: string;
  group: ModuleGroup;
  label: string;
  description: string;
  icon: typeof BookOpen;
  actions: string[];
  agentIds: AgentId[];
  records: Array<{ title: string; meta: string; body: string }>;
};
type AgentMessage = { moduleId: string; agentId: AgentId; role: "user" | "assistant"; text: string };
type ChatRequestMessage = { role: "system" | "user" | "assistant"; content: string };
type RoundtableReply = { agentId: AgentId; title: string; text: string };
type RoundtableRound = { id: string; topic: string; replies: RoundtableReply[] };
type SkitRound = { id: string; scene: string; roles: string; replies: RoundtableReply[] };
type OutlineTask = { id: string; title: string; detail: string; done: boolean };
type OutlineBeat = { volume: string; beat: string; title: string; words: string; tone: string; summary?: string };
type RoleplayMessage = { role: "user" | "character"; text: string };
type AvatarStyle = "movie" | "anime" | "fantasy" | "photo" | "custom";
type CharacterEditorTab = "bio" | "status";
type ChapterDraft = { id: string; title: string; status: string; outline: string; outlineApproved: boolean; content: string; wordCount: number };
type ChapterTask = { id: string; title: string; detail: string; status: "done" | "running" | "pending" };
type EntityRelation = { id: string; source: string; relation: string; target: string; note: string };
type ConversationOption = { label: string; detail: string; onSelect: () => void; disabled?: boolean };
type AssistantTask = {
  title: string;
  detail: string;
  status: "running" | "done" | "error";
  thinking: string;
  result: string;
  steps: Array<{ title: string; status: "done" | "running" | "pending" }>;
};
type CharacterProfile = {
  id: string;
  name: string;
  role: string;
  gender: string;
  firstChapter: string;
  bio: string;
  status: string;
  avatarUrl: string;
  gallery: string[];
};
type WorkData = {
  moduleRecords: Record<string, WorkspaceModule["records"]>;
  chapters: ChapterDraft[];
  characters: CharacterProfile[];
  relations: EntityRelation[];
  outlineBeats: OutlineBeat[];
};

const defaultWork: WorkForm = {
  id: "default-work",
  title: "重生之我用 AI 写小说",
  coverUrl: "",
  intro: "女主前世被宗门当作炉鼎牺牲，重生后用账本、契约和人心裂缝反杀。",
  category: "玄幻",
  type: "原创",
  tags: ["重生", "复仇", "宗门"],
};
const worksStorageKey = "ai-novel-factory.works";
const workDataStorageKey = "ai-novel-factory.workDataById";

function loadStored<T>(key: string, fallback: T): T {
  try {
    const rawValue = window.localStorage.getItem(key);
    return rawValue ? JSON.parse(rawValue) as T : fallback;
  } catch {
    return fallback;
  }
}

function saveStored(key: string, value: unknown) {
  try {
    window.localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // ponytail: localStorage can fail in private mode; in-memory state still works.
  }
}

function loadWorks() {
  try {
    const rawValue = window.localStorage.getItem(worksStorageKey);
    if (rawValue) {
      const savedWorks = JSON.parse(rawValue) as WorkForm[];
      return Array.isArray(savedWorks) ? savedWorks : [defaultWork];
    }
  } catch {
    // ponytail: bad localStorage falls back to the demo work.
  }
  return [defaultWork];
}

function saveWorks(works: WorkForm[]) {
  saveStored(worksStorageKey, works);
}

function cloneModuleRecords(records: Record<string, WorkspaceModule["records"]>) {
  return Object.fromEntries(Object.entries(records).map(([key, value]) => [key, value.map((record) => ({ ...record }))])) as Record<string, WorkspaceModule["records"]>;
}

const modules: WorkspaceModule[] = [
  moduleDef("overview", "系统", "概览", LayoutDashboard, "作品状态、近期章节、下一步任务。", ["继续创作", "运行规划"], ["coordinator"], [
    { title: "当前目标", meta: "今日", body: "拆出下一章任务，确认主角反杀线和宗门账本线。" },
    { title: "作品标签", meta: "定位", body: "强钩子、快节奏、低解释。" },
  ]),
  moduleDef("relationship-graph", "系统", "实体关系图", GitBranch, "人物、势力、地点、物品和伏笔的关系视图。", ["新增关系", "检查断点"], ["characterDesigner", "outlineArchitect"], []),
  moduleDef("chapters", "创作", "章节", BookOpen, "正文、草稿、终稿和导出内容。", ["新建章节", "生成正文"], ["plotPlanner", "leadWriter", "editor"], [
    { title: "第 1 章 账本重启", meta: "草稿", body: "她醒在祭坛前，第一眼看见的不是仇人，是自己亲手写过的账。" },
    { title: "第 2 章 契约反噬", meta: "待写", body: "旧契约仍在，但漏洞第一次站到了她这边。" },
  ]),
  moduleDef("outline", "创作", "大纲", FileText, "卷纲、主线、阶段目标和钩子回收。", ["新增节点", "拆分章节"], ["outlineArchitect", "plotPlanner"], [
    { title: "第一卷：旧账新命", meta: "主线", body: "重生、藏账、试探宗门规则，完成第一次公开反杀。" },
  ]),
  moduleDef("characters", "创作", "人物", PenLine, "角色卡、人物弧、关系网和冲突动机。", ["新增人物", "检查动机"], ["characterDesigner", "editor"], [
    { title: "沈照微", meta: "主角", body: "前世被牺牲，今生用账本和契约反制宗门。" },
    { title: "玄衡长老", meta: "反派", body: "把规则当武器的人，最怕规则被重新解释。" },
  ]),
  moduleDef("hooks", "创作", "伏笔", GitBranch, "埋线、回收、误导和章节触发点。", ["新增伏笔", "标记回收"], ["outlineArchitect", "plotPlanner", "editor"], [
    { title: "缺页账本", meta: "未回收", body: "缺掉的三页指向真正的炉鼎名单。" },
  ]),
  moduleDef("world", "设定", "世界观设定", LayoutDashboard, "修行规则、社会秩序、宗门制度。", ["新增设定", "一致性检查"], ["marketAnalyst", "outlineArchitect", "editor"], [
    { title: "契约灵纹", meta: "规则", body: "只约束签名者，但见证人可触发反噬。" },
  ]),
  moduleDef("map", "设定", "地图", FileText, "地点、路线、场景空间和移动限制。", ["新增地点", "连接路线"], ["outlineArchitect", "plotPlanner"], []),
  moduleDef("forces", "设定", "势力", GitBranch, "宗门、家族、商会与暗线组织。", ["新增势力", "势力关系"], ["characterDesigner", "outlineArchitect"], []),
  moduleDef("creatures", "设定", "生物", PenLine, "灵兽、异种、禁物生命。", ["新增生物"], ["marketAnalyst", "plotPlanner"], []),
  moduleDef("items", "设定", "物品", BookOpen, "账本、契约、法器和关键道具。", ["新增物品", "绑定伏笔"], ["plotPlanner", "editor"], []),
  moduleDef("skills", "设定", "技能", Settings, "功法、能力限制和代价。", ["新增技能", "检查代价"], ["marketAnalyst", "editor"], []),
  moduleDef("materials", "设定", "素材", Upload, "参考片段、灵感、资料和禁用表达。", ["导入素材", "整理标签"], ["coordinator", "marketAnalyst"], []),
  moduleDef("chat", "AI", "聊天", MessageSquare, "和当前 Agent 对话，处理当前模块问题。", ["发送给 Agent"], ["coordinator"], []),
  moduleDef("roundtable", "AI", "圆桌会议", Bot, "多 Agent 对同一创作问题给出分歧意见。", ["发起圆桌"], ["coordinator", "characterDesigner", "outlineArchitect", "editor"], []),
  moduleDef("monologue", "AI", "独白", PenLine, "让角色用第一人称暴露动机和情绪。", ["生成独白"], ["characterDesigner", "leadWriter"], []),
  moduleDef("skit", "AI", "小剧场", BookOpen, "用短场景测试人物关系和对白张力。", ["生成小剧场"], ["characterDesigner", "actor", "leadWriter", "editor"], []),
  moduleDef("roleplay", "AI", "角色扮演", MessageSquare, "以角色身份问答，校准口吻。", ["开始扮演"], ["actor", "characterDesigner", "leadWriter"], []),
  moduleDef("agent-planning", "AI", "智能体规划", GitBranch, "选择本次参与的 Agent，查看执行顺序。", ["运行选中 Agent", "重置选择"], ["coordinator", "marketAnalyst", "characterDesigner", "outlineArchitect", "plotPlanner", "leadWriter", "editor", "actor"], []),
  moduleDef("agent-skills", "AI", "智能体技能", Settings, "查看每个 Agent 的输入、输出和职责边界。", ["查看契约"], ["coordinator", "editor", "actor"], []),
];

const moduleGroups: ModuleGroup[] = ["系统", "创作", "设定", "AI"];
const outlineRecords = [
  { title: "主线", meta: "全局", body: "全局大纲时间轴" },
  { title: "第一卷·破土", meta: "35/100章", body: "产品上线，节奏起势。" },
  { title: "第二卷·生长", meta: "35/100章", body: "产品上线，AI 巨头入场。" },
  { title: "第三卷·突围", meta: "40/115章", body: "技术路线与用户增长冲突。" },
  { title: "第四卷·决战", meta: "50/140章", body: "竞品围剿，主线爆发。" },
  { title: "第五卷·登顶", meta: "50/140章", body: "全球化与最终抉择。" },
];
const defaultCharacters: CharacterProfile[] = [
  {
    id: "jiang-ran",
    name: "江然",
    role: "主角",
    gender: "男",
    firstChapter: "第1章 起手",
    bio: "男主角，上辈子 28 岁扑街网文作者，因一条差评在出租屋猝死后穿越回 20 岁的 2015 年。成为 S 市某大学计算机科学与技术学院大三学生，保留了 2015-2025 年完整的 AI 行业记忆。",
    status: "正在把未来十年的 AI 记忆转化成可执行的创业路线。",
    avatarUrl: "",
    gallery: [],
  },
  {
    id: "song-zhiyuan",
    name: "宋知远",
    role: "配角",
    gender: "男",
    firstChapter: "第3章 合伙人",
    bio: "工程能力强，负责早期系统架构，是江然最早的技术同盟。",
    status: "观望中，但已经被项目潜力打动。",
    avatarUrl: "",
    gallery: [],
  },
  {
    id: "chen-yao",
    name: "陈曜",
    role: "反派",
    gender: "男",
    firstChapter: "第6章 竞品",
    bio: "资本和流量都很敏锐，擅长把别人尚未证明的方向包装成自己的故事。",
    status: "准备抢先发布相似产品。",
    avatarUrl: "",
    gallery: [],
  },
  {
    id: "liu-lei",
    name: "刘磊",
    role: "配角",
    gender: "男",
    firstChapter: "第8章 招募",
    bio: "运营型角色，善于把复杂产品讲成人话。",
    status: "正在搭建第一批用户反馈渠道。",
    avatarUrl: "",
    gallery: [],
  },
];
const defaultChapterContent = `## 1. 章节连续性

定位：全书开篇，无前章钩子需求接续
时间：穿越前最后一刻（202X 年城郊）→ 2015 年 9 月 12 日清晨

手机屏幕的蓝光照着江然的脸。

凌晨两点十七分，出租屋的灯没开，只有电脑散热口的嗡鸣填补着寂静。他靠着椅背，拇指停在屏幕上方一条评论区、最新一条。

ID 叫「今天也想弃书」，头像是个默认灰色人形，追了三百零三章，给了两颗星。

「追了三百多章看到这里，真绷不住了。主角越写越蠢，反派全是工具人，剧情灌水灌得能养鱼。你写的时候自己读过吗？还指望 AI 帮你写？算了吧。」

江然盯着最后几个字。

还指望 AI 帮你写。

他往下划了一下，均订两位数，追读个位数。上个月的稿费刚够交网费，书架收藏跌了大半，群里没人说话。

他看着后台「搜索结果：约 15,300 条」，心脏声从耳朵里传出来，咚咚咚的。

2015 年，没有人相信机器能写故事。没有人在做 AI 写作工具。整个行业里，最接近这件事的，是几个学术圈的人用 RNN-LM 生成古诗，一生成就发篇论文，然后就没有然后了。

而他知道这条路会怎么走。

他知道从 RNN 到 Transformer 到 GPT，每一步需要什么，会在什么时候发生。他甚至知道中间哪些方向是死胡同，哪些方向是捷径。`;

const defaultChapterTasks: ChapterTask[] = [
  { id: "skill-1", title: "使用技能", detail: "使用技能 章节写作", status: "done" },
  { id: "skill-2", title: "使用技能", detail: "使用技能 人工智能行业名词时间线", status: "done" },
  { id: "skill-3", title: "使用技能", detail: "使用技能 去AI味", status: "done" },
  { id: "write", title: "写入", detail: "写入章节 · 第1章 · 差评 · 内容", status: "done" },
  { id: "review", title: "审查任务", detail: "要审查内容线索", status: "pending" },
  { id: "edit", title: "编辑", detail: "修改章节 · 第1章 · 差评 · 内容", status: "pending" },
];
const defaultRelations: EntityRelation[] = [];
const defaultOutlineBeats: OutlineBeat[] = [
  { volume: "第一卷·破土", beat: "Beat 1", title: "2015 梦开始", words: "第 1-35 章", tone: "warm" },
  { volume: "第二卷·生长", beat: "Beat 1", title: "产品上线与巨头入场", words: "第 35-70 章", tone: "rose" },
  { volume: "第三卷·突围", beat: "Beat 1", title: "算法路线被质疑", words: "第 70-95 章", tone: "gold" },
  { volume: "第四卷·决战", beat: "Beat 2", title: "资本与技术围剿", words: "第 95-115 章", tone: "mint" },
  { volume: "第五卷·登顶", beat: "Beat 5", title: "差评的真相 & 终极权重", words: "第 115-140 章", tone: "amber" },
  { volume: "第五卷·登顶", beat: "Beat 6", title: "尾声：一空白的屏幕", words: "第 140-150 章", tone: "cream" },
  { volume: "第五卷·登顶", beat: "Beat 4", title: "上市还是被收购", words: "第 110-125 章", tone: "mint" },
];
const defaultOutlineTasks: OutlineTask[] = [
  { id: "outline-1", title: "第一卷主线 content + 6 个节拍 beats", detail: "MVP、第一批读者、产品上线", done: true },
  { id: "outline-2", title: "第二卷主线 content + 6 个节拍 beats", detail: "AI 巨头入场，节奏升级", done: true },
  { id: "outline-3", title: "第三卷突围 content + 6 个节拍 beats", detail: "技术路线争议，主角反击", done: true },
  { id: "outline-4", title: "第四卷决战 content + 6 个节拍 beats", detail: "资本围剿，爽点爆发", done: false },
  { id: "outline-5", title: "第五卷登顶 content + 6 个节拍 beats", detail: "全球化、终局、余韵", done: false },
];
const settingsTabs: Array<{ id: SettingsTab; label: string }> = [
  { id: "general", label: "通用" },
  { id: "appearance", label: "外观" },
  { id: "editor", label: "编辑器" },
  { id: "assistant", label: "AI 助手" },
  { id: "provider", label: "AI 供应商" },
  { id: "model", label: "AI 模型" },
  { id: "dream", label: "梦境" },
  { id: "usage", label: "用量" },
  { id: "storage", label: "存储" },
  { id: "about", label: "关于" },
];
const defaultPaneWidths: PaneWidths = { rail: 52, module: 220, workspace: 180, agent: 320 };
const defaultEnabledAgents = Object.fromEntries(agentSpecs.map((agent) => [agent.id, true])) as Record<AgentId, boolean>;
const defaultModuleRecords = Object.fromEntries(modules.map((module) => [module.id, module.records])) as Record<string, WorkspaceModule["records"]>;
const emptyModuleRecords = Object.fromEntries(modules.map((module) => [module.id, []])) as Record<string, WorkspaceModule["records"]>;
const defaultBaseUrlPresets: BaseUrlPreset[] = [
  { name: "OpenAI", url: "https://api.openai.com/v1" },
  { name: "DeepSeek", url: "https://api.deepseek.com/v1" },
  { name: "OpenRouter", url: "https://openrouter.ai/api/v1" },
  { name: "DashScope", url: "https://dashscope.aliyuncs.com/compatible-mode/v1" },
  { name: "LM Studio", url: "http://localhost:1234/v1" },
];
const baseUrlPresetStorageKey = "ai-novel-factory.baseUrlPresets";
const modelSettingsStorageKey = "ai-novel-factory.modelSettings";
const paneWidthsStorageKey = "ai-novel-factory.paneWidths";
const styleModeStorageKey = "ai-novel-factory.styleMode";
const dreamSettingsStorageKey = "ai-novel-factory.dreamSettings";
const defaultDreamSettings: DreamSettings = {
  enabled: true,
  intervalHours: 24,
  modelAgentId: "coordinator",
  lastRun: "",
  lastSummary: "尚未运行。梦境会合并重复内容，提炼重要设定，提示过时信息。",
};

function blankWorkData(): WorkData {
  return {
    moduleRecords: cloneModuleRecords(emptyModuleRecords),
    chapters: [],
    characters: [],
    relations: [],
    outlineBeats: [],
  };
}

function normalizeWorkData(data: Partial<WorkData> | undefined): WorkData {
  const fallback = blankWorkData();
  return {
    moduleRecords: { ...fallback.moduleRecords, ...cloneModuleRecords(data?.moduleRecords ?? {}) },
    chapters: data?.chapters?.map((chapter) => ({
      ...chapter,
      outline: chapter.outline ?? "",
      outlineApproved: chapter.outlineApproved ?? false,
    })) ?? fallback.chapters,
    characters: data?.characters?.map((character) => ({ ...character, gallery: [...character.gallery] })) ?? fallback.characters,
    relations: data?.relations?.map((relation) => ({ ...relation })) ?? fallback.relations,
    outlineBeats: data?.outlineBeats?.map((beat) => ({ ...beat })) ?? fallback.outlineBeats,
  };
}

function loadWorkDataById() {
  return loadStored<Record<string, Partial<WorkData>>>(workDataStorageKey, {});
}

function saveWorkDataById(data: Record<string, Partial<WorkData>>) {
  saveStored(workDataStorageKey, data);
}

function loadBaseUrlPresets() {
  const savedPresets = loadStored<BaseUrlPreset[]>(baseUrlPresetStorageKey, []);
  if (!Array.isArray(savedPresets)) return defaultBaseUrlPresets;
  return savedPresets.reduce((presets, preset) => {
    const url = typeof preset.url === "string" ? preset.url.trim().replace(/\/+$/, "") : "";
    const name = typeof preset.name === "string" && preset.name.trim() ? preset.name.trim() : "自定义";
    if (url && !presets.some((item) => item.url === url)) presets.push({ name, url });
    return presets;
  }, [...defaultBaseUrlPresets]);
}

function saveBaseUrlPresets(presets: BaseUrlPreset[]) {
  saveStored(baseUrlPresetStorageKey, presets);
}

const defaultModelSettings = agentSpecs.reduce((settings, agent) => {
  settings[agent.id] = {
    apiKey: "",
    baseUrl: defaultBaseUrlPresets[0]?.url ?? "",
    models: [],
    defaultModel: "",
    status: "idle",
    error: "",
  };
  return settings;
}, {} as Record<AgentId, AgentModelSetting>);

function loadModelSettings() {
  const savedSettings = loadStored<Partial<Record<AgentId, AgentModelSetting>>>(modelSettingsStorageKey, {});
  return agentSpecs.reduce((settings, agent) => {
    const saved = savedSettings[agent.id];
    settings[agent.id] = {
      ...defaultModelSettings[agent.id],
      ...saved,
      status: "idle",
      error: "",
    };
    return settings;
  }, {} as Record<AgentId, AgentModelSetting>);
}

function saveModelSettings(settings: Record<AgentId, AgentModelSetting>) {
  saveStored(modelSettingsStorageKey, settings);
}

function loadPaneWidths() {
  return { ...defaultPaneWidths, ...loadStored<Partial<PaneWidths>>(paneWidthsStorageKey, {}) };
}

function loadStyleMode() {
  const saved = loadStored<StyleMode>(styleModeStorageKey, "warm");
  return ["warm", "clean", "night"].includes(saved) ? saved : "warm";
}

function loadDreamSettings() {
  return { ...defaultDreamSettings, ...loadStored<Partial<DreamSettings>>(dreamSettingsStorageKey, {}) };
}

export function App() {
  const store = useMemo(() => new BrowserArtifactStore(), []);
  const orchestrator = useMemo(() => new PipelineOrchestrator(store), [store]);
  const [works, setWorks] = useState(loadWorks);
  const [activeWorkId, setActiveWorkId] = useState(() => works[0]?.id ?? defaultWork.id);
  const [draftWork, setDraftWork] = useState(defaultWork);
  const [tagInput, setTagInput] = useState("");
  const [showCreate, setShowCreate] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [settingsTab, setSettingsTab] = useState<SettingsTab>("general");
  const [providerName, setProviderName] = useState("");
  const [providerUrl, setProviderUrl] = useState("");
  const [baseUrlPresets, setBaseUrlPresets] = useState(loadBaseUrlPresets);
  const [modelSettings, setModelSettings] = useState(loadModelSettings);
  const [paneWidths, setPaneWidths] = useState(loadPaneWidths);
  const [styleMode, setStyleMode] = useState<StyleMode>(loadStyleMode);
  const [dreamSettings, setDreamSettings] = useState(loadDreamSettings);
  const [activeModuleId, setActiveModuleId] = useState("overview");
  const [workDataById, setWorkDataById] = useState(loadWorkDataById);
  const [selectedChapterId, setSelectedChapterId] = useState("");
  const [chapterTasks, setChapterTasks] = useState(defaultChapterTasks);
  const [showAuditReport, setShowAuditReport] = useState(false);
  const [showChapterOutlineModal, setShowChapterOutlineModal] = useState(false);
  const [showContinuityReport, setShowContinuityReport] = useState(false);
  const [chapterMenuId, setChapterMenuId] = useState("");
  const [workMenuId, setWorkMenuId] = useState("");
  const [showInlineCharacter, setShowInlineCharacter] = useState(false);
  const [selectedRecordTitle, setSelectedRecordTitle] = useState("");
  const [characterEditorTab, setCharacterEditorTab] = useState<CharacterEditorTab>("bio");
  const [avatarModalOpen, setAvatarModalOpen] = useState(false);
  const [avatarStyle, setAvatarStyle] = useState<AvatarStyle>("fantasy");
  const [avatarPrompt, setAvatarPrompt] = useState("");
  const [avatarStatus, setAvatarStatus] = useState("");
  const [outlineTasks, setOutlineTasks] = useState(defaultOutlineTasks);
  const [recordSearch, setRecordSearch] = useState("");
  const [actionNotice, setActionNotice] = useState("");
  const [selectedAgentId, setSelectedAgentId] = useState<AgentId>("coordinator");
  const [enabledAgents, setEnabledAgents] = useState(defaultEnabledAgents);
  const [chatInput, setChatInput] = useState("");
  const [agentMessages, setAgentMessages] = useState<AgentMessage[]>([]);
  const [chatBusy, setChatBusy] = useState(false);
  const [assistantTask, setAssistantTask] = useState<AssistantTask | null>(null);
  const [thinkingOpen, setThinkingOpen] = useState(false);
  const [roundtableTopic, setRoundtableTopic] = useState("怎么写第九章");
  const [roundtableRounds, setRoundtableRounds] = useState<RoundtableRound[]>([]);
  const [roundtableBusy, setRoundtableBusy] = useState(false);
  const [skitScene, setSkitScene] = useState("宗门账房外，沈照微和玄衡长老第一次正面交锋");
  const [skitRoles, setSkitRoles] = useState("沈照微、玄衡长老、旁观弟子");
  const [skitRounds, setSkitRounds] = useState<SkitRound[]>([]);
  const [skitBusy, setSkitBusy] = useState(false);
  const [roleplayName, setRoleplayName] = useState("沈照微");
  const [roleplayProfile, setRoleplayProfile] = useState("前世被宗门牺牲，重生后用账本和契约反制宗门；说话克制、锋利，不轻易示弱。");
  const [roleplayInput, setRoleplayInput] = useState("你到底想从这本账里拿回什么？");
  const [roleplayMessages, setRoleplayMessages] = useState<RoleplayMessage[]>([]);
  const [roleplayBusy, setRoleplayBusy] = useState(false);
  const [snapshot, setSnapshot] = useState<PipelineRunSnapshot | null>(null);
  const [running, setRunning] = useState(false);

  const work = works.find((item) => item.id === activeWorkId) ?? works[0] ?? null;
  const activeWorkData = work ? normalizeWorkData(workDataById[work.id]) : blankWorkData();
  const moduleRecords = activeWorkData.moduleRecords;
  const chapters = activeWorkData.chapters;
  const characters = activeWorkData.characters;
  const relations = activeWorkData.relations;
  const outlineBeats = activeWorkData.outlineBeats;
  const activeModule = modules.find((item) => item.id === activeModuleId) ?? modules[0];
  const activeRecords = moduleRecords[activeModule.id] ?? [];
  const chapterRecords = chapters.map((chapter) => ({ title: chapter.title, meta: chapter.id, body: chapter.content }));
  const characterRecords = characters.map((character) => ({ title: character.name, meta: character.role, body: character.bio }));
  const sidebarRecords = !work ? [] : activeModule.id === "outline" ? outlineRecords : activeModule.id === "characters" ? characterRecords : activeModule.id === "chapters" ? chapterRecords : activeRecords;
  const visibleRecords = sidebarRecords.filter((record) => record.title.includes(recordSearch.trim()));
  const listRecords = work ? (visibleRecords.length ? visibleRecords : [{ title: activeModule.label === "概览" ? "作品状态" : "主线", meta: "默认", body: activeModule.description }]) : [];
  const selectedChapter = chapters.find((chapter) => chapter.id === selectedChapterId)
    ?? chapters.find((chapter) => chapter.title === selectedRecordTitle)
    ?? chapters[0];
  const selectedCharacter = characters.find((character) => character.name === selectedRecordTitle) ?? characters[0];
  const ActiveIcon = activeModule.icon;
  const selectedAgent = agentSpecs.find((agent) => agent.id === selectedAgentId) ?? agentSpecs[0];
  const relevantAgents = agentSpecs.filter((agent) => activeModule.agentIds.includes(agent.id));
  const artifacts = snapshot?.project.artifacts ?? [];
  const reviewOpen = snapshot?.project.status === "blocked-for-review";
  const exportBundle = [...artifacts].reverse()
    .find((artifact) => artifact.kind === "export_bundle")
    ?.payload as ExportBundlePayload | undefined;
  const selectedAgentMessages = agentMessages.filter((message) => message.moduleId === activeModuleId && message.agentId === selectedAgent.id);
  const shellStyle = {
    "--rail-width": `${paneWidths.rail}px`,
    "--module-width": `${paneWidths.module}px`,
    "--workspace-width": `${paneWidths.workspace}px`,
    "--agent-width": `${paneWidths.agent}px`,
  } as CSSProperties;

  function updateActiveWorkData(updater: StateUpdate<WorkData>) {
    if (!work) return;
    setWorkDataById((dataById) => {
      const currentData = normalizeWorkData(dataById[work.id]);
      const nextData = typeof updater === "function" ? (updater as (value: WorkData) => WorkData)(currentData) : updater;
      const nextDataById = { ...dataById, [work.id]: nextData };
      saveWorkDataById(nextDataById);
      return nextDataById;
    });
  }

  function setModuleRecordsForWork(next: StateUpdate<Record<string, WorkspaceModule["records"]>>) {
    updateActiveWorkData((data) => ({ ...data, moduleRecords: typeof next === "function" ? (next as (value: Record<string, WorkspaceModule["records"]>) => Record<string, WorkspaceModule["records"]>)(data.moduleRecords) : next }));
  }

  function setChaptersForWork(next: StateUpdate<ChapterDraft[]>) {
    updateActiveWorkData((data) => ({ ...data, chapters: typeof next === "function" ? (next as (value: ChapterDraft[]) => ChapterDraft[])(data.chapters) : next }));
  }

  function setCharactersForWork(next: StateUpdate<CharacterProfile[]>) {
    updateActiveWorkData((data) => ({ ...data, characters: typeof next === "function" ? (next as (value: CharacterProfile[]) => CharacterProfile[])(data.characters) : next }));
  }

  function setRelationsForWork(next: StateUpdate<EntityRelation[]>) {
    updateActiveWorkData((data) => ({ ...data, relations: typeof next === "function" ? (next as (value: EntityRelation[]) => EntityRelation[])(data.relations) : next }));
  }

  function setOutlineBeatsForWork(next: StateUpdate<OutlineBeat[]>) {
    updateActiveWorkData((data) => ({ ...data, outlineBeats: typeof next === "function" ? (next as (value: OutlineBeat[]) => OutlineBeat[])(data.outlineBeats) : next }));
  }

  async function startAssistantTask(
    title: string,
    detail: string,
    thinking: string,
    steps: string[],
    action: () => Promise<void> | void,
  ) {
    setThinkingOpen(false);
    setAssistantTask({
      title,
      detail,
      status: "running",
      thinking,
      result: "处理中...",
      steps: steps.map((step, index) => ({ title: step, status: index === 0 ? "running" : "pending" })),
    });
    try {
      await action();
      setAssistantTask({
        title,
        detail,
        status: "done",
        thinking,
        result: "任务已完成，可以继续追问或选择下一步。",
        steps: steps.map((step) => ({ title: step, status: "done" })),
      });
    } catch (error) {
      setAssistantTask({
        title,
        detail,
        status: "error",
        thinking,
        result: error instanceof Error ? error.message : "任务失败",
        steps: steps.map((step) => ({ title: step, status: "done" })),
      });
    }
  }

  async function chooseAgent(agentId: AgentId, prompt: string) {
    await sendPromptToAgent(agentId, prompt);
  }

  function conversationOptions(): ConversationOption[] {
    if (activeModule.id === "chapters") {
      return [
        {
          label: "先写章节细纲",
          detail: "整理主内容、目标、冲突和钩子。",
          onSelect: () => void startAssistantTask("写章节细纲", "先产出可确认的章节大纲。", "内部选择情节策划，读取作品设定、当前大纲和人物关系，只输出细纲，不直接写正文。", ["读取章节上下文", "推理过程", "写入章节细纲"], () => selectedChapter ? generateChapterOutline(selectedChapter) : createChapter()),
        },
        {
          label: "确认细纲",
          detail: "确认后才允许进入正文撰写。",
          onSelect: () => void startAssistantTask("确认章节细纲", "锁定本章写作依据。", "把用户确认作为审批点，后续正文只能按已确认细纲生成。", ["读取细纲", "设置审批点", "开放正文写作"], () => approveChapterOutline()),
        },
        {
          label: "写正文",
          detail: "按已确认细纲写正文。",
          onSelect: () => void startAssistantTask("撰写正文", "按细纲生成章节正文。", "内部选择写作主笔，读取已确认细纲；完成后交给责编做节奏和一致性检查。", ["读取已确认细纲", "撰写正文", "准备审查"], () => generateChapterBody()),
        },
      ];
    }
    if (activeModule.id === "outline" || activeModule.id === "hooks") {
      return [
        { label: "梳理主线", detail: "把卷纲、阶段目标和钩子回收串起来。", onSelect: () => void startAssistantTask("梳理主线", "形成可执行的大纲方向。", "内部选择大纲架构，必要时交给情节策划补章节任务。", ["读取作品信息", "推理过程", "整理主线"], () => chooseAgent("outlineArchitect", "帮我梳理当前作品的主线、阶段目标和钩子回收。")) },
        { label: "拆成章节", detail: "把大纲拆成可写的章节任务。", onSelect: () => void startAssistantTask("拆成章节", "把大纲拆到可写粒度。", "内部选择情节策划，把主线拆成章节目标、冲突和场景卡。", ["读取大纲", "拆章节任务", "等待确认"], () => chooseAgent("plotPlanner", "把当前大纲拆成章节细纲和写作任务。")) },
        { label: "检查漏洞", detail: "检查节奏、伏笔和逻辑断点。", onSelect: () => void startAssistantTask("检查漏洞", "找出影响继续写的问题。", "内部选择责编，检查节奏、伏笔、逻辑和信息缺口。", ["读取大纲", "推理过程", "列出问题"], () => chooseAgent("editor", "检查当前大纲里的节奏、伏笔和逻辑断点。")) },
      ];
    }
    if (activeModule.id === "characters" || activeModule.id === "relationship-graph") {
      return [
        { label: "补人物动机", detail: "完善人物目标、伤口和关系压力。", onSelect: () => void startAssistantTask("补人物动机", "补齐人物驱动力。", "内部选择角色设计，读取人物卡和关系网，补目标、伤口、欲望和压力。", ["读取人物卡", "推理过程", "写入建议"], () => chooseAgent("characterDesigner", "帮我补全人物动机、人物弧和关系压力。")) },
        { label: "检查关系网", detail: "找出人物关系里的断点和冲突机会。", onSelect: () => void startAssistantTask("检查关系网", "找关系断点和可用冲突。", "内部选择角色设计，必要时交给责编检查一致性。", ["读取关系网", "检查断点", "输出冲突机会"], () => chooseAgent("characterDesigner", "检查当前人物关系网，找断点和冲突机会。")) },
        { label: "写对话口吻", detail: "让演员 Agent 试一段角色声音。", onSelect: () => void startAssistantTask("试角色口吻", "确认角色说话方式。", "内部选择演员 Agent，根据人物卡代入角色，只写角色会说的话。", ["读取人物设定", "角色代入", "输出对话"], () => chooseAgent("actor", "用角色本人的口吻试写一段对话。")) },
      ];
    }
    return [
      { label: "下一步做什么", detail: "根据当前模块给出最短行动路径。", onSelect: () => void startAssistantTask("规划下一步", "给出当前模块下一步选项。", "内部选择当前模块主 Agent，先读上下文，再给最短行动路径。", ["读取当前模块", "推理过程", "给出选项"], () => chooseAgent(activeModule.agentIds[0] ?? "coordinator", "根据当前界面，告诉我下一步应该做什么，并给出选项。")) },
      { label: "整理素材", detail: "把现有信息归纳成可写内容。", onSelect: () => void startAssistantTask("整理素材", "把散信息变成创作任务。", "内部选择当前模块主 Agent，合并重复内容，保留可写信息。", ["读取素材", "归纳整理", "输出任务"], () => chooseAgent(activeModule.agentIds[0] ?? "coordinator", "整理当前模块的信息，变成可执行的创作任务。")) },
      { label: "检查问题", detail: "找出当前内容最影响继续写的地方。", onSelect: () => void startAssistantTask("检查问题", "定位继续写的阻塞点。", "内部选择责编，检查逻辑、节奏和信息缺口。", ["读取内容", "推理过程", "输出问题"], () => chooseAgent("editor", "检查当前内容最影响继续写的问题。")) },
    ];
  }

  async function runPipeline() {
    const source = work ?? draftWork;
    setRunning(true);
    try {
      setSnapshot(await orchestrator.runUntilReview(`${source.title}\n${source.intro}`));
    } finally {
      setRunning(false);
    }
  }

  async function approveAndExport() {
    if (!snapshot) return;
    setRunning(true);
    try {
      setSnapshot(await orchestrator.approveAndExport(snapshot));
    } finally {
      setRunning(false);
    }
  }

  function openCreateWork() {
    setDraftWork({ ...defaultWork, id: crypto.randomUUID(), title: `新作品 ${works.length + 1}` });
    setTagInput("");
    setShowCreate(true);
  }

  function saveWork() {
    const savedWork = { ...draftWork, title: draftWork.title.trim() || "未命名作品" };
    const isNewWork = !works.some((item) => item.id === savedWork.id);
    const nextWorks = works.some((item) => item.id === savedWork.id)
      ? works.map((item) => item.id === savedWork.id ? savedWork : item)
      : [...works, savedWork];
    setWorks(nextWorks);
    saveWorks(nextWorks);
    if (isNewWork) {
      setWorkDataById((dataById) => {
        const nextDataById = { ...dataById, [savedWork.id]: blankWorkData() };
        saveWorkDataById(nextDataById);
        return nextDataById;
      });
    }
    setActiveWorkId(savedWork.id);
    setDraftWork(savedWork);
    setShowCreate(false);
    setSnapshot(null);
    setActionNotice(`已创建：${savedWork.title}`);
  }

  function deleteWork(id: string) {
    const nextWorks = works.filter((item) => item.id !== id);
    setWorks(nextWorks);
    saveWorks(nextWorks);
    setWorkDataById((dataById) => {
      const { [id]: _deleted, ...nextDataById } = dataById;
      saveWorkDataById(nextDataById);
      return nextDataById;
    });
    setWorkMenuId("");
    setSnapshot(null);
    setSelectedChapterId("");
    setSelectedRecordTitle("");
    if (activeWorkId === id) {
      setActiveWorkId(nextWorks[0]?.id ?? "");
      setDraftWork(nextWorks[0] ?? defaultWork);
      if (!nextWorks.length) {
        setActiveModuleId("overview");
        setAgentMessages([]);
        setAssistantTask(null);
        setChatInput("");
      }
    }
    setActionNotice("小说已删除");
  }

  function startPaneResize(event: ReactPointerEvent, pane: PaneKey) {
    event.preventDefault();
    const startX = event.clientX;
    const startWidth = paneWidths[pane];
    const minWidths: PaneWidths = { rail: 44, module: 150, workspace: 140, agent: 220 };
    const maxWidths: PaneWidths = { rail: 88, module: 360, workspace: 360, agent: 520 };
    const direction = pane === "agent" ? -1 : 1;

    function onPointerMove(moveEvent: PointerEvent) {
      const nextWidth = startWidth + (moveEvent.clientX - startX) * direction;
      setPaneWidths((widths) => {
        const nextWidths = {
          ...widths,
          [pane]: Math.min(maxWidths[pane], Math.max(minWidths[pane], nextWidth)),
        };
        saveStored(paneWidthsStorageKey, nextWidths);
        return nextWidths;
      });
    }

    function onPointerUp() {
      document.body.classList.remove("is-resizing-pane");
      window.removeEventListener("pointermove", onPointerMove);
      window.removeEventListener("pointerup", onPointerUp);
    }

    document.body.classList.add("is-resizing-pane");
    window.addEventListener("pointermove", onPointerMove);
    window.addEventListener("pointerup", onPointerUp, { once: true });
  }

  function addTag() {
    const value = tagInput.trim();
    if (!value || draftWork.tags.includes(value)) return;
    setDraftWork({ ...draftWork, tags: [...draftWork.tags, value] });
    setTagInput("");
  }

  function selectModule(module: WorkspaceModule) {
    setActiveModuleId(module.id);
    setSelectedAgentId(module.agentIds[0] ?? "coordinator");
    setSelectedRecordTitle("");
    setRecordSearch("");
    setChapterMenuId("");
    setWorkMenuId("");
  }

  function selectModuleById(moduleId: string) {
    selectModule(modules.find((module) => module.id === moduleId) ?? modules[0]);
  }

  async function callAgentModel(agent: AgentSpec, messages: ChatRequestMessage[]) {
    const setting = modelSettings[agent.id];
    const baseUrl = setting.baseUrl.trim().replace(/\/+$/, "");
    const apiKey = setting.apiKey.trim();
    const model = setting.defaultModel.trim();
    if (!baseUrl || !apiKey || !model) throw new Error(`${agent.title} 未配置 API key、模型接口或默认模型`);

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({ model, messages }),
    });
    if (!response.ok) throw new Error(`${agent.title} 调用失败：${response.status}`);
    const payload = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
    const answer = payload.choices?.[0]?.message?.content?.trim();
    if (!answer) throw new Error(`${agent.title} 没有返回内容`);
    return answer;
  }

  async function sendPromptToAgent(agentId: AgentId, prompt: string) {
    const text = prompt.trim();
    if (!text) return;
    if (!work) {
      openCreateWork();
      return;
    }
    const moduleId = activeModuleId;
    const agent = agentSpecs.find((item) => item.id === agentId) ?? selectedAgent;
    setSelectedAgentId(agent.id);

    const history = agentMessages
      .filter((message) => message.moduleId === moduleId && message.agentId === agent.id)
      .slice(-10)
      .map((message) => ({ role: message.role, content: message.text }));
    const userMessage: AgentMessage = { moduleId, agentId: agent.id, role: "user", text };
    setAgentMessages((messages) => [...messages, userMessage]);
    setChatInput("");
    setChatBusy(true);

    try {
      const answer = await callAgentModel(agent, [
        {
          role: "system",
          content: `你是${agent.title}，职责：${agent.responsibilities.join("、")}。回答要直接服务当前小说创作。`,
        },
        ...history,
        { role: "user", content: text },
      ]);
      setAgentMessages((messages) => [...messages, { moduleId, agentId: agent.id, role: "assistant", text: answer }]);
    } catch (error) {
      setAgentMessages((messages) => [...messages, {
        moduleId,
        agentId: agent.id,
        role: "assistant",
        text: error instanceof Error ? error.message : "聊天失败",
      }]);
    } finally {
      setChatBusy(false);
    }
  }

  async function runRoundtableRound() {
    const topic = roundtableTopic.trim();
    if (!topic) return;
    const agents = activeModule.agentIds
      .filter((agentId) => enabledAgents[agentId])
      .map((agentId) => agentSpecs.find((agent) => agent.id === agentId))
      .filter((agent): agent is AgentSpec => Boolean(agent));
    if (!agents.length) {
      setActionNotice("请至少启用一个圆桌 Agent");
      return;
    }

    const priorDiscussion = roundtableRounds
      .flatMap((round) => round.replies.map((reply) => `${reply.title}：${reply.text}`))
      .join("\n\n");
    setRoundtableBusy(true);
    try {
      const replies = await Promise.all(agents.map(async (agent) => {
        try {
          const text = await callAgentModel(agent, [
            {
              role: "system",
              content: `你正在参加小说创作圆桌会议。你的身份是${agent.title}，职责：${agent.responsibilities.join("、")}。只从你的职责角度发言，给出可执行建议。`,
            },
            {
              role: "user",
              content: `作品：${work?.title ?? "未命名"}\n简介：${work?.intro ?? ""}\n议题：${topic}\n已有讨论：${priorDiscussion || "暂无"}\n请给出本轮观点。`,
            },
          ]);
          return { agentId: agent.id, title: agent.title, text };
        } catch (error) {
          return {
            agentId: agent.id,
            title: agent.title,
            text: error instanceof Error ? error.message : "发言失败",
          };
        }
      }));
      setRoundtableRounds((rounds) => [...rounds, { id: crypto.randomUUID(), topic, replies }]);
    } finally {
      setRoundtableBusy(false);
    }
  }

  async function runSkitRound() {
    const scene = skitScene.trim();
    const roles = skitRoles.trim();
    if (!scene || !roles) return;
    const agents = activeModule.agentIds
      .filter((agentId) => enabledAgents[agentId])
      .map((agentId) => agentSpecs.find((agent) => agent.id === agentId))
      .filter((agent): agent is AgentSpec => Boolean(agent));
    if (!agents.length) {
      setActionNotice("请至少启用一个小剧场 Agent");
      return;
    }

    const previous = skitRounds
      .flatMap((round) => round.replies.map((reply) => `${reply.title}：${reply.text}`))
      .join("\n\n");
    setSkitBusy(true);
    try {
      const replies = await Promise.all(agents.map(async (agent) => {
        try {
          const text = await callAgentModel(agent, [
            {
              role: "system",
              content: `你正在参与小说小剧场。你的身份是${agent.title}，职责：${agent.responsibilities.join("、")}。请让角色自然说话，不要写功能说明。`,
            },
            {
              role: "user",
              content: `作品：${work?.title ?? "未命名"}\n简介：${work?.intro ?? ""}\n角色：${roles}\n场景：${scene}\n上一轮：${previous || "暂无"}\n请生成本轮小剧场内容。角色设计 Agent 侧重动机和台词，演员 Agent 侧重角色代入和自然发声，写作 Agent 侧重正文表演，编辑 Agent 侧重补强冲突和节奏。`,
            },
          ]);
          return { agentId: agent.id, title: agent.title, text };
        } catch (error) {
          return {
            agentId: agent.id,
            title: agent.title,
            text: error instanceof Error ? error.message : "表演失败",
          };
        }
      }));
      setSkitRounds((rounds) => [...rounds, { id: crypto.randomUUID(), scene, roles, replies }]);
    } finally {
      setSkitBusy(false);
    }
  }

  async function runRoleplayMessage() {
    const character = roleplayName.trim();
    const profile = roleplayProfile.trim();
    const text = roleplayInput.trim();
    if (!character || !profile || !text) return;
    const agent = agentSpecs.find((item) => item.id === "actor" && activeModule.agentIds.includes(item.id) && enabledAgents[item.id])
      ?? agentSpecs.find((item) => item.id === "leadWriter" && activeModule.agentIds.includes(item.id) && enabledAgents[item.id])
      ?? activeModule.agentIds
        .filter((agentId) => enabledAgents[agentId])
        .map((agentId) => agentSpecs.find((item) => item.id === agentId))
        .find((item): item is AgentSpec => Boolean(item));
    if (!agent) {
      setActionNotice("请至少启用一个角色扮演 Agent");
      return;
    }

    const nextUserMessage: RoleplayMessage = { role: "user", text };
    setRoleplayMessages((messages) => [...messages, nextUserMessage]);
    setRoleplayInput("");
    setRoleplayBusy(true);
    try {
      const history = roleplayMessages.slice(-10).map((message): ChatRequestMessage => ({
        role: message.role === "character" ? "assistant" : "user",
        content: message.text,
      }));
      const answer = await callAgentModel(agent, [
        {
          role: "system",
          content: `你正在进行小说角色扮演。你必须代入角色“${character}”，人设：${profile}。只用角色本人会说的话和必要动作回应，不要解释你是 AI，不要跳出角色。`,
        },
        ...history,
        { role: "user", content: text },
      ]);
      setRoleplayMessages((messages) => [...messages, { role: "character", text: answer }]);
    } catch (error) {
      setRoleplayMessages((messages) => [...messages, {
        role: "character",
        text: error instanceof Error ? error.message : "角色回复失败",
      }]);
    } finally {
      setRoleplayBusy(false);
    }
  }

  function updateModelSetting(agentId: AgentId, patch: Partial<AgentModelSetting>) {
    setModelSettings((settings) => {
      const nextSettings = {
        ...settings,
        [agentId]: { ...settings[agentId], ...patch },
      };
      saveModelSettings(nextSettings);
      return nextSettings;
    });
  }

  function selectStyleMode(mode: StyleMode) {
    setStyleMode(mode);
    saveStored(styleModeStorageKey, mode);
  }

  function updateDreamSettings(patch: Partial<DreamSettings>) {
    setDreamSettings((settings) => {
      const nextSettings = { ...settings, ...patch };
      saveStored(dreamSettingsStorageKey, nextSettings);
      return nextSettings;
    });
  }

  function addProviderPresetFromSettings() {
    const name = providerName.trim() || "自定义";
    const url = providerUrl.trim().replace(/\/+$/, "");
    if (!url || baseUrlPresets.some((preset) => preset.url === url)) return;
    const nextPresets = [...baseUrlPresets, { name, url }];
    setBaseUrlPresets(nextPresets);
    saveBaseUrlPresets(nextPresets);
    setProviderName("");
    setProviderUrl("");
  }

  function runDreamTidy() {
    const recordCount = Object.values(moduleRecords).reduce((total, records) => total + records.length, 0);
    const agent = agentSpecs.find((item) => item.id === dreamSettings.modelAgentId) ?? agentSpecs[0];
    updateDreamSettings({
      lastRun: new Date().toLocaleString(),
      lastSummary: `已由 ${agent.title} 整理 ${recordCount} 条创作记忆：合并重复内容，保留关键设定，标记可能过时的信息。`,
    });
  }

  function updateCharacter(id: string, patch: Partial<CharacterProfile>) {
    setCharactersForWork((items) => items.map((item) => item.id === id ? { ...item, ...patch } : item));
  }

  function createChapter() {
    const nextChapter: ChapterDraft = {
      id: crypto.randomUUID(),
      title: chapters.length ? `第${chapters.length + 1}章 新章节` : "第1章 差评",
      status: "细纲",
      outline: "",
      outlineApproved: false,
      content: "",
      wordCount: 0,
    };
    setChaptersForWork((items) => [...items, nextChapter]);
    setSelectedChapterId(nextChapter.id);
    setSelectedRecordTitle(nextChapter.title);
    setActionNotice(`已新建：${nextChapter.title}`);
  }

  function updateChapter(id: string, patch: Partial<ChapterDraft>) {
    setChaptersForWork((items) => items.map((item) => item.id === id ? { ...item, ...patch } : item));
  }

  async function generateChapterOutline(chapter = selectedChapter) {
    if (!chapter) return;
    const moduleId = activeModuleId;
    const agent = agentSpecs.find((item) => item.id === "plotPlanner") ?? selectedAgent;
    const prompt = `作品：${work?.title ?? "未命名"}\n简介：${work?.intro ?? ""}\n章节：${chapter.title}\n请写这一章细纲。`;
    setSelectedAgentId(agent.id);
    setAgentMessages((messages) => [...messages, { moduleId, agentId: agent.id, role: "user", text: prompt }]);
    setChatBusy(true);
    try {
      const outline = await callAgentModel(agent, [
        { role: "system", content: "你是小说章节细纲智能体。只输出章节细纲，包含主内容、目标、冲突、伏笔和钩子兑现。" },
        { role: "user", content: prompt },
      ]);
      updateChapter(chapter.id, { outline, outlineApproved: false, status: "细纲" });
      setAgentMessages((messages) => [...messages, { moduleId, agentId: agent.id, role: "assistant", text: outline }]);
      setActionNotice("已生成章节细纲，确认后再写正文");
    } catch (error) {
      setActionNotice(error instanceof Error ? error.message : "生成细纲失败");
    } finally {
      setChatBusy(false);
    }
  }

  async function sendAgentMessage() {
    await sendPromptToAgent(selectedAgent.id, chatInput);
  }

  function approveChapterOutline(chapter = selectedChapter) {
    if (!chapter) return;
    const moduleId = activeModuleId;
    updateChapter(chapter.id, { outlineApproved: true, status: "待正文" });
    const agent = agentSpecs.find((item) => item.id === "plotPlanner") ?? selectedAgent;
    setSelectedAgentId(agent.id);
    setAgentMessages((messages) => [...messages,
      { moduleId, agentId: agent.id, role: "user", text: `确认《${chapter.title}》章节细纲。` },
      { moduleId, agentId: agent.id, role: "assistant", text: "细纲已确认。下一步可以按这份细纲生成正文。" },
    ]);
    setActionNotice("细纲已确认，可以生成正文");
  }

  async function generateChapterBody(chapter = selectedChapter) {
    if (!chapter) return;
    if (!chapter.outlineApproved) {
      setActionNotice("请先确认章节细纲");
      return;
    }
    const moduleId = activeModuleId;
    const agent = agentSpecs.find((item) => item.id === "leadWriter") ?? selectedAgent;
    const prompt = `作品：${work?.title ?? "未命名"}\n章节：${chapter.title}\n章节细纲：\n${chapter.outline}\n请写本章正文。`;
    setSelectedAgentId(agent.id);
    setAgentMessages((messages) => [...messages, { moduleId, agentId: agent.id, role: "user", text: prompt }]);
    setChatBusy(true);
    try {
      const content = await callAgentModel(agent, [
        { role: "system", content: "你是小说正文主笔。严格按照用户确认的章节细纲写正文，不要复述说明。" },
        { role: "user", content: prompt },
      ]);
      updateChapter(chapter.id, { content, wordCount: content.length, status: "正文" });
      setAgentMessages((messages) => [...messages, { moduleId, agentId: agent.id, role: "assistant", text: content }]);
      setActionNotice("已生成正文");
    } catch (error) {
      setActionNotice(error instanceof Error ? error.message : "生成正文失败");
    } finally {
      setChatBusy(false);
    }
  }

  function moveChapter(id: string) {
    setChaptersForWork((items) => {
      const index = items.findIndex((item) => item.id === id);
      if (index <= 0) return items;
      const next = [...items];
      [next[index - 1], next[index]] = [next[index], next[index - 1]];
      return next;
    });
    setChapterMenuId("");
    setActionNotice("章节已上移");
  }

  function deleteChapter(id: string) {
    setChaptersForWork((items) => items.filter((item) => item.id !== id));
    if (selectedChapterId === id) setSelectedChapterId("");
    setChapterMenuId("");
    setActionNotice("章节已删除");
  }

  function publishChapter(id: string) {
    updateChapter(id, { status: "已发布" });
    setChapterMenuId("");
    setActionNotice("章节已发布");
  }

  function acceptChapterSuggestions() {
    setChapterTasks((tasks) => tasks.map((task) => ({ ...task, status: "done" })));
    setActionNotice("已全部接受章节修订");
  }

  function addRelation() {
    setRelationsForWork((items) => [...items, {
      id: crypto.randomUUID(),
      source: "江然",
      relation: "friend",
      target: "刘磊",
      note: "大学室友，上下铺；后续成为早期运营伙伴。",
    }]);
    setActionNotice("已添加关系");
  }

  function acceptCharacterSuggestions() {
    setCharactersForWork((items) => items.map((item) => {
      if (item.name === "江然") return { ...item, status: "2015年9月12日状态：与江然同住一个宿舍，对江然晚上写小说的事略知一二。" };
      if (item.name === "宋知远") return { ...item, bio: `${item.bio} 后续与江然建立技术协作关系。` };
      return item;
    }));
    setActionNotice("已全部接受人物卡片更新");
  }

  function generateAvatar() {
    if (!selectedCharacter) return;
    const url = makeAvatarUrl(selectedCharacter.name, avatarStyle, avatarPrompt);
    updateCharacter(selectedCharacter.id, {
      avatarUrl: url,
      gallery: [url, ...selectedCharacter.gallery].slice(0, 4),
    });
    setAvatarStatus(`头像已生成：${selectedCharacter.name} · ${avatarLabel(avatarStyle)}`);
    setAvatarModalOpen(false);
  }

  function setAgentBaseUrl(agentId: AgentId, baseUrl: string) {
    updateModelSetting(agentId, { baseUrl, status: "idle", error: "" });
  }

  async function copyBaseUrl(baseUrl: string) {
    if (!baseUrl.trim()) return;
    try {
      await navigator.clipboard.writeText(baseUrl.trim());
      setActionNotice("已复制模型接口");
    } catch {
      setActionNotice("浏览器拒绝剪贴板权限");
    }
  }

  async function pasteBaseUrl(agentId: AgentId) {
    try {
      const text = await navigator.clipboard.readText();
      if (!text.trim()) return;
      setAgentBaseUrl(agentId, text.trim());
      setActionNotice("已粘贴模型接口");
    } catch {
      setActionNotice("浏览器拒绝剪贴板权限");
    }
  }

  function addBaseUrlPreset(agentId: AgentId, baseUrl: string) {
    const url = baseUrl.trim().replace(/\/+$/, "");
    if (!url || baseUrlPresets.some((preset) => preset.url === url)) return;
    const nextPresets = [...baseUrlPresets, { name: "自定义", url }];
    setBaseUrlPresets(nextPresets);
    saveBaseUrlPresets(nextPresets);
    setAgentBaseUrl(agentId, url);
    setActionNotice("已加入模型接口预设");
  }

  async function loadAgentModels(agentId: AgentId) {
    const setting = modelSettings[agentId];
    const baseUrl = setting.baseUrl.trim().replace(/\/+$/, "");
    const apiKey = setting.apiKey.trim();
    if (!baseUrl || !apiKey) return;

    updateModelSetting(agentId, { status: "loading", error: "" });
    try {
      const response = await fetch(`${baseUrl}/models`, {
        headers: { Authorization: `Bearer ${apiKey}` },
      });
      if (!response.ok) throw new Error(`读取失败：${response.status}`);
      const payload = await response.json() as { data?: Array<{ id?: string }> };
      const models = (payload.data ?? []).map((model) => model.id).filter((id): id is string => Boolean(id));
      if (!models.length) throw new Error("没有读取到模型");
      updateModelSetting(agentId, {
        models,
        defaultModel: setting.defaultModel && models.includes(setting.defaultModel) ? setting.defaultModel : models[0],
        status: "ready",
        error: "",
      });
    } catch (error) {
      updateModelSetting(agentId, {
        status: "error",
        error: error instanceof Error ? error.message : "读取模型失败",
      });
    }
  }

  function addModuleRecord(action = `新增${activeModule.label}`) {
    const currentRecords = moduleRecords[activeModule.id] ?? [];
    const nextRecord = {
      title: `${activeModule.label}${currentRecords.length + 1}`,
      meta: action,
      body: `由“${action}”创建，后续接入真实存储后替换为完整编辑器。`,
    };
    setModuleRecordsForWork({
      ...moduleRecords,
      [activeModule.id]: [...currentRecords, nextRecord],
    });
    setSelectedRecordTitle(nextRecord.title);
    setActionNotice(`已${action}`);
  }

  function addOutlineNode() {
    const current = selectedRecordTitle && selectedRecordTitle !== "主线" ? selectedRecordTitle : outlineRecords[1].title;
    const count = outlineBeats.filter((beat) => beat.volume === current).length;
    const nextBeat = {
      volume: current,
      beat: `Beat ${count + 1}`,
      title: "新的剧情节点",
      words: "待分配章节",
      tone: "cream",
      summary: "写下这个节点的冲突、转折和承接关系。",
    };
    setOutlineBeatsForWork([...outlineBeats, nextBeat]);
    setSelectedRecordTitle(current);
    setActionNotice(`已给${current}新增节点`);
  }

  function updateOutlineBeat(target: OutlineBeat, patch: Partial<OutlineBeat>) {
    setOutlineBeatsForWork((current) => current.map((beat) => beat === target ? { ...beat, ...patch } : beat));
  }

  function runModuleAction(action: string) {
    if (action === "新增节点") {
      addOutlineNode();
      return;
    }
    if (action === "新建章节") {
      createChapter();
      return;
    }
    if (action === "继续创作") {
      selectModule(modules.find((module) => module.id === "chapters") ?? activeModule);
      setActionNotice("已切到章节");
      return;
    }
    if (action.includes("规划") || action.includes("运行")) {
      void runPipeline();
      setActionNotice("已启动规划流程");
      return;
    }
    if (action === "生成正文") {
      if (!selectedChapter) {
        createChapter();
        setActionNotice("已新建章节，请先生成章节细纲");
        return;
      }
      if (!selectedChapter.outline) {
        void generateChapterOutline(selectedChapter);
        return;
      }
      void generateChapterBody(selectedChapter);
      return;
    }
    if (action === "重置选择") {
      setEnabledAgents(defaultEnabledAgents);
      setActionNotice("已重置 Agent 选择");
      return;
    }
    if (action === "查看契约") {
      selectModule(modules.find((module) => module.id === "agent-skills") ?? activeModule);
      return;
    }
    if (action === "发送给 Agent") {
      setChatInput(`请处理${activeModule.label}。`);
      setActionNotice("已填入聊天输入框");
      return;
    }
    addModuleRecord(action);
  }

  return (
    <main className={`studio-shell theme-${styleMode}`} style={shellStyle}>
      <aside className="tool-rail" aria-label="主工具栏">
        <button
          type="button"
          className={activeModule.id === "overview" ? "active" : ""}
          title="作品首页"
          aria-label="作品首页"
          onClick={() => selectModule(modules[0])}
        >
          <BookOpen size={18} aria-hidden="true" />
        </button>
        {moduleGroups.map((group) => {
          const Icon = group === "系统" ? LayoutDashboard : group === "创作" ? PenLine : group === "设定" ? Settings : Bot;
          const target = modules.find((item) => item.group === group) ?? modules[0];
          const isSettings = group === "设定";
          return (
            <button
              type="button"
              className={isSettings ? (showSettings ? "active" : "") : activeModule.group === group && activeModule.id !== "overview" ? "active" : ""}
              key={group}
              title={isSettings ? "设置" : group}
              aria-label={isSettings ? "打开设置" : `跳转到${group}`}
              onClick={() => isSettings ? setShowSettings(true) : selectModule(target)}
            >
              <Icon size={18} aria-hidden="true" />
            </button>
          );
        })}
        <div className="pane-resizer pane-resizer-right" role="separator" aria-label="调整图标栏宽度" onPointerDown={(event) => startPaneResize(event, "rail")} />
      </aside>

      <aside className="module-tree">
        <header>
          <strong>AI Novel Factory</strong>
          <span>创作空间</span>
        </header>
        <button type="button" className="new-work" onClick={openCreateWork}>
          <Plus size={16} aria-hidden="true" /> 新建作品
        </button>
        {moduleGroups.map((group) => (
          <nav key={group} aria-label={group}>
            <h2>{group}</h2>
            {modules.filter((item) => item.group === group).map((item) => (
              <button
                type="button"
                className={item.id === activeModule.id ? "active" : ""}
                onClick={() => selectModule(item)}
                key={item.id}
              >
                {item.label}
              </button>
            ))}
          </nav>
        ))}
        <div className="pane-resizer pane-resizer-right" role="separator" aria-label="调整导航栏宽度" onPointerDown={(event) => startPaneResize(event, "module")} />
      </aside>

      <aside className="workspace-pane" aria-label="当前模块侧栏">
        <button type="button" className="work-switch" onClick={openCreateWork}>
          <span className="work-avatar">{work?.title.at(0) ?? "新"}</span>
          <span>{work?.title ?? "新建作品"}</span>
          <Plus size={14} aria-hidden="true" />
        </button>

        <div className="work-list" aria-label="作品列表">
          {works.map((item) => (
            <div className="work-row-wrap" key={item.id}>
              <button
                type="button"
                className={item.id === work?.id ? "active" : ""}
                onContextMenu={(event) => {
                  event.preventDefault();
                  setWorkMenuId(item.id);
                  setChapterMenuId("");
                }}
                onClick={() => {
                  setActiveWorkId(item.id);
                  setDraftWork(item);
                  setSnapshot(null);
                  setSelectedChapterId("");
                  setSelectedRecordTitle("");
                  setWorkMenuId("");
                  setActionNotice(`已切换：${item.title}`);
                }}
              >
                <span>{item.title}</span>
                <small>{item.category} · {item.type}</small>
              </button>
              {workMenuId === item.id && (
                <div className="chapter-menu">
                  <button type="button" onClick={() => deleteWork(item.id)}>删除小说</button>
                </div>
              )}
            </div>
          ))}
        </div>

        <div className="workspace-head">
          <span>{activeModule.label}</span>
          <small>{sidebarRecords.length}</small>
          <button
            type="button"
            title={activeModule.id === "outline" ? "新增节点" : `新建${activeModule.label}`}
            disabled={!work}
            onClick={() => activeModule.id === "outline" ? addOutlineNode() : addModuleRecord()}
          >
            <Plus size={14} aria-hidden="true" />
          </button>
        </div>

        <label className="workspace-search">
          <span>搜索</span>
          <input value={recordSearch} onChange={(event) => setRecordSearch(event.target.value)} aria-label={`搜索${activeModule.label}`} />
        </label>

        <div className="workspace-list">
          {listRecords.map((record) => (
            <div className="workspace-row-wrap" key={record.title}>
              <button
                type="button"
                className={selectedRecordTitle === record.title || (!selectedRecordTitle && record.title === visibleRecords[0]?.title) ? "workspace-row active" : "workspace-row"}
                onContextMenu={(event) => {
                  event.preventDefault();
                  if (activeModule.id === "chapters" && record.meta !== "默认") {
                    setSelectedRecordTitle(record.title);
                    setSelectedChapterId(record.meta);
                    setChapterMenuId(record.meta);
                    setWorkMenuId("");
                  }
                }}
                onClick={() => {
                  setSelectedRecordTitle(record.title);
                  if (activeModule.id === "chapters") setSelectedChapterId(record.meta);
                  setChapterMenuId("");
                  setActionNotice(`已选中：${record.title}`);
                }}
              >
                <ActiveIcon size={15} aria-hidden="true" />
                <span>{record.title}</span>
              </button>
              {activeModule.id === "chapters" && record.meta !== "默认" && (
                <>
                  <button type="button" className="row-menu-button" onClick={() => {
                    setChapterMenuId(chapterMenuId === record.meta ? "" : record.meta);
                    setWorkMenuId("");
                  }} aria-label="章节菜单">⋯</button>
                  {chapterMenuId === record.meta && (
                    <div className="chapter-menu">
                      <button type="button" onClick={() => moveChapter(record.meta)}>移动到位置</button>
                      <button type="button" onClick={() => deleteChapter(record.meta)}>删除</button>
                      <button type="button" onClick={() => publishChapter(record.meta)}>发布</button>
                    </div>
                  )}
                </>
              )}
            </div>
          ))}
        </div>

        <button type="button" className="scope-button" onClick={() => selectModule(modules[0])}>
          <GitBranch size={15} aria-hidden="true" />
          全局
        </button>
        <div className="pane-resizer pane-resizer-right" role="separator" aria-label="调整作品栏宽度" onPointerDown={(event) => startPaneResize(event, "workspace")} />
      </aside>

      <section className="content-pane" aria-label={`${activeModule.label}内容区`}>
        <header className="work-header">
          <div>
            <span>{activeModule.group} / {activeModule.label}</span>
            <h1>{work?.title ?? "尚未创建作品"}</h1>
            <p>{work ? `${work.category} · ${work.type} · ${work.tags.join(" / ")}` : "先新建作品，再开始规划。"}</p>
          </div>
        </header>

        <article className="module-panel">
          <div className="module-title">
            <div>
              <h2>{activeModule.label}</h2>
              <p>{activeModule.description}</p>
            </div>
            <div className="module-actions">
              {activeModule.actions.map((action) => (
                <button type="button" key={action} onClick={() => runModuleAction(action)} disabled={running || !work}>
                  {action}
                </button>
              ))}
            </div>
          </div>

          {actionNotice && <p className="action-notice">{actionNotice}</p>}
          {renderModuleContent(
            activeModule,
            work,
            exportBundle,
            enabledAgents,
            setEnabledAgents,
            activeRecords,
            outlineBeats,
            updateOutlineBeat,
            runModuleAction,
            selectModuleById,
            roundtableTopic,
            setRoundtableTopic,
            roundtableRounds,
            roundtableBusy,
            runRoundtableRound,
            skitScene,
            setSkitScene,
            skitRoles,
            setSkitRoles,
            skitRounds,
            skitBusy,
            runSkitRound,
            roleplayName,
            setRoleplayName,
            roleplayProfile,
            setRoleplayProfile,
            roleplayInput,
            setRoleplayInput,
            roleplayMessages,
            roleplayBusy,
            runRoleplayMessage,
            selectedRecordTitle,
            selectedCharacter,
            characterEditorTab,
            setCharacterEditorTab,
            updateCharacter,
            () => setAvatarModalOpen(true),
            selectedChapter,
            updateChapter,
            createChapter,
            () => setShowInlineCharacter((value) => !value),
            showInlineCharacter,
            showChapterOutlineModal,
            setShowChapterOutlineModal,
            characters,
            relations,
            addRelation,
          )}
        </article>
      </section>

      <aside className="agent-pane">
        <div className="pane-resizer pane-resizer-left" role="separator" aria-label="调整智能体栏宽度" onPointerDown={(event) => startPaneResize(event, "agent")} />
        <AgentConversationPanel
          moduleLabel={activeModule.label}
          modelSetting={modelSettings[selectedAgent.id]}
          onModelChange={(model) => updateModelSetting(selectedAgent.id, { defaultModel: model })}
          onLoadModels={() => void loadAgentModels(selectedAgent.id)}
          messages={work ? selectedAgentMessages : []}
          chatInput={chatInput}
          setChatInput={setChatInput}
          chatBusy={chatBusy}
          sendAgentMessage={sendAgentMessage}
          options={work ? conversationOptions() : [{ label: "先新建作品", detail: "创建作品后再开始规划、写作和检查。", onSelect: openCreateWork }]}
          task={work ? assistantTask : null}
          disabled={!work}
          thinkingOpen={thinkingOpen}
          setThinkingOpen={setThinkingOpen}
        />
      </aside>

      {showCreate && (
        <div className="modal-backdrop" role="presentation">
          <section className="create-modal" role="dialog" aria-modal="true" aria-labelledby="create-title">
            <header>
              <h2 id="create-title">新建作品</h2>
              <button type="button" className="plain-button" onClick={() => setShowCreate(false)}>取消</button>
            </header>

            <div className="create-grid">
              <label className="cover-picker">
                {draftWork.coverUrl ? <img src={draftWork.coverUrl} alt="封面预览" /> : <Upload aria-hidden="true" />}
                <span>选择封面</span>
                <input
                  type="file"
                  accept="image/*"
                  onChange={(event) => {
                    const file = event.target.files?.[0];
                    if (file) setDraftWork({ ...draftWork, coverUrl: URL.createObjectURL(file) });
                  }}
                />
              </label>

              <div className="form-stack">
                <label>作品名称<input value={draftWork.title} onChange={(event) => setDraftWork({ ...draftWork, title: event.target.value })} /></label>
                <label>简介描述<textarea value={draftWork.intro} onChange={(event) => setDraftWork({ ...draftWork, intro: event.target.value })} /></label>
                <label>分类<select value={draftWork.category} onChange={(event) => setDraftWork({ ...draftWork, category: event.target.value })}>
                  <option>玄幻</option><option>都市</option><option>科幻</option><option>悬疑</option><option>言情</option>
                </select></label>
                <label>作品类型<select value={draftWork.type} onChange={(event) => setDraftWork({ ...draftWork, type: event.target.value as WorkType })}>
                  <option>原创</option><option>同人</option><option>二创</option><option>资料</option>
                </select></label>
                <label>标签<span className="tag-editor">
                  <input value={tagInput} onChange={(event) => setTagInput(event.target.value)} onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault();
                      addTag();
                    }
                  }} placeholder="输入后回车" />
                  <button type="button" onClick={addTag}>新增</button>
                </span></label>
                <div className="tags">
                  {draftWork.tags.map((tag) => (
                    <button type="button" key={tag} onClick={() => setDraftWork({ ...draftWork, tags: draftWork.tags.filter((item) => item !== tag) })}>
                      {tag}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <footer>
              <button type="button" className="plain-button" onClick={() => setShowCreate(false)}>取消</button>
              <button type="button" onClick={saveWork}>创建</button>
            </footer>
          </section>
        </div>
      )}

      {avatarModalOpen && selectedCharacter && (
        <div className="modal-backdrop" role="presentation">
          <section className="avatar-modal" role="dialog" aria-modal="true" aria-labelledby="avatar-title">
            <header>
              <h2 id="avatar-title">生成头像</h2>
              <button type="button" className="plain-button" onClick={() => setAvatarModalOpen(false)}>取消</button>
            </header>
            <div className="avatar-style-grid" role="radiogroup" aria-label="头像风格">
              {([
                ["movie", "电影感"],
                ["anime", "日漫"],
                ["fantasy", "东方幻想"],
                ["photo", "摄影"],
                ["custom", "自定义"],
              ] as Array<[AvatarStyle, string]>).map(([value, label]) => (
                <button type="button" className={avatarStyle === value ? "active" : ""} onClick={() => setAvatarStyle(value)} key={value}>
                  {label}
                </button>
              ))}
            </div>
            <label className="avatar-prompt">
              额外要求
              <textarea value={avatarPrompt} onChange={(event) => setAvatarPrompt(event.target.value)} placeholder="输入额外的封面要求，确认后发送给 AI。" />
            </label>
            <footer>
              <button type="button" className="plain-button" onClick={() => setAvatarModalOpen(false)}>取消</button>
              <button type="button" onClick={generateAvatar}>生成头像</button>
            </footer>
          </section>
        </div>
      )}

      {showAuditReport && (
        <div className="modal-backdrop" role="presentation">
          <section className="audit-modal" role="dialog" aria-modal="true" aria-labelledby="audit-title">
            <header>
              <span>内容审查</span>
              <button type="button" className="plain-button" onClick={() => setShowAuditReport(false)}>关闭</button>
            </header>
            <article>
              <h2 id="audit-title">审查报告</h2>
              <h3>1. 因果链: 10/10</h3>
              <strong>OK</strong>
              <ul>
                <li>开篇由差评触发情绪，主角动机清晰，能自然导向“重来一次”的转折。</li>
                <li>江然的行业记忆、写作挫败和 AI 工具线形成明确推进。</li>
              </ul>
              <h3>2. 角色一致性: 10/10</h3>
              <strong>OK</strong>
              <ul>
                <li>江然反应符合扑街作者设定：疲惫、敏感，但仍保持理性分析。</li>
                <li>人物台词没有跳出时代背景。</li>
              </ul>
              <h3>3. 时间线: 9/10</h3>
              <strong>OK → 一处提示</strong>
              <p>2015 年 AI 写作认知可以再压低一点，避免显得过早成熟。</p>
            </article>
          </section>
        </div>
      )}

      {showContinuityReport && (
        <div className="modal-backdrop" role="presentation">
          <section className="continuity-modal" role="dialog" aria-modal="true" aria-labelledby="continuity-title">
            <header>
              <span>编年史者</span>
              <button type="button" className="plain-button" onClick={() => setShowContinuityReport(false)}>关闭</button>
            </header>
            <article>
              <table>
                <thead><tr><th>来源</th><th>关系</th><th>目标</th><th>说明</th></tr></thead>
                <tbody>
                  <tr><td>江然</td><td>friend</td><td>刘磊</td><td>大学室友，上下铺</td></tr>
                  <tr><td>江然</td><td>active</td><td>男生宿舍</td><td>本章活动地点</td></tr>
                  <tr><td>宋知远</td><td>active</td><td>S市大学</td><td>研二在 NLP 实验室</td></tr>
                  <tr><td>本章</td><td>occurs</td><td>男生宿舍</td><td>核心场景</td></tr>
                </tbody>
              </table>
              <h2 id="continuity-title">✅ 连续性核对结果</h2>
              <ul>
                <li>角色一致性：目前无明显冲突，设定完整。</li>
                <li>关系一致性：江然与刘磊的室友关系可建立。</li>
                <li>时间线一致性：穿越点与章节时间清晰。</li>
                <li>伏笔追踪：2 个新线索已设为 planted 状态。</li>
              </ul>
            </article>
          </section>
        </div>
      )}

      {showSettings && (
        <div className="modal-backdrop settings-backdrop" role="presentation">
          <section className="settings-modal" role="dialog" aria-modal="true" aria-labelledby="settings-title">
            <header>
              <h2 id="settings-title">设置</h2>
              <button type="button" className="plain-button" onClick={() => setShowSettings(false)}>取消</button>
            </header>

            <div className="settings-layout">
              <nav className="settings-tabs" role="tablist" aria-label="设置页签">
                {settingsTabs.map((tab) => (
                  <button type="button" className={settingsTab === tab.id ? "active" : ""} onClick={() => setSettingsTab(tab.id)} key={tab.id}>
                    {tab.label}
                  </button>
                ))}
              </nav>

              <div className="settings-body">
                {settingsTab === "general" && (
                  <section className="settings-panel">
                    <h3>通用</h3>
                    <label>默认作品<input value={work?.title ?? ""} readOnly /></label>
                    <label><span>启动后打开上次作品</span><input type="checkbox" defaultChecked /></label>
                  </section>
                )}

                {settingsTab === "appearance" && (
                  <section className="settings-panel">
                    <h3>外观</h3>
                    <div className="style-options">
                      {[
                        ["warm", "米白"],
                        ["clean", "清爽"],
                        ["night", "夜间"],
                      ].map(([value, label]) => (
                        <button type="button" className={styleMode === value ? "active" : ""} onClick={() => selectStyleMode(value as StyleMode)} key={value}>
                          {label}
                        </button>
                      ))}
                    </div>
                  </section>
                )}

                {settingsTab === "editor" && (
                  <section className="settings-panel">
                    <h3>编辑器</h3>
                    <label>默认章节字数<input type="number" defaultValue={4500} /></label>
                    <label><span>自动保存草稿</span><input type="checkbox" defaultChecked /></label>
                    <label><span>显示章节结构提示</span><input type="checkbox" defaultChecked /></label>
                  </section>
                )}

                {settingsTab === "assistant" && (
                  <section className="settings-panel">
                    <h3>AI 助手</h3>
                    <label><span>允许 Agent 主动提出整理建议</span><input type="checkbox" defaultChecked /></label>
                    <label><span>运行前需要人工确认</span><input type="checkbox" defaultChecked /></label>
                  </section>
                )}

                {settingsTab === "provider" && (
                  <section className="settings-panel">
                    <h3>AI 供应商</h3>
                    <div className="provider-list">
                      {baseUrlPresets.map((preset) => <p key={preset.url}><strong>{preset.name}</strong><span>{preset.url}</span></p>)}
                    </div>
                    <label>名称<input value={providerName} onChange={(event) => setProviderName(event.target.value)} placeholder="自定义供应商" /></label>
                    <label>接口地址<input value={providerUrl} onChange={(event) => setProviderUrl(event.target.value)} placeholder="https://example.com/v1" /></label>
                    <button type="button" onClick={addProviderPresetFromSettings}>加入供应商</button>
                  </section>
                )}

                {settingsTab === "model" && (
                  <div className="agent-api-list">
                    {agentSpecs.map((agent) => {
                      const setting = modelSettings[agent.id];
                      return (
                        <section className="agent-api-row" key={agent.id}>
                          <header>
                            <strong>{agent.title}</strong>
                            <span>{agent.responsibilities.join("、")}</span>
                          </header>
                          <label>
                            API key
                            <input type="password" value={setting.apiKey} onChange={(event) => updateModelSetting(agent.id, { apiKey: event.target.value, status: "idle", error: "" })} placeholder="sk-..." />
                          </label>
                          <label className="base-url-field">
                            模型接口
                            <select value={baseUrlPresets.some((preset) => preset.url === setting.baseUrl.trim()) ? setting.baseUrl.trim() : ""} onChange={(event) => setAgentBaseUrl(agent.id, event.target.value)}>
                              <option value="">选择预设接口</option>
                              {baseUrlPresets.map((preset) => <option value={preset.url} key={`${preset.name}-${preset.url}`}>{preset.name} · {preset.url}</option>)}
                            </select>
                            <input value={setting.baseUrl} onChange={(event) => setAgentBaseUrl(agent.id, event.target.value)} placeholder="https://api.openai.com/v1" />
                            <span className="base-url-actions">
                              <button type="button" onClick={() => void copyBaseUrl(setting.baseUrl)} disabled={!setting.baseUrl.trim()}>复制</button>
                              <button type="button" onClick={() => void pasteBaseUrl(agent.id)}>粘贴</button>
                              <button type="button" onClick={() => addBaseUrlPreset(agent.id, setting.baseUrl)} disabled={!setting.baseUrl.trim()}>加入预设</button>
                            </span>
                          </label>
                          <div className="model-picker">
                            <button type="button" onClick={() => void loadAgentModels(agent.id)} disabled={!setting.apiKey.trim() || setting.status === "loading"}>
                              {setting.status === "loading" ? "读取中" : "读取模型"}
                            </button>
                            <select value={setting.defaultModel} onChange={(event) => updateModelSetting(agent.id, { defaultModel: event.target.value })} disabled={!setting.models.length}>
                              <option value="">默认模型</option>
                              {setting.models.map((model) => <option value={model} key={model}>{model}</option>)}
                            </select>
                          </div>
                          {setting.error && <p>{setting.error}</p>}
                        </section>
                      );
                    })}
                  </div>
                )}

                {settingsTab === "dream" && (
                  <section className="settings-panel dream-panel">
                    <h3>梦境</h3>
                    <p>定期整理创作记忆，合并重复内容，提炼重要设定，移除过时信息。AI 只提出整理结果，由你决定是否采纳。</p>
                    <label><span>记忆整理</span><input type="checkbox" checked={dreamSettings.enabled} onChange={(event) => updateDreamSettings({ enabled: event.target.checked })} /></label>
                    <label>整理间隔（小时）<input type="number" min={1} value={dreamSettings.intervalHours} onChange={(event) => updateDreamSettings({ intervalHours: Number(event.target.value) || 1 })} /></label>
                    <label>整理模型<select value={dreamSettings.modelAgentId} onChange={(event) => updateDreamSettings({ modelAgentId: event.target.value as AgentId })}>
                      {agentSpecs.map((agent) => <option value={agent.id} key={agent.id}>{agent.title}</option>)}
                    </select></label>
                    <button type="button" onClick={runDreamTidy}>立即整理</button>
                    <div className="dream-summary">
                      <strong>上次运行</strong>
                      <span>{dreamSettings.lastRun || "从未运行"}</span>
                      <p>{dreamSettings.lastSummary}</p>
                    </div>
                  </section>
                )}

                {settingsTab === "usage" && (
                  <section className="settings-panel">
                    <h3>用量</h3>
                    <div className="settings-stats"><p><strong>{agentMessages.length}</strong><span>对话消息</span></p><p><strong>{artifacts.length}</strong><span>产物记录</span></p></div>
                  </section>
                )}

                {settingsTab === "storage" && (
                  <section className="settings-panel">
                    <h3>存储</h3>
                    <p>当前版本使用浏览器 localStorage 保存作品、模型配置、界面宽度和梦境设置。</p>
                    <button type="button" onClick={() => setActionNotice("存储检查完成：本地数据可用")}>检查本地存储</button>
                  </section>
                )}

                {settingsTab === "about" && (
                  <section className="settings-panel">
                    <h3>关于</h3>
                    <p>AI Novel Factory 是面向长篇小说的本地 Agent 创作工作台。</p>
                    <p>版本：0.1.0</p>
                  </section>
                )}
              </div>
            </div>

            <footer>
              <button type="button" className="plain-button" onClick={() => setShowSettings(false)}>取消</button>
              <button type="button" onClick={() => setShowSettings(false)}>保存</button>
            </footer>
          </section>
        </div>
      )}
    </main>
  );
}

function moduleDef(
  id: string,
  group: ModuleGroup,
  label: string,
  icon: typeof BookOpen,
  description: string,
  actions: string[],
  agentIds: AgentId[],
  records: WorkspaceModule["records"],
): WorkspaceModule {
  return { id, group, label, icon, description, actions, agentIds, records };
}

function renderModuleContent(
  module: WorkspaceModule,
  work: WorkForm | null,
  exportBundle: ExportBundlePayload | undefined,
  enabledAgents: Record<AgentId, boolean>,
  setEnabledAgents: (next: Record<AgentId, boolean>) => void,
  records: WorkspaceModule["records"],
  outlineBeats: OutlineBeat[],
  updateOutlineBeat: (target: OutlineBeat, patch: Partial<OutlineBeat>) => void,
  runModuleAction: (action: string) => void,
  selectModuleById: (moduleId: string) => void,
  roundtableTopic: string,
  setRoundtableTopic: (topic: string) => void,
  roundtableRounds: RoundtableRound[],
  roundtableBusy: boolean,
  runRoundtableRound: () => void,
  skitScene: string,
  setSkitScene: (scene: string) => void,
  skitRoles: string,
  setSkitRoles: (roles: string) => void,
  skitRounds: SkitRound[],
  skitBusy: boolean,
  runSkitRound: () => void,
  roleplayName: string,
  setRoleplayName: (name: string) => void,
  roleplayProfile: string,
  setRoleplayProfile: (profile: string) => void,
  roleplayInput: string,
  setRoleplayInput: (input: string) => void,
  roleplayMessages: RoleplayMessage[],
  roleplayBusy: boolean,
  runRoleplayMessage: () => void,
  selectedRecordTitle: string,
  selectedCharacter: CharacterProfile,
  characterEditorTab: CharacterEditorTab,
  setCharacterEditorTab: (tab: CharacterEditorTab) => void,
  updateCharacter: (id: string, patch: Partial<CharacterProfile>) => void,
  openAvatarModal: () => void,
  selectedChapter: ChapterDraft | undefined,
  updateChapter: (id: string, patch: Partial<ChapterDraft>) => void,
  createChapter: () => void,
  toggleInlineCharacter: () => void,
  showInlineCharacter: boolean,
  showChapterOutlineModal: boolean,
  setShowChapterOutlineModal: (open: boolean) => void,
  characters: CharacterProfile[],
  relations: EntityRelation[],
  addRelation: () => void,
) {
  if (!work) return <EmptyState title="还没有作品" body="点击左侧“新建作品”，填写名称、封面、简介、分类、类型和标签。" />;

  if (module.id === "overview") {
    return (
      <div className="overview-home">
        <section className="writing-hero">
          <span>继续写作</span>
          <h3>新章节空空如也，从一句话开始吧。</h3>
          <p>慢慢写，让故事自然生长。</p>
          <div>
            <button type="button" onClick={() => runModuleAction("继续创作")}>开始写第 1 章</button>
            <button type="button" onClick={() => selectModuleById("outline")}>查看大纲</button>
            <button type="button" onClick={() => selectModuleById("chapters")}>打开草稿</button>
          </div>
        </section>

        <section className="work-summary-card">
          <h3>作品简介</h3>
          <div>
            <div className="cover">
              {work.coverUrl ? <img src={work.coverUrl} alt={`${work.title}封面`} /> : <BookOpen size={24} aria-hidden="true" />}
            </div>
            <p>{work.intro}</p>
          </div>
          <footer>
            <span>章节 2</span>
            <span>设定 3</span>
            <span>人物 2</span>
            <span>伏笔 1</span>
          </footer>
        </section>

        <section className="inspiration-panel">
          <header>
            <h3>创作片段 / 灵感便签</h3>
            <button type="button" onClick={() => selectModuleById("materials")}>查看更多</button>
          </header>
          <div className="inspiration-grid">
            {records.slice(0, 3).map((record) => (
              <article key={record.title}>
                <strong>{record.title}</strong>
                <p>{record.body}</p>
              </article>
            ))}
          </div>
        </section>
      </div>
    );
  }

  if (module.id === "relationship-graph") {
    const inspectedEntity = "刘磊";
    const inspectedRelations = relations.filter((relation) => (
      relation.source === inspectedEntity || relation.target === inspectedEntity
    ));
    const activeRelationCount = inspectedRelations.filter((relation) => relation.source === inspectedEntity).length;
    const passiveRelationCount = inspectedRelations.length - activeRelationCount;

    return (
      <div className="relationship-board">
        <header className="relationship-toolbar">
          <button type="button" className="active">关系视图</button>
          <select defaultValue="3">
            <option value="3">3跳</option>
            <option value="2">2跳</option>
            <option value="1">1跳</option>
          </select>
          <select defaultValue="all">
            <option value="all">全部</option>
            <option value="people">人物</option>
            <option value="forces">势力</option>
          </select>
          <label><input type="checkbox" defaultChecked /> 显示外链</label>
          <label><input type="checkbox" defaultChecked /> 显示方向</label>
          <button type="button">重置</button>
        </header>

        <section className="relationship-layout">
          <div className="relationship-canvas">
            {relations.length ? (
              <div className="relation-lines">
                {relations.map((relation) => (
                  <article key={relation.id}>
                    <strong>{relation.source}</strong>
                    <span>{relation.relation}</span>
                    <strong>{relation.target}</strong>
                    <p>{relation.note}</p>
                  </article>
                ))}
              </div>
            ) : (
              <div className="relation-empty">
                <GitBranch size={34} aria-hidden="true" />
                <h3>暂无关系数据</h3>
                <button type="button" onClick={addRelation}>添加关系</button>
              </div>
            )}
          </div>

          <aside className="relation-inspector">
            <header>
              <strong>{inspectedEntity} 的关系</strong>
              <button type="button">×</button>
            </header>
            <p>全部 {inspectedRelations.length} · 主动关系 {activeRelationCount} · 被动关系 {passiveRelationCount}</p>
            {inspectedRelations.length ? (
              <ul>
                {inspectedRelations.map((relation) => (
                  <li key={relation.id}>
                    <strong>{relation.source}</strong>
                    <span>{relation.relation}</span>
                    <strong>{relation.target}</strong>
                  </li>
                ))}
              </ul>
            ) : null}
            <button type="button" onClick={addRelation}>添加关系</button>
          </aside>
        </section>

        <section className="entity-list">
          <h3>实体关系管理</h3>
          <div>
            <button type="button" className="active">全部 {characters.length}</button>
            <button type="button">角色 {characters.length}</button>
            <button type="button">势力 {relations.length}</button>
          </div>
          {characters.map((character) => (
            <article key={character.id}>
              <span>{character.name.slice(0, 1)}</span>
              <strong>{character.name}</strong>
              <small>{character.role}</small>
            </article>
          ))}
        </section>
      </div>
    );
  }

  if (module.id === "chapters") {
    if (!selectedChapter) {
      return (
        <section className="chapter-empty">
          <BookOpen size={30} aria-hidden="true" />
          <h2>还没有选中章节</h2>
          <p>先创建第一章。</p>
          <button type="button" onClick={createChapter}><Plus size={15} aria-hidden="true" /> 新增章节</button>
        </section>
      );
    }

    return (
      <div className="chapter-editor">
        <header className="chapter-editor-head">
          <div>
            <span>{selectedChapter.title.match(/^第\d+章/)?.[0] ?? "章节"}</span>
            <button type="button">{selectedChapter.status}</button>
            <h2>{selectedChapter.title.replace(/^第\d+章\s*/, "")}</h2>
          </div>
          <button type="button" onClick={toggleInlineCharacter}>插入人物卡</button>
        </header>

        <section className="chapter-outline-panel">
          <header>
            <button type="button" className="chapter-outline-chip">章节大纲</button>
            <button type="button" aria-label="展开章节大纲" onClick={() => setShowChapterOutlineModal(true)}>⛶</button>
          </header>
          <div className="editor-toolbar" aria-label="文本工具栏">
            <button type="button">B</button>
            <button type="button">I</button>
            <button type="button">S</button>
            <button type="button">H</button>
            <button type="button">≡</button>
            <button type="button">❞</button>
          </div>
          <textarea
            value={selectedChapter.outline}
            onChange={(event) => updateChapter(selectedChapter.id, { outline: event.target.value, outlineApproved: false, status: "细纲" })}
            placeholder="记录这章大纲的主内容、目标、冲突、伏笔和钩子兑现。"
          />
        </section>

        <section className="chapter-body-panel">
          {selectedChapter.content ? (
            <div className="chapter-prose" aria-label="正文内容">
              {renderCharacterMentions(selectedChapter.content, characters)}
            </div>
          ) : (
            <p>在这里开始写正文。</p>
          )}
          <details className="chapter-source">
            <summary>编辑正文</summary>
            <textarea
              value={selectedChapter.content}
              onChange={(event) => updateChapter(selectedChapter.id, {
                content: event.target.value,
                wordCount: event.target.value.length,
              })}
            />
          </details>
        </section>

        {showChapterOutlineModal && (
          <div className="modal-backdrop" role="presentation">
            <section className="chapter-outline-modal" role="dialog" aria-modal="true" aria-label="章节大纲">
              <header>
                <h2>章节大纲</h2>
                <button type="button" className="plain-button" onClick={() => setShowChapterOutlineModal(false)}>×</button>
              </header>
              <div className="editor-toolbar" aria-label="文本工具栏">
                <button type="button">B</button>
                <button type="button">I</button>
                <button type="button">S</button>
                <button type="button">H</button>
                <button type="button">≡</button>
                <button type="button">❞</button>
              </div>
              <textarea
                value={selectedChapter.outline}
                onChange={(event) => updateChapter(selectedChapter.id, { outline: event.target.value, outlineApproved: false, status: "细纲" })}
                placeholder="记录这章大纲的主内容、目标、冲突、伏笔和钩子兑现。"
              />
            </section>
          </div>
        )}
        {showInlineCharacter && (
          <article className="inline-character-card">
            <div className="mini-avatar">江</div>
            <div>
              <strong>江然</strong>
              <span>主角</span>
              <p>23岁，计算机系大三学生。保留 2015-2025 年完整 AI 行业记忆。</p>
            </div>
          </article>
        )}
      </div>
    );
  }

  if (module.id === "characters") {
    if (!selectedCharacter) {
      return <EmptyState title="还没有人物" body="当前作品已删除或还没有人物卡。新建作品后再创建人物。" />;
    }

    const editorField = characterEditorTab === "bio" ? "bio" : "status";
    return (
      <div className="character-board">
        <section className="character-fields">
          <label>名称<input value={selectedCharacter.name} onChange={(event) => updateCharacter(selectedCharacter.id, { name: event.target.value })} /></label>
          <label>定位<select value={selectedCharacter.role} onChange={(event) => updateCharacter(selectedCharacter.id, { role: event.target.value })}>
            <option>主角</option>
            <option>配角</option>
            <option>反派</option>
            <option>路人</option>
          </select></label>
          <label>性别<select value={selectedCharacter.gender} onChange={(event) => updateCharacter(selectedCharacter.id, { gender: event.target.value })}>
            <option>男</option>
            <option>女</option>
            <option>未知</option>
          </select></label>
        </section>

        <section className="character-media">
          <div className="avatar-box">
            <h3>头像</h3>
            <div className="avatar-preview">
              {selectedCharacter.avatarUrl ? <img src={selectedCharacter.avatarUrl} alt={`${selectedCharacter.name}头像`} /> : <Bot size={42} aria-hidden="true" />}
            </div>
            <button type="button">选择头像图片</button>
            <button type="button" onClick={openAvatarModal}>生成头像</button>
          </div>

          <div className="gallery-box">
            <h3>照片集</h3>
            <div className="gallery-strip">
              {selectedCharacter.gallery.length ? selectedCharacter.gallery.map((url) => (
                <img src={url} alt={`${selectedCharacter.name}照片`} key={url} />
              )) : (
                <>
                  <span />
                  <button type="button" onClick={openAvatarModal}><Plus size={22} aria-hidden="true" /></button>
                </>
              )}
            </div>
          </div>
        </section>

        <section className="character-entry">
          <label>首次出场章节<input value={selectedCharacter.firstChapter} onChange={(event) => updateCharacter(selectedCharacter.id, { firstChapter: event.target.value })} /></label>
          <button type="button" aria-label="搜索章节">⌕</button>
        </section>

        <section className="character-editor">
          <div className="character-tabs" role="tablist" aria-label="人物文本">
            <button type="button" role="tab" aria-selected={characterEditorTab === "bio"} className={characterEditorTab === "bio" ? "active" : ""} onClick={() => setCharacterEditorTab("bio")}>人物小传</button>
            <button type="button" role="tab" aria-selected={characterEditorTab === "status"} className={characterEditorTab === "status" ? "active" : ""} onClick={() => setCharacterEditorTab("status")}>人物当前状态</button>
          </div>
          <div className="editor-toolbar" aria-label="文本工具栏">
            <button type="button">B</button>
            <button type="button">I</button>
            <button type="button">S</button>
            <button type="button">H</button>
            <button type="button">≡</button>
            <button type="button">❞</button>
          </div>
          <textarea
            value={selectedCharacter[editorField]}
            onChange={(event) => updateCharacter(selectedCharacter.id, { [editorField]: event.target.value })}
          />
        </section>
      </div>
    );
  }

  if (module.id === "outline") {
    const selected = selectedRecordTitle || "主线";
    const isGlobal = selected === "主线";
    const beats = isGlobal ? outlineBeats.slice(0, 5) : outlineBeats.filter((beat) => beat.volume === selected);
    return (
      <div className="outline-board">
        <header className="outline-board-head">
          <div>
            <h2>{isGlobal ? "全局大纲时间轴" : selected}</h2>
            <p>{isGlobal ? "按章节节奏对比所有大纲，快速定位支持查看。" : "时间线节拍"}</p>
          </div>
          <div className="outline-meta">
            <span>大纲 5</span>
            <span>时间线节拍 30</span>
            <span>章节 565</span>
          </div>
        </header>

        {isGlobal ? (
          <div className="global-timeline">
            <div className="timeline-scale" aria-hidden="true">
              <span>全局</span>
              <div>起点</div>
            </div>
            {outlineRecords.slice(1).map((record) => (
              <section key={record.title}>
                <h3>{record.title}</h3>
                <div>
                  {outlineBeats.filter((beat) => beat.volume === record.title).map((beat) => (
                    <button type="button" className={`beat-card ${beat.tone}`} key={`${beat.volume}-${beat.beat}-${beat.title}`}>
                      <strong>{beat.beat}：{beat.title}</strong>
                      <span>{beat.words}</span>
                    </button>
                  ))}
                </div>
              </section>
            ))}
          </div>
        ) : (
          <div className="volume-timeline">
            {beats.map((beat, index) => (
              <article className={`timeline-node ${index % 2 ? "left" : "right"}`} key={`${beat.beat}-${beat.title}`}>
                <span className="node-dot" />
                <div className={`beat-detail ${beat.tone}`}>
                  <header>
                    <span>节拍 {index + 4}</span>
                    <em>待开始</em>
                    <input aria-label="节点章节范围" value={beat.words} onChange={(event) => updateOutlineBeat(beat, { words: event.target.value })} />
                  </header>
                  <label>
                    <span>{beat.beat}</span>
                    <input aria-label="节点标题" value={beat.title} onChange={(event) => updateOutlineBeat(beat, { title: event.target.value })} />
                  </label>
                  <textarea
                    aria-label="节点说明"
                    value={beat.summary ?? "2025 年初，主角拿到一个重要线索，重新整理一条隐藏已久的创作脉络，打开后续剧情的关键入口。"}
                    onChange={(event) => updateOutlineBeat(beat, { summary: event.target.value })}
                  />
                </div>
              </article>
            ))}
          </div>
        )}
      </div>
    );
  }

  if (module.id === "agent-planning") {
    return (
      <div className="planning-list">
        {agentSpecs.map((agent, index) => (
          <label key={agent.id}>
            <input
              type="checkbox"
              checked={enabledAgents[agent.id]}
              onChange={(event) => setEnabledAgents({ ...enabledAgents, [agent.id]: event.target.checked })}
            />
            <span>{index + 1}</span>
            <strong>{agent.name}</strong>
            <em>{agent.title}</em>
          </label>
        ))}
      </div>
    );
  }

  if (module.id === "roundtable") {
    return (
      <div className="roundtable-board">
        <section className="roundtable-topic">
          <span>讨论主题</span>
          <input value={roundtableTopic} onChange={(event) => setRoundtableTopic(event.target.value)} placeholder="输入你想让多个 Agent 讨论的问题" />
          <button type="button" onClick={() => void runRoundtableRound()} disabled={!roundtableTopic.trim() || roundtableBusy}>
            {roundtableBusy ? "讨论中" : "添加一轮"}
          </button>
          <button type="button" onClick={() => selectModuleById("chapters")}>切换到写作模式</button>
        </section>

        {roundtableRounds.length ? (
          <div className="roundtable-rounds">
            {roundtableRounds.map((round, index) => (
              <section className="roundtable-round" key={round.id}>
                <header>
                  <strong>第 {index + 1} 轮</strong>
                  <span>{round.topic}</span>
                </header>
                {round.replies.map((reply) => (
                  <article key={`${round.id}-${reply.agentId}`}>
                    <strong>{reply.title}</strong>
                    <p>{reply.text}</p>
                  </article>
                ))}
              </section>
            ))}
          </div>
        ) : (
          <EmptyState title="还没有圆桌讨论" body="输入议题后添加一轮，启用的 Agent 会分别给出观点。" />
        )}
      </div>
    );
  }

  if (module.id === "skit") {
    return (
      <div className="skit-board">
        <section className="skit-controls">
          <label>场景描述<textarea value={skitScene} onChange={(event) => setSkitScene(event.target.value)} /></label>
          <label>登场角色<input value={skitRoles} onChange={(event) => setSkitRoles(event.target.value)} /></label>
          <button type="button" onClick={() => void runSkitRound()} disabled={!skitScene.trim() || !skitRoles.trim() || skitBusy}>
            {skitBusy ? "表演中" : "添加一轮"}
          </button>
          <button type="button" onClick={() => selectModuleById("chapters")}>切换到写作模式</button>
        </section>

        {skitRounds.length ? (
          <div className="skit-rounds">
            {skitRounds.map((round, index) => (
              <section className="skit-round" key={round.id}>
                <header>
                  <strong>第 {index + 1} 轮</strong>
                  <span>{round.roles}</span>
                </header>
                <p className="skit-scene">{round.scene}</p>
                {round.replies.map((reply) => (
                  <article key={`${round.id}-${reply.agentId}`}>
                    <strong>{reply.title}</strong>
                    <p>{reply.text}</p>
                  </article>
                ))}
              </section>
            ))}
          </div>
        ) : (
          <EmptyState title="还没有小剧场" body="设定角色和场景后添加一轮，让 Agent 代入表演。" />
        )}
      </div>
    );
  }

  if (module.id === "roleplay") {
    return (
      <div className="roleplay-board">
        <section className="roleplay-profile">
          <label>角色名<input value={roleplayName} onChange={(event) => setRoleplayName(event.target.value)} /></label>
          <label>人物设定<textarea value={roleplayProfile} onChange={(event) => setRoleplayProfile(event.target.value)} /></label>
        </section>

        <section className="roleplay-chat">
          {roleplayMessages.length ? (
            <div className="roleplay-log">
              {roleplayMessages.map((message, index) => (
                <p className={message.role} key={`${message.text}-${index}`}>
                  <strong>{message.role === "character" ? roleplayName : "你"}</strong>
                  {message.text}
                </p>
              ))}
            </div>
          ) : (
            <EmptyState title="还没有开始对话" body="补全角色设定后，用一句话打开角色的声音。" />
          )}
          <div className="roleplay-input">
            <textarea value={roleplayInput} onChange={(event) => setRoleplayInput(event.target.value)} placeholder={`与 ${roleplayName || "角色"} 对话...`} />
            <button type="button" onClick={() => void runRoleplayMessage()} disabled={!roleplayName.trim() || !roleplayProfile.trim() || !roleplayInput.trim() || roleplayBusy}>
              {roleplayBusy ? "回复中" : "发送"}
            </button>
          </div>
        </section>
      </div>
    );
  }

  if (module.id === "agent-skills") {
    return (
      <div className="record-list">
        {agentSpecs.map((agent) => (
          <section key={agent.id}>
            <h3>{agent.name} {agent.title}</h3>
            <p>输入：{agent.inputs.join(", ")}</p>
            <p>输出：{agent.outputs.join(", ")}</p>
          </section>
        ))}
      </div>
    );
  }

  if (exportBundle && module.id === "chapters") {
    return <pre className="chapter-output">{exportBundle.content}</pre>;
  }

  if (!records.length) return <EmptyState title={`${module.label}暂无内容`} body="先用上方动作创建第一条记录，后续再接入真实存储。" />;

  return (
    <div className="record-list">
      {records.map((record) => (
        <section key={record.title}>
          <h3>{record.title}</h3>
          <span>{record.meta}</span>
          <p>{record.body}</p>
        </section>
      ))}
    </div>
  );
}

function OutlineAgentPanel({
  tasks,
  setTasks,
  chatInput,
  setChatInput,
  chatBusy,
  sendAgentMessage,
  selectedAgent,
}: {
  tasks: OutlineTask[];
  setTasks: (tasks: OutlineTask[]) => void;
  chatInput: string;
  setChatInput: (value: string) => void;
  chatBusy: boolean;
  sendAgentMessage: () => void;
  selectedAgent: AgentSpec;
}) {
  const doneCount = tasks.filter((task) => task.done).length;
  return (
    <>
      <section className="agent-card outline-task-card">
        <header>
          <FileText size={18} aria-hidden="true" />
          <div>
            <strong>任务列表</strong>
            <span>{doneCount}/{tasks.length}</span>
          </div>
        </header>
        <div className="outline-task-list">
          {tasks.map((task) => (
            <label key={task.id} className={task.done ? "done" : ""}>
              <input
                type="checkbox"
                checked={task.done}
                onChange={(event) => setTasks(tasks.map((item) => item.id === task.id ? { ...item, done: event.target.checked } : item))}
              />
              <span>
                <strong>{task.title}</strong>
                <small>{task.detail}</small>
              </span>
            </label>
          ))}
        </div>
      </section>

      <section className="agent-card outline-agent-step">
        <button type="button">
          <Check size={15} aria-hidden="true" />
          智能体核查 <span>已完成</span>
        </button>
        <button type="button">
          <Bot size={15} aria-hidden="true" />
          构思过程
        </button>
      </section>

      <section className="agent-card chat-card outline-chat">
        <div className="chat-head">
          <Bot size={18} aria-hidden="true" />
          <strong>{selectedAgent.title}</strong>
        </div>
        <p className="outline-chat-note">把大纲节点拆成节拍、冲突和章节任务。</p>
        <textarea
          value={chatInput}
          onChange={(event) => setChatInput(event.target.value)}
          placeholder="让大纲 Agent 调整节拍、卷纲或任务..."
        />
        <button type="button" onClick={() => void sendAgentMessage()} disabled={!chatInput.trim() || chatBusy}>
          <MessageSquare size={15} aria-hidden="true" /> {chatBusy ? "发送中" : "发送"}
        </button>
      </section>
    </>
  );
}

function AgentConversationPanel({
  moduleLabel,
  modelSetting,
  onModelChange,
  onLoadModels,
  messages,
  chatInput,
  setChatInput,
  chatBusy,
  sendAgentMessage,
  options,
  task,
  disabled = false,
  thinkingOpen,
  setThinkingOpen,
}: {
  moduleLabel: string;
  modelSetting: AgentModelSetting;
  onModelChange: (model: string) => void;
  onLoadModels: () => void;
  messages: AgentMessage[];
  chatInput: string;
  setChatInput: (value: string) => void;
  chatBusy: boolean;
  sendAgentMessage: () => void;
  options: ConversationOption[];
  task: AssistantTask | null;
  disabled?: boolean;
  thinkingOpen: boolean;
  setThinkingOpen: (open: boolean) => void;
}) {
  const modelOptions = Array.from(new Set([modelSetting.defaultModel, ...modelSetting.models].filter(Boolean)));

  return (
    <section className="agent-card chat-card unified-chat-card">
      <div className="chat-head">
        <Bot size={18} aria-hidden="true" />
        <strong>{moduleLabel}创作助手</strong>
      </div>
      <div className="chat-flow">
        {task && (
          <section className="assistant-task-card">
            <header>
              <div>
                <strong>{task.title}</strong>
                <span>{task.status === "running" ? "进行中" : task.status === "done" ? "已完成" : "失败"}</span>
              </div>
              <button type="button" onClick={() => setThinkingOpen(!thinkingOpen)}>
                推理过程 {thinkingOpen ? "收起" : "展开"}
              </button>
            </header>
            {thinkingOpen && <div className="thinking-box">{task.thinking}</div>}
            <ol className="assistant-step-list">
              {task.steps.map((step) => (
                <li className={step.status} key={step.title}>
                  <Check size={14} aria-hidden="true" />
                  <span>{step.title}</span>
                  <small>{step.status === "running" ? "进行中" : step.status === "done" ? "已完成" : "待处理"}</small>
                </li>
              ))}
            </ol>
          </section>
        )}
        {messages.length ? (
          <div className="chat-log">
            {messages.map((message, index) => (
              <p className={message.role} key={`${message.text}-${index}`}>{message.text}</p>
            ))}
          </div>
        ) : (
          <div className="chat-empty compact-chat-empty">
            <div className="chat-illustration"><BookOpen size={38} aria-hidden="true" /></div>
            <h2>你可以这样开始</h2>
            <div className="question-options">
              {options.map((option) => (
                <button type="button" onClick={option.onSelect} key={option.label}>
                  <strong>{option.label}</strong>
                  <small>{option.detail}</small>
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
      <div className="chat-input-dock">
        {modelSetting.status === "error" && <p className="chat-model-error">{modelSetting.error}</p>}
        <textarea
          value={chatInput}
          onChange={(event) => setChatInput(event.target.value)}
          placeholder={disabled ? "先新建作品，再开始对话..." : `对 ${moduleLabel}助手提要求...`}
          disabled={disabled}
        />
        <div className="chat-model-row">
          <select value={modelSetting.defaultModel} onChange={(event) => onModelChange(event.target.value)} disabled={!modelOptions.length || modelSetting.status === "loading"} aria-label="切换对话模型">
            <option value="">选择模型</option>
            {modelOptions.map((model) => <option value={model} key={model}>{model}</option>)}
          </select>
          <button type="button" onClick={onLoadModels} disabled={!modelSetting.apiKey.trim() || modelSetting.status === "loading"}>
            {modelSetting.status === "loading" ? "读取中" : "读取"}
          </button>
          <button type="button" onClick={() => void sendAgentMessage()} disabled={disabled || !chatInput.trim() || chatBusy} aria-label="发送">
            <MessageSquare size={15} aria-hidden="true" /> {chatBusy ? "发送中" : "发送"}
          </button>
        </div>
      </div>
    </section>
  );
}

function CharacterAgentPanel({
  character,
  avatarStatus,
  openAvatarModal,
}: {
  character: CharacterProfile;
  avatarStatus: string;
  openAvatarModal: () => void;
}) {
  return (
    <>
      <section className="agent-card character-agent-preview">
        <header>
          <Bot size={18} aria-hidden="true" />
          <div>
            <strong>Avatar portrait</strong>
            <span>Mirroria · deepseek-v4-flash</span>
          </div>
        </header>
        <div className="avatar-result">
          {character.avatarUrl ? <img src={character.avatarUrl} alt={`${character.name}头像`} /> : <Bot size={46} aria-hidden="true" />}
        </div>
        <button type="button" onClick={openAvatarModal}>设为头像</button>
      </section>

      <section className="agent-card outline-agent-step">
        <button type="button"><Check size={15} aria-hidden="true" /> 生成头像 <span>{character.avatarUrl ? "已完成" : "待处理"}</span></button>
        <button type="button"><Check size={15} aria-hidden="true" /> 写入人物 <span>{character.name}</span></button>
        <button type="button"><Bot size={15} aria-hidden="true" /> 构思过程</button>
      </section>

      <section className="agent-card">
        <h2>执行结果</h2>
        <p>{avatarStatus || `等待为 ${character.name} 生成头像。`}</p>
      </section>
    </>
  );
}

function ChapterAgentPanel({
  chapter,
  tasks,
  setTasks,
  createChapter,
  generateOutline,
  approveOutline,
  generateBody,
  openAudit,
  acceptAll,
}: {
  chapter: ChapterDraft | undefined;
  tasks: ChapterTask[];
  setTasks: (tasks: ChapterTask[]) => void;
  createChapter: () => void;
  generateOutline: () => void;
  approveOutline: () => void;
  generateBody: () => void;
  openAudit: () => void;
  acceptAll: () => void;
}) {
  if (!chapter) {
    return (
      <section className="agent-card chapter-assistant-empty">
        <div className="chat-illustration"><BookOpen size={46} aria-hidden="true" /></div>
        <h2>慢慢写，我会陪你一起整理灵感与情节。</h2>
        <button type="button" onClick={createChapter}>开始写第一章</button>
        <button type="button">梳理设定一致性</button>
        <button type="button">规划今天的工作</button>
      </section>
    );
  }

  return (
    <>
      <section className="agent-card chapter-task-card">
        <header>
          <FileText size={18} aria-hidden="true" />
          <div>
            <strong>任务列表</strong>
            <span>{tasks.filter((task) => task.status === "done").length}/{tasks.length}</span>
          </div>
        </header>
        <div className="chapter-task-list">
          {tasks.map((task) => (
            <label key={task.id} className={task.status}>
              <input
                type="checkbox"
                checked={task.status === "done"}
                onChange={(event) => setTasks(tasks.map((item) => item.id === task.id ? { ...item, status: event.target.checked ? "done" : "pending" } : item))}
              />
              <span>
                <strong>{task.title}</strong>
                <small>{task.detail}</small>
              </span>
            </label>
          ))}
        </div>
      </section>

      <section className="agent-card chapter-progress-card">
        <p>{chapter.outlineApproved ? "细纲已确认，可以进入正文撰写。" : "先写章节细纲，用户确认后再写正文。"}</p>
        <button type="button" onClick={generateOutline}>生成章节细纲</button>
        <button type="button" onClick={approveOutline} disabled={!chapter.outline.trim() || chapter.outlineApproved}>确认细纲</button>
        <button type="button" onClick={generateBody} disabled={!chapter.outlineApproved}>生成正文</button>
      </section>

      <section className="agent-card revision-card">
        <h2>委派任务</h2>
        <p>{chapter.outlineApproved ? "正文会调用写作-主笔。" : "细纲会调用情节扩展-情节策划。"}</p>
        <div className="revision-diff">
          <span>&lt;/&gt; 1...</span>
          <strong>+{chapter.wordCount} -0</strong>
          <button type="button" onClick={openAudit}>查看变更</button>
        </div>
        <div className="revision-actions">
          <button type="button">全部丢弃</button>
          <button type="button" onClick={acceptAll}>全部接受</button>
        </div>
      </section>
    </>
  );
}

function RelationAgentPanel({ acceptAll, openReport }: { acceptAll: () => void; openReport: () => void }) {
  return (
    <>
      <section className="agent-card relation-agent-card">
        <header>
          <Bot size={18} aria-hidden="true" />
          <div>
            <strong>编剧本章</strong>
            <span>chapters · 差评</span>
          </div>
        </header>
        <p>好的，先读取本章正文，然后去编年史流程。</p>
        <div className="chapter-task-list">
          <label className="done"><input type="checkbox" checked readOnly /><span><strong>读取</strong><small>查看章节 · 第1章 · 差评</small></span></label>
          <label className="running"><input type="checkbox" readOnly /><span><strong>思考中...</strong><small>整理角色与关系线索</small></span></label>
        </div>
      </section>

      <section className="agent-card revision-card">
        <h2>委派任务</h2>
        <p>编年史者从本章发现了新关系和角色状态。</p>
        <div className="revision-diff">
          <span>&lt;/&gt; 2...</span>
          <strong>+243 -55</strong>
          <button type="button" onClick={openReport}>查看变更</button>
        </div>
        <article className="relation-suggestions">
          <p><strong>江然</strong><span>身份 / 作品简介 +111</span></p>
          <p><strong>宋知远</strong><span>简介 / 作品简介 +132 -55</span></p>
        </article>
        <div className="revision-actions">
          <button type="button">全部丢弃</button>
          <button type="button" onClick={acceptAll}>全部接受</button>
        </div>
      </section>
    </>
  );
}

function renderCharacterMentions(text: string, characters: CharacterProfile[]) {
  const names = characters.map((character) => character.name).filter(Boolean).sort((a, b) => b.length - a.length);
  if (!names.length) return text;
  const matcher = new RegExp(`(${names.map(escapeRegExp).join("|")})`, "g");
  return text.split("\n\n").map((paragraph, paragraphIndex) => (
    <p key={`${paragraphIndex}-${paragraph.slice(0, 8)}`}>
      {paragraph.split(matcher).map((part, index) => {
        const character = characters.find((item) => item.name === part);
        return character ? <CharacterMention character={character} key={`${part}-${index}`} /> : part;
      })}
    </p>
  ));
}

function CharacterMention({ character }: { character: CharacterProfile }) {
  return (
    <span className="character-mention" tabIndex={0}>
      {character.name}
      <span className="character-hover-card" role="tooltip">
        <strong>{character.name}</strong>
        <em>{character.role} · {character.gender}</em>
        <span>{character.status}</span>
      </span>
    </span>
  );
}

function escapeRegExp(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function avatarLabel(style: AvatarStyle) {
  return {
    movie: "电影感",
    anime: "日漫",
    fantasy: "东方幻想",
    photo: "摄影",
    custom: "自定义",
  }[style];
}

function makeAvatarUrl(name: string, style: AvatarStyle, prompt: string) {
  const palette = {
    movie: ["#2f3742", "#d8c4a6", "#f5efe8"],
    anime: ["#9dc7e8", "#f0b4c8", "#fff7fb"],
    fantasy: ["#d8e8e3", "#b8895f", "#fff8ec"],
    photo: ["#d2d8d6", "#8b8176", "#f7f4ef"],
    custom: ["#e8ddca", "#7f6b52", "#fffaf2"],
  }[style];
  const initial = name.trim().slice(0, 1) || "人";
  const note = prompt.trim().slice(0, 18) || avatarLabel(style);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320">
    <defs><linearGradient id="g" x1="0" x2="1" y1="0" y2="1"><stop stop-color="${palette[0]}"/><stop offset="1" stop-color="${palette[2]}"/></linearGradient></defs>
    <rect width="320" height="320" fill="url(#g)"/>
    <circle cx="160" cy="112" r="58" fill="${palette[2]}" opacity=".9"/>
    <path d="M77 292c16-74 50-108 83-108s67 34 83 108" fill="${palette[1]}" opacity=".72"/>
    <path d="M93 108c28-58 104-72 140 0-42-16-90-14-140 0z" fill="${palette[1]}" opacity=".82"/>
    <text x="160" y="132" text-anchor="middle" font-size="58" font-family="serif" fill="#3a3028">${initial}</text>
    <text x="160" y="282" text-anchor="middle" font-size="18" font-family="sans-serif" fill="#3a3028">${note}</text>
  </svg>`;
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

function Stat({ label, value }: { label: string; value: string }) {
  return <div className="stat"><span>{label}</span><strong>{value}</strong></div>;
}

function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <div className="empty-state">
      <Check size={18} aria-hidden="true" />
      <h3>{title}</h3>
      <p>{body}</p>
    </div>
  );
}
