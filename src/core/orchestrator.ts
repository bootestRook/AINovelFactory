import { makeArtifact, type ArtifactStore } from "./artifact-store";
import { agentById } from "./agents";
import { ProjectStateSchema, type AgentId, type ArtifactKind, type ProjectState, type RunEvent, type PipelineStepId } from "./schemas";

export interface PipelineStepSpec {
  readonly id: PipelineStepId;
  readonly label: string;
  readonly agentId: AgentId;
  readonly outputs: ReadonlyArray<ArtifactKind>;
  readonly gateAfter?: "human-review";
}

export interface PipelineRunSnapshot {
  readonly runId: string;
  readonly project: ProjectState;
  readonly events: ReadonlyArray<RunEvent>;
}

export interface ExportBundlePayload {
  readonly fileName: string;
  readonly format: "md";
  readonly content: string;
  readonly exportedAt: string;
  readonly sourceArtifactIds: ReadonlyArray<string>;
}

export const pipelineSteps: ReadonlyArray<PipelineStepSpec> = [
  { id: "initBook", label: "initBook", agentId: "coordinator", outputs: ["project_brief", "project_state", "run_plan"] },
  { id: "researchMarket", label: "researchMarket", agentId: "marketAnalyst", outputs: ["market_report", "genre_rules"] },
  { id: "buildCharacters", label: "buildCharacters", agentId: "characterDesigner", outputs: ["characters", "character_matrix"] },
  { id: "buildOutline", label: "buildOutline", agentId: "outlineArchitect", outputs: ["volume_outline", "arc_plan"] },
  { id: "planChapter", label: "planChapter", agentId: "plotPlanner", outputs: ["chapter_intent", "scene_cards"] },
  { id: "composeContext", label: "composeContext", agentId: "plotPlanner", outputs: ["context_package", "rule_stack"] },
  { id: "draftChapter", label: "draftChapter", agentId: "leadWriter", outputs: ["chapter_draft"] },
  { id: "settleState", label: "settleState", agentId: "leadWriter", outputs: ["state_delta", "memory_snapshot"] },
  { id: "auditChapter", label: "auditChapter", agentId: "editor", outputs: ["audit_report"] },
  { id: "reviseChapter", label: "reviseChapter", agentId: "editor", outputs: ["chapter_final"], gateAfter: "human-review" },
  { id: "approveChapter", label: "approveChapter", agentId: "coordinator", outputs: ["project_state"] },
  { id: "exportBook", label: "exportBook", agentId: "coordinator", outputs: ["export_bundle"] },
];

const reviewStop = "reviseChapter";

export class PipelineOrchestrator {
  constructor(private readonly store: ArtifactStore) {}

  async runUntilReview(brief: string): Promise<PipelineRunSnapshot> {
    const now = new Date().toISOString();
    const projectId = `book-${Date.now().toString(36)}`;
    const runId = `run-${Date.now().toString(36)}`;
    const title = titleFromBrief(brief);
    const events: RunEvent[] = [];
    const project = ProjectStateSchema.parse({
      projectId,
      title,
      status: "running",
      currentStep: "initBook",
      chapters: [],
      artifacts: [],
      memory: { facts: [], hooks: [], summaries: [] },
      updatedAt: now,
    });

    await this.store.saveProject(project);

    for (const step of pipelineSteps) {
      if (step.id === "approveChapter") break;
      await this.record(events, project, runId, "step-started", step, `${step.label} started`);

      for (const kind of step.outputs) {
        const artifact = makeArtifact({
          projectId,
          kind,
          byAgent: step.agentId,
          path: artifactPath(kind),
          chapterNumber: chapterArtifact(kind) ? 1 : undefined,
          summary: artifactSummary(kind),
          payload: this.payloadFor(kind, brief, title),
        });
        await this.store.put(artifact);
        project.artifacts.push(artifact);
        await this.record(events, project, runId, "artifact-written", step, `${kind} written`, artifact.id);
      }

      applyStepState(project, step.id);
      await this.record(events, project, runId, "step-completed", step, `${step.label} completed`);

      if (step.id === reviewStop) {
        project.status = "blocked-for-review";
        project.currentStep = "approveChapter";
        await this.record(events, project, runId, "gate-opened", step, "chapter ready for human review");
        break;
      }
    }

    project.updatedAt = new Date().toISOString();
    await this.store.saveProject(project);
    return { runId, project, events };
  }

  async approveAndExport(snapshot: PipelineRunSnapshot): Promise<PipelineRunSnapshot> {
    const project: ProjectState = {
      ...snapshot.project,
      chapters: snapshot.project.chapters.map((chapter) =>
        chapter.number === 1 ? { ...chapter, status: "approved" } : chapter,
      ),
      status: "approved",
      currentStep: "exportBook",
      updatedAt: new Date().toISOString(),
    };
    const events = [...snapshot.events];

    for (const step of pipelineSteps.filter((item) => item.id === "approveChapter" || item.id === "exportBook")) {
      await this.record(events, project, snapshot.runId, "step-started", step, `${step.label} started`);
      for (const kind of step.outputs) {
        const payload = kind === "export_bundle"
          ? this.buildExportBundle(project)
          : this.payloadFor(kind, "", project.title);
        const artifact = makeArtifact({
          projectId: project.projectId,
          kind,
          byAgent: step.agentId,
          path: artifactPath(kind),
          chapterNumber: kind === "export_bundle" ? 1 : undefined,
          summary: artifactSummary(kind),
          payload,
        });
        await this.store.put(artifact);
        project.artifacts.push(artifact);
        await this.record(events, project, snapshot.runId, "artifact-written", step, `${kind} written`, artifact.id);
      }
      await this.record(events, project, snapshot.runId, "step-completed", step, `${step.label} completed`);
    }

    project.status = "exported";
    project.chapters = project.chapters.map((chapter) =>
      chapter.number === 1 ? { ...chapter, status: "exported" } : chapter,
    );
    await this.record(events, project, snapshot.runId, "run-completed", pipelineSteps[pipelineSteps.length - 1]!, "book exported");
    await this.store.saveProject(project);
    return { ...snapshot, project, events };
  }

