import { z } from "zod";

export const agentIds = [
  "coordinator",
  "marketAnalyst",
  "characterDesigner",
  "outlineArchitect",
  "plotPlanner",
  "leadWriter",
  "editor",
  "actor",
] as const;

export const artifactKinds = [
  "project_brief",
  "project_state",
  "run_plan",
  "market_report",
  "genre_rules",
  "characters",
  "character_matrix",
  "volume_outline",
  "arc_plan",
  "chapter_intent",
  "scene_cards",
  "context_package",
  "rule_stack",
  "chapter_draft",
  "state_delta",
  "audit_report",
  "chapter_final",
  "export_bundle",
  "memory_snapshot",
] as const;

export const pipelineStepIds = [
  "initBook",
  "researchMarket",
  "buildCharacters",
  "buildOutline",
  "planChapter",
  "composeContext",
  "draftChapter",
  "settleState",
  "auditChapter",
  "reviseChapter",
  "approveChapter",
  "exportBook",
] as const;

export const AgentIdSchema = z.enum(agentIds);
export type AgentId = z.infer<typeof AgentIdSchema>;

export const ArtifactKindSchema = z.enum(artifactKinds);
export type ArtifactKind = z.infer<typeof ArtifactKindSchema>;

export const PipelineStepIdSchema = z.enum(pipelineStepIds);
export type PipelineStepId = z.infer<typeof PipelineStepIdSchema>;

export const ChapterStatusSchema = z.enum([
  "planned",
  "drafted",
  "audit-failed",
  "ready-for-review",
  "approved",
  "rejected",
  "exported",
]);
export type ChapterStatus = z.infer<typeof ChapterStatusSchema>;

export const AuditIssueSchema = z.object({
  severity: z.enum(["info", "warning", "critical"]),
  category: z.string().min(1),
  description: z.string().min(1),
  suggestion: z.string().optional(),
});
export type AuditIssue = z.infer<typeof AuditIssueSchema>;

export const ArtifactRefSchema = z.object({
  id: z.string().min(1),
  projectId: z.string().min(1),
  kind: ArtifactKindSchema,
  path: z.string().min(1),
  version: z.number().int().min(1),
  createdAt: z.string().datetime(),
  byAgent: AgentIdSchema,
  chapterNumber: z.number().int().min(1).optional(),
  summary: z.string().optional(),
});
export type ArtifactRef = z.infer<typeof ArtifactRefSchema>;

export const ArtifactRecordSchema = ArtifactRefSchema.extend({
  payload: z.unknown(),
});

export type ArtifactRecord<T = unknown> = ArtifactRef & {
  readonly payload: T;
};

export const ChapterMetaSchema = z.object({
  number: z.number().int().min(1),
  title: z.string().min(1),
  status: ChapterStatusSchema,
  wordCount: z.number().int().nonnegative(),
  auditIssues: z.array(AuditIssueSchema).default([]),
  artifactIds: z.array(z.string()).default([]),
});
export type ChapterMeta = z.infer<typeof ChapterMetaSchema>;

export const ProjectStateSchema = z.object({
  projectId: z.string().min(1),
  title: z.string().min(1),
  status: z.enum(["idle", "running", "blocked-for-review", "approved", "exported"]),
  currentStep: PipelineStepIdSchema.optional(),
  chapters: z.array(ChapterMetaSchema).default([]),
  artifacts: z.array(ArtifactRecordSchema).default([]),
  memory: z.object({
    facts: z.array(z.string()).default([]),
    hooks: z.array(z.string()).default([]),
    summaries: z.array(z.string()).default([]),
  }),
  updatedAt: z.string().datetime(),
});
export type ProjectState = z.infer<typeof ProjectStateSchema>;

export const RunEventSchema = z.object({
  id: z.string().min(1),
  runId: z.string().min(1),
  projectId: z.string().min(1),
  type: z.enum([
    "step-started",
    "artifact-written",
    "gate-opened",
    "step-completed",
    "run-completed",
  ]),
  at: z.string().datetime(),
  message: z.string().min(1),
  stepId: PipelineStepIdSchema.optional(),
  agentId: AgentIdSchema.optional(),
  artifactId: z.string().optional(),
});
export type RunEvent = z.infer<typeof RunEventSchema>;
