import type { AgentId, ArtifactKind, ArtifactRecord, ArtifactRef, ProjectState, RunEvent } from "./schemas";

export interface ArtifactStore {
  put<T>(artifact: ArtifactRecord<T>): Promise<ArtifactRecord<T>>;
  get<T = unknown>(projectId: string, artifactId: string): Promise<ArtifactRecord<T> | undefined>;
  list(projectId: string): Promise<ReadonlyArray<ArtifactRecord>>;
  saveProject(project: ProjectState): Promise<ProjectState>;
  loadProject(projectId: string): Promise<ProjectState | undefined>;
  appendEvent(event: RunEvent): Promise<RunEvent>;
  listEvents(projectId: string): Promise<ReadonlyArray<RunEvent>>;
}

export class BrowserArtifactStore implements ArtifactStore {
  async put<T>(artifact: ArtifactRecord<T>): Promise<ArtifactRecord<T>> {
    const records = await this.listMutable(artifact.projectId);
    const index = records.findIndex((item) => item.id === artifact.id);
    if (index >= 0) {
      records[index] = artifact;
    } else {
      records.push(artifact);
    }
    this.write(this.artifactsKey(artifact.projectId), records);
    return artifact;
  }

  async get<T = unknown>(projectId: string, artifactId: string): Promise<ArtifactRecord<T> | undefined> {
    return (await this.list(projectId)).find((item) => item.id === artifactId) as ArtifactRecord<T> | undefined;
  }

  async list(projectId: string): Promise<ReadonlyArray<ArtifactRecord>> {
    return this.read<ArtifactRecord[]>(this.artifactsKey(projectId), []);
  }

  async saveProject(project: ProjectState): Promise<ProjectState> {
    this.write(this.projectKey(project.projectId), project);
    return project;
  }

  async loadProject(projectId: string): Promise<ProjectState | undefined> {
    return this.read<ProjectState | undefined>(this.projectKey(projectId), undefined);
  }

  async appendEvent(event: RunEvent): Promise<RunEvent> {
    const events = this.read<RunEvent[]>(this.eventsKey(event.projectId), []);
    events.push(event);
    this.write(this.eventsKey(event.projectId), events);
    return event;
  }

  async listEvents(projectId: string): Promise<ReadonlyArray<RunEvent>> {
    return this.read<RunEvent[]>(this.eventsKey(projectId), []);
  }

  private async listMutable(projectId: string): Promise<ArtifactRecord[]> {
    return [...(await this.list(projectId))];
  }

  private artifactsKey(projectId: string): string {
    return `novel-factory:${projectId}:artifacts`;
  }

  private projectKey(projectId: string): string {
    return `novel-factory:${projectId}:project`;
  }

  private eventsKey(projectId: string): string {
    return `novel-factory:${projectId}:events`;
  }

  private read<T>(key: string, fallback: T): T {
    if (typeof window === "undefined") return fallback;
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  }

  private write(key: string, value: unknown): void {
    if (typeof window === "undefined") return;
    window.localStorage.setItem(key, JSON.stringify(value));
  }
}

export function makeArtifact<T>(input: {
  readonly projectId: string;
  readonly kind: ArtifactKind;
  readonly path: string;
  readonly byAgent: AgentId;
  readonly payload: T;
  readonly chapterNumber?: number;
  readonly summary?: string;
}): ArtifactRecord<T> {
  const ref: ArtifactRef = {
    id: crypto.randomUUID(),
    projectId: input.projectId,
    kind: input.kind,
    path: input.path,
    version: 1,
    createdAt: new Date().toISOString(),
    byAgent: input.byAgent,
    chapterNumber: input.chapterNumber,
    summary: input.summary,
  };

  return { ...ref, payload: input.payload };
}