  private payloadFor(kind: ArtifactKind, brief: string, title: string): unknown {
    const agent = agentById[payloadAgent(kind)];
    switch (kind) {
      case "project_brief":
        return { title, brief };
      case "project_state":
        return { title, status: "snapshot" };
      case "audit_report":
        return {
          score: 86,
          passed: true,
          issues: [{ severity: "warning", category: "AI味", description: "部分句式偏整齐，交给 humanizer adapter 约束修订。" }],
        };
      case "chapter_draft":
      case "chapter_final":
        return `# 第1章 ${title}\n\n这里是 ${agent.title} 产出的章节占位稿。真实实现会替换为 LLM 输出。`;
      default:
        return { title, owner: agent.title, contract: artifactSummary(kind) };
    }
  }

  private buildExportBundle(project: ProjectState): ExportBundlePayload {
    const finalChapters = project.artifacts
      .filter((artifact) => artifact.kind === "chapter_final" && typeof artifact.payload === "string")
      .sort((left, right) => (left.chapterNumber ?? 0) - (right.chapterNumber ?? 0));
    const body = finalChapters.map((artifact) => artifact.payload as string).join("\n\n");
    const content = [`# ${project.title}`, "", body || "（暂无已批准章节）"].join("\n");

    return {
      fileName: `${slugify(project.title)}.md`,
      format: "md",
      content,
      exportedAt: new Date().toISOString(),
      sourceArtifactIds: finalChapters.map((artifact) => artifact.id),
    };
  }

  private async record(
    events: RunEvent[],
    project: ProjectState,
    runId: string,
    type: RunEvent["type"],
    step: PipelineStepSpec,
    message: string,
    artifactId?: string,
  ): Promise<void> {
    const event: RunEvent = {
      id: crypto.randomUUID(),
      runId,
      projectId: project.projectId,
      type,
      at: new Date().toISOString(),
      message,
      stepId: step.id,
      agentId: step.agentId,
      artifactId,
    };
    events.push(event);
    await this.store.appendEvent(event);
  }
}

function applyStepState(project: ProjectState, stepId: PipelineStepId): void {
  project.currentStep = stepId;
  project.updatedAt = new Date().toISOString();
  if (stepId === "draftChapter") {
    project.chapters = [{
      number: 1,
      title: "样章",
      status: "drafted",
      wordCount: 1200,
      auditIssues: [],
      artifactIds: project.artifacts.filter((item) => item.chapterNumber === 1).map((item) => item.id),
    }];
  }
  if (stepId === "settleState") {
    project.memory = {
      facts: ["主角身份已落库", "核心冲突已落库"],
      hooks: ["第一章结尾保留一个待回收钩子"],
      summaries: ["第1章完成开局冲突和人物动机"],
    };
  }
  if (stepId === "auditChapter") {
    project.chapters = project.chapters.map((chapter) => ({
      ...chapter,
      status: "ready-for-review",
      auditIssues: [{ severity: "warning", category: "AI味", description: "句式需要人工确认。" }],
    }));
  }
}

function titleFromBrief(brief: string): string {
  const firstLine = brief.trim().split(/\r?\n/).find(Boolean);
  return firstLine?.slice(0, 24) || "未命名小说";
}

function slugify(value: string): string {
  const slug = value
    .trim()
    .replace(/[\\/:*?"<>|]/g, "")
    .replace(/\s+/g, "-")
    .slice(0, 48);
  return slug || "book-export";
}

function chapterArtifact(kind: ArtifactKind): boolean {
  return ["chapter_intent", "scene_cards", "context_package", "rule_stack", "chapter_draft", "state_delta", "audit_report", "chapter_final"].includes(kind);
}

function artifactPath(kind: ArtifactKind): string {
  if (chapterArtifact(kind)) return `books/current/chapters/0001/${kind}`;
  if (kind === "export_bundle") return "books/current/export/book.md";
  return `books/current/story/${kind}`;
}

function artifactSummary(kind: ArtifactKind): string {
  return kind.replaceAll("_", " ");
}

function payloadAgent(kind: ArtifactKind): AgentId {
  if (["market_report", "genre_rules"].includes(kind)) return "marketAnalyst";
  if (["characters", "character_matrix"].includes(kind)) return "characterDesigner";
  if (["volume_outline", "arc_plan"].includes(kind)) return "outlineArchitect";
  if (["chapter_intent", "scene_cards", "context_package", "rule_stack"].includes(kind)) return "plotPlanner";
  if (["chapter_draft", "state_delta", "memory_snapshot"].includes(kind)) return "leadWriter";
  if (["audit_report", "chapter_final"].includes(kind)) return "editor";
  return "coordinator";
}
