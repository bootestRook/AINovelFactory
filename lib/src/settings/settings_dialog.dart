import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../app/ai_models_client.dart';
import '../app/app_agent_settings.dart';
import '../app/app_appearance.dart';
import '../app/app_ai_settings.dart';
import '../app/app_dream_settings.dart';
import '../app/app_editor_settings.dart';
import '../app/app_localizations.dart';
import '../app/app_storage_settings.dart';
import '../app/app_theme.dart';
import '../widgets/app_select_field.dart';

typedef StorageBackupCallback = Future<String> Function(String directoryPath);
typedef StorageRestoreCallback = Future<void> Function(String backupPath);

Future<void> showSettingsDialog(
  BuildContext context, {
  required AppLanguage language,
  required ValueChanged<AppLanguage> onLanguageChanged,
  required AppAppearance appearance,
  required ValueChanged<AppAppearance> onAppearanceChanged,
  required AppEditorSettings editorSettings,
  required ValueChanged<AppEditorSettings> onEditorSettingsChanged,
  required AppAiSettings aiSettings,
  required ValueChanged<AppAiSettings> onAiSettingsChanged,
  required AppAgentSettings agentSettings,
  required ValueChanged<AppAgentSettings> onAgentSettingsChanged,
  required AppDreamSettings dreamSettings,
  required ValueChanged<AppDreamSettings> onDreamSettingsChanged,
  required AppStorageSettings storageSettings,
  required ValueChanged<AppStorageSettings> onStorageSettingsChanged,
  required StorageBackupCallback onBackupNow,
  required StorageRestoreCallback onRestoreBackup,
  bool showAgents = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _SettingsDialog(
      language: language,
      onLanguageChanged: onLanguageChanged,
      appearance: appearance,
      onAppearanceChanged: onAppearanceChanged,
      editorSettings: editorSettings,
      onEditorSettingsChanged: onEditorSettingsChanged,
      aiSettings: aiSettings,
      onAiSettingsChanged: onAiSettingsChanged,
      agentSettings: agentSettings,
      onAgentSettingsChanged: onAgentSettingsChanged,
      dreamSettings: dreamSettings,
      onDreamSettingsChanged: onDreamSettingsChanged,
      storageSettings: storageSettings,
      onStorageSettingsChanged: onStorageSettingsChanged,
      onBackupNow: onBackupNow,
      onRestoreBackup: onRestoreBackup,
      showAgents: showAgents,
    ),
  );
}

enum _SettingsSection {
  general,
  appearance,
  editor,
  aiAssistant,
  aiProvider,
  aiModel,
  dream,
  usage,
  storage,
  about,
}

class _SettingsItem {
  const _SettingsItem({
    required this.section,
    required this.labelKey,
    required this.icon,
  });

  final _SettingsSection section;
  final String labelKey;
  final IconData icon;
}

const _settingsItems = [
  _SettingsItem(
    section: _SettingsSection.general,
    labelKey: 'settings.general',
    icon: Icons.settings_outlined,
  ),
  _SettingsItem(
    section: _SettingsSection.appearance,
    labelKey: 'settings.appearance',
    icon: Icons.palette_outlined,
  ),
  _SettingsItem(
    section: _SettingsSection.editor,
    labelKey: 'settings.editor',
    icon: Icons.text_fields,
  ),
  _SettingsItem(
    section: _SettingsSection.aiAssistant,
    labelKey: 'settings.aiAssistant',
    icon: Icons.smart_toy_outlined,
  ),
  _SettingsItem(
    section: _SettingsSection.aiProvider,
    labelKey: 'settings.aiProvider',
    icon: Icons.hub_outlined,
  ),
  _SettingsItem(
    section: _SettingsSection.aiModel,
    labelKey: 'settings.aiModel',
    icon: Icons.groups_2_outlined,
  ),
  _SettingsItem(
    section: _SettingsSection.dream,
    labelKey: 'settings.dream',
    icon: Icons.nightlight_round,
  ),
  _SettingsItem(
    section: _SettingsSection.usage,
    labelKey: 'settings.usage',
    icon: Icons.bar_chart_outlined,
  ),
  _SettingsItem(
    section: _SettingsSection.storage,
    labelKey: 'settings.storage',
    icon: Icons.inventory_2_outlined,
  ),
  _SettingsItem(
    section: _SettingsSection.about,
    labelKey: 'settings.about',
    icon: Icons.help_outline,
  ),
];

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({
    required this.language,
    required this.onLanguageChanged,
    required this.appearance,
    required this.onAppearanceChanged,
    required this.editorSettings,
    required this.onEditorSettingsChanged,
    required this.aiSettings,
    required this.onAiSettingsChanged,
    required this.agentSettings,
    required this.onAgentSettingsChanged,
    required this.dreamSettings,
    required this.onDreamSettingsChanged,
    required this.storageSettings,
    required this.onStorageSettingsChanged,
    required this.onBackupNow,
    required this.onRestoreBackup,
    required this.showAgents,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AppAppearance appearance;
  final ValueChanged<AppAppearance> onAppearanceChanged;
  final AppEditorSettings editorSettings;
  final ValueChanged<AppEditorSettings> onEditorSettingsChanged;
  final AppAiSettings aiSettings;
  final ValueChanged<AppAiSettings> onAiSettingsChanged;
  final AppAgentSettings agentSettings;
  final ValueChanged<AppAgentSettings> onAgentSettingsChanged;
  final AppDreamSettings dreamSettings;
  final ValueChanged<AppDreamSettings> onDreamSettingsChanged;
  final AppStorageSettings storageSettings;
  final ValueChanged<AppStorageSettings> onStorageSettingsChanged;
  final StorageBackupCallback onBackupNow;
  final StorageRestoreCallback onRestoreBackup;
  final bool showAgents;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late _SettingsSection _selected =
      widget.showAgents ? _SettingsSection.aiModel : _SettingsSection.general;
  late AppLanguage _language = widget.language;
  late AppAppearance _appearance = widget.appearance;
  late AppEditorSettings _editorSettings = widget.editorSettings;
  late AppAiSettings _aiSettings = widget.aiSettings;
  late AppAgentSettings _agentSettings = widget.agentSettings;
  late AppDreamSettings _dreamSettings = widget.dreamSettings;
  late AppStorageSettings _storageSettings = widget.storageSettings;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;
    final selectedItem = _settingsItems.firstWhere(
      (item) => item.section == _selected,
    );
    final selectedTitle = l10n.text(selectedItem.labelKey);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 620),
        child: SizedBox(
          width: 860,
          height: 620,
          child: Row(
            children: [
              _SettingsSidebar(
                selected: _selected,
                onSelected: (section) {
                  setState(() => _selected = section);
                },
              ),
              VerticalDivider(width: 1, thickness: 1, color: colors.line),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsHeader(title: selectedTitle),
                    Divider(height: 1, thickness: 1, color: colors.line),
                    Expanded(
                      child: _SettingsContent(
                        section: _selected,
                        title: selectedTitle,
                        language: _language,
                        onLanguageChanged: (language) {
                          setState(() => _language = language);
                          widget.onLanguageChanged(language);
                        },
                        appearance: _appearance,
                        onAppearanceChanged: (appearance) {
                          setState(() => _appearance = appearance);
                          widget.onAppearanceChanged(appearance);
                        },
                        editorSettings: _editorSettings,
                        onEditorSettingsChanged: (settings) {
                          setState(() => _editorSettings = settings);
                          widget.onEditorSettingsChanged(settings);
                        },
                        aiSettings: _aiSettings,
                        onAiSettingsChanged: (settings) {
                          final previousAgentSettings = _agentSettings;
                          final previousDreamSettings = _dreamSettings;
                          final agentSettings = _agentSettings
                              .pruneUnavailableModels(settings.activeModels);
                          final dreamSettings = _dreamSettings
                              .pruneUnavailableModels(settings.activeModels);
                          setState(() {
                            _aiSettings = settings;
                            _agentSettings = agentSettings;
                            _dreamSettings = dreamSettings;
                          });
                          widget.onAiSettingsChanged(settings);
                          if (agentSettings != previousAgentSettings) {
                            widget.onAgentSettingsChanged(agentSettings);
                          }
                          if (dreamSettings != previousDreamSettings) {
                            widget.onDreamSettingsChanged(dreamSettings);
                          }
                        },
                        agentSettings: _agentSettings,
                        onAgentSettingsChanged: (settings) {
                          setState(() => _agentSettings = settings);
                          widget.onAgentSettingsChanged(settings);
                        },
                        dreamSettings: _dreamSettings,
                        onDreamSettingsChanged: (settings) {
                          setState(() => _dreamSettings = settings);
                          widget.onDreamSettingsChanged(settings);
                        },
                        storageSettings: _storageSettings,
                        onStorageSettingsChanged: (settings) {
                          setState(() => _storageSettings = settings);
                          widget.onStorageSettingsChanged(settings);
                        },
                        onBackupNow: widget.onBackupNow,
                        onRestoreBackup: widget.onRestoreBackup,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.selected,
    required this.onSelected,
  });

  final _SettingsSection selected;
  final ValueChanged<_SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return Container(
      width: 160,
      color: colors.background,
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: _settingsItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final item = _settingsItems[index];
          final isSelected = item.section == selected;
          final label = l10n.text(item.labelKey);

          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(item.section),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.brand.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: isSelected ? colors.brand : colors.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? colors.text : colors.muted,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 14),
        child: Row(
          children: [
            Text(
              l10n.text('settings'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
            const Spacer(),
            IconButton(
              tooltip: l10n.text('settings.close'),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.section,
    required this.title,
    required this.language,
    required this.onLanguageChanged,
    required this.appearance,
    required this.onAppearanceChanged,
    required this.editorSettings,
    required this.onEditorSettingsChanged,
    required this.aiSettings,
    required this.onAiSettingsChanged,
    required this.agentSettings,
    required this.onAgentSettingsChanged,
    required this.dreamSettings,
    required this.onDreamSettingsChanged,
    required this.storageSettings,
    required this.onStorageSettingsChanged,
    required this.onBackupNow,
    required this.onRestoreBackup,
  });

  final _SettingsSection section;
  final String title;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AppAppearance appearance;
  final ValueChanged<AppAppearance> onAppearanceChanged;
  final AppEditorSettings editorSettings;
  final ValueChanged<AppEditorSettings> onEditorSettingsChanged;
  final AppAiSettings aiSettings;
  final ValueChanged<AppAiSettings> onAiSettingsChanged;
  final AppAgentSettings agentSettings;
  final ValueChanged<AppAgentSettings> onAgentSettingsChanged;
  final AppDreamSettings dreamSettings;
  final ValueChanged<AppDreamSettings> onDreamSettingsChanged;
  final AppStorageSettings storageSettings;
  final ValueChanged<AppStorageSettings> onStorageSettingsChanged;
  final StorageBackupCallback onBackupNow;
  final StorageRestoreCallback onRestoreBackup;

  @override
  Widget build(BuildContext context) {
    if (section == _SettingsSection.general) {
      return _GeneralSettingsPage(
        language: language,
        onLanguageChanged: onLanguageChanged,
      );
    }

    if (section == _SettingsSection.appearance) {
      return _AppearanceSettingsPage(
        appearance: appearance,
        onAppearanceChanged: onAppearanceChanged,
      );
    }

    if (section == _SettingsSection.editor) {
      return _EditorSettingsPage(
        settings: editorSettings,
        onChanged: onEditorSettingsChanged,
      );
    }

    if (section == _SettingsSection.aiProvider) {
      return _AiProviderSettingsPage(
        settings: aiSettings,
        onChanged: onAiSettingsChanged,
      );
    }

    if (section == _SettingsSection.aiModel) {
      return _AgentModelSettingsPage(
        aiSettings: aiSettings,
        settings: agentSettings,
        onChanged: onAgentSettingsChanged,
      );
    }

    if (section == _SettingsSection.dream) {
      return _DreamSettingsPage(
        aiSettings: aiSettings,
        settings: dreamSettings,
        onChanged: onDreamSettingsChanged,
      );
    }

    if (section == _SettingsSection.usage) {
      return _UsageSettingsPage(aiSettings: aiSettings);
    }

    if (section == _SettingsSection.storage) {
      return _StorageSettingsPage(
        settings: storageSettings,
        onChanged: onStorageSettingsChanged,
        onBackupNow: onBackupNow,
        onRestoreBackup: onRestoreBackup,
      );
    }

    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.text('settings.pending'),
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _GeneralSettingsPage extends StatelessWidget {
  const _GeneralSettingsPage({
    required this.language,
    required this.onLanguageChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('settings.language'),
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.text('settings.language.description'),
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (final item in AppLanguage.values) ...[
            _LanguageOption(
              title: item.displayName,
              subtitle: item.code,
              selected: item == language,
              onTap: () => onLanguageChanged(item),
            ),
            if (item != AppLanguage.values.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AgentModelSettingsPage extends StatefulWidget {
  const _AgentModelSettingsPage({
    required this.aiSettings,
    required this.settings,
    required this.onChanged,
  });

  final AppAiSettings aiSettings;
  final AppAgentSettings settings;
  final ValueChanged<AppAgentSettings> onChanged;

  @override
  State<_AgentModelSettingsPage> createState() =>
      _AgentModelSettingsPageState();
}

class _AgentModelSettingsPageState extends State<_AgentModelSettingsPage> {
  final _expandedAgentIds = <String>{'book_breakdown'};

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final models = widget.aiSettings.activeModels;
    final hasModels = models.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: _editorText(context, '智能体', 'Agents'),
            description: _editorText(
              context,
              '为智能体选择调用模型。展开后的子项才是真实可调用 Agent，模型列表来自 AI 供应商页读取结果。',
              'Choose agent models. Expanded child items are the callable agents, and models come from the AI Providers page.',
            ),
          ),
          const SizedBox(height: 14),
          if (!hasModels) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.muted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _editorText(
                        context,
                        '请先在 AI 供应商页填写 API Key、基础 URL，并读取模型列表。',
                        'Fetch models from AI Providers after entering API key and base URL.',
                      ),
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _SettingsGroup(
            children: _buildAgentRows(context, models, hasModels),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAgentRows(
    BuildContext context,
    List<String> models,
    bool hasModels,
  ) {
    final rows = <Widget>[];
    for (final agent in defaultAgentDefinitions) {
      if (rows.isNotEmpty) {
        rows.add(const Divider(height: 1));
      }

      final expanded = _expandedAgentIds.contains(agent.id);
      if (agent.children.isEmpty) {
        rows.add(
          _AgentModelRow(
            agent: agent,
            models: models,
            selectedModel: widget.settings.modelFor(agent.id),
            enabled: hasModels,
            description: _editorText(
              context,
              '职能后续定义，当前先绑定调用模型。',
              'Role details will be defined later; bind its model now.',
            ),
            onChanged: (model) {
              widget.onChanged(widget.settings.setModel(agent.id, model));
            },
          ),
        );
        continue;
      }

      rows.add(
        _AgentModelRow(
          agent: agent,
          models: models,
          selectedModel: widget.settings.modelFor(agent.id),
          enabled: hasModels,
          description: _editorText(
            context,
            '作为下级真实 Agent 的默认模型；子 Agent 可继承或单独覆盖。',
            'Default model for child callable agents; children can inherit or override it.',
          ),
          leading: IconButton(
            key: ValueKey('agent-expand-${agent.id}'),
            tooltip: expanded
                ? _editorText(context, '收起', 'Collapse')
                : _editorText(context, '展开', 'Expand'),
            onPressed: () {
              setState(() {
                if (expanded) {
                  _expandedAgentIds.remove(agent.id);
                } else {
                  _expandedAgentIds.add(agent.id);
                }
              });
            },
            icon: Icon(
              expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
              size: 20,
            ),
          ),
          onChanged: (model) {
            widget.onChanged(widget.settings.setModel(agent.id, model));
          },
        ),
      );

      if (!expanded) {
        continue;
      }

      for (final child in agent.children) {
        rows.add(const Divider(height: 1));
        rows.add(
          _AgentModelRow(
            agent: child,
            models: models,
            selectedModel: widget.settings.modelFor(child.id),
            inheritedModel: widget.settings.effectiveModelFor(
              child.id,
              fallbackAgentId: agent.id,
            ),
            inheritLabel: _editorText(
                context, '继承${agent.name}', 'Inherit ${agent.name}'),
            enabled: hasModels,
            indent: 34,
            isChild: true,
            description: _editorText(
              context,
              '真实可调用 Agent；默认继承上级模型，也可以单独指定。',
              'Callable agent; inherit the parent model by default or choose its own.',
            ),
            onChanged: (model) {
              widget.onChanged(widget.settings.setModel(child.id, model));
            },
          ),
        );
      }
    }
    return rows;
  }
}

class _AgentModelRow extends StatelessWidget {
  const _AgentModelRow({
    required this.agent,
    required this.models,
    required this.selectedModel,
    required this.enabled,
    required this.description,
    required this.onChanged,
    this.leading,
    this.indent = 0,
    this.isChild = false,
    this.inheritLabel,
    this.inheritedModel,
  });

  final AppAgentDefinition agent;
  final List<String> models;
  final String selectedModel;
  final bool enabled;
  final String description;
  final ValueChanged<String> onChanged;
  final Widget? leading;
  final double indent;
  final bool isChild;
  final String? inheritLabel;
  final String? inheritedModel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final usesInheritance = inheritLabel != null;
    final currentValue = usesInheritance
        ? selectedModel
        : selectedModel.isEmpty
            ? null
            : selectedModel;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (indent > 0) SizedBox(width: indent),
        if (leading != null) ...[
          SizedBox(width: 28, height: 28, child: leading),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agent.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: isChild ? 12.5 : 13,
                  fontWeight: isChild ? FontWeight.w600 : FontWeight.w700,
                ),
              ),
              if (isChild) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _editorText(context, '子 Agent', 'Child Agent'),
                    style: TextStyle(color: colors.brand, fontSize: 11),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 365,
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: AbsorbPointer(
              absorbing: !enabled,
              child: AppSelectField<String>(
                label: agent.name,
                value: currentValue,
                hint: enabled
                    ? _editorText(context, '选择模型', 'Choose a model')
                    : _editorText(context, '先读取模型', 'Fetch models first'),
                options: [
                  if (inheritLabel != null)
                    AppSelectOption(
                      value: '',
                      label: inheritLabel!,
                      description:
                          inheritedModel == null || inheritedModel!.isEmpty
                              ? _editorText(
                                  context, '上级未设置模型', 'Parent model is not set')
                              : inheritedModel,
                    ),
                  for (final model in models)
                    AppSelectOption(value: model, label: model),
                ],
                onChanged: (model) {
                  if (model == null) {
                    return;
                  }
                  onChanged(model);
                },
              ),
            ),
          ),
        ),
      ],
    );

    if (!isChild) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: row,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.background.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: colors.brand.withValues(alpha: 0.55),
              width: 3,
            ),
          ),
        ),
        child: row,
      ),
    );
  }
}

class _UsageSettingsPage extends StatefulWidget {
  const _UsageSettingsPage({required this.aiSettings});

  final AppAiSettings aiSettings;

  @override
  State<_UsageSettingsPage> createState() => _UsageSettingsPageState();
}

class _UsageSettingsPageState extends State<_UsageSettingsPage> {
  static const _allProviders = 'all';
  static const _allModels = 'all';

  String _provider = _allProviders;
  String _model = _allModels;

  @override
  Widget build(BuildContext context) {
    final providerOptions = _providerOptions(context);
    final modelOptions = [
      AppSelectOption(
        value: _allModels,
        label: _editorText(context, '全部模型', 'All Models'),
      ),
      for (final model in widget.aiSettings.activeModels)
        AppSelectOption(value: model, label: model),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: _editorText(context, '词元消耗', 'Token Usage'),
            description: _editorText(
              context,
              '按提供商和模型查看真实调用消耗。当前没有用量记录时显示 0，不生成模拟数据。',
              'Review real usage by provider and model. Empty usage records stay at zero.',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FilterSelect(
                  title: _editorText(context, '提供商', 'Provider'),
                  child: AppSelectField<String>(
                    label: _editorText(context, '提供商', 'Provider'),
                    value: _provider,
                    hint: _editorText(context, '全部提供商', 'All Providers'),
                    options: providerOptions,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _provider = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterSelect(
                  title: _editorText(context, '模型', 'Model'),
                  child: AppSelectField<String>(
                    label: _editorText(context, '用量模型', 'Usage Model'),
                    value: _model,
                    hint: _editorText(context, '全部模型', 'All Models'),
                    options: modelOptions,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _model = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _UsageSummaryCard(
                title: _editorText(context, '本日', 'Today'),
                value: '0',
                unit: _editorText(context, '词元', 'tokens'),
                rows: [
                  _UsageMetric(
                    label: _editorText(context, '输入', 'Input'),
                    color: Colors.black,
                    value: '0',
                  ),
                  _UsageMetric(
                    label: _editorText(context, '缓存读取', 'Cache Read'),
                    color: const Color(0xFF00A878),
                    value: '0',
                  ),
                  _UsageMetric(
                    label: _editorText(context, '缓存写入', 'Cache Write'),
                    color: const Color(0xFF333333),
                    value: '0',
                  ),
                  _UsageMetric(
                    label: _editorText(context, '输出', 'Output'),
                    color: const Color(0xFF777777),
                    value: '0',
                  ),
                ],
              ),
              _UsageSummaryCard(
                title: _editorText(context, '本月', 'This Month'),
                value: '0',
                unit: _editorText(context, '词元', 'tokens'),
                subtitle: _editorText(context, '上月无数据', 'No data last month'),
                rows: [
                  _UsageMetric(
                    label: _editorText(context, '输入', 'Input'),
                    color: Colors.black,
                    value: '0',
                  ),
                  _UsageMetric(
                    label: _editorText(context, '缓存读取', 'Cache Read'),
                    color: const Color(0xFF00A878),
                    value: '0',
                  ),
                  _UsageMetric(
                    label: _editorText(context, '缓存写入', 'Cache Write'),
                    color: const Color(0xFF333333),
                    value: '0',
                  ),
                  _UsageMetric(
                    label: _editorText(context, '输出', 'Output'),
                    color: const Color(0xFF777777),
                    value: '0',
                  ),
                ],
              ),
              _UsageMiniCard(
                title: _editorText(context, '今日请求', 'Requests Today'),
                value: '0',
                unit: _editorText(context, 'API 调用', 'API calls'),
              ),
              _UsageMiniCard(
                title: _editorText(context, '日平均值', 'Daily Average'),
                value: '0',
                unit: _editorText(context, '词元', 'tokens'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _UsageChartCard(),
          const SizedBox(height: 24),
          _UsageDetailTable(),
        ],
      ),
    );
  }

  List<AppSelectOption<String>> _providerOptions(BuildContext context) {
    return [
      AppSelectOption(
        value: _allProviders,
        label: _editorText(context, '全部提供商', 'All Providers'),
      ),
      for (final provider in widget.aiSettings.providers)
        if (provider.enabled)
          AppSelectOption(
            value: provider.id,
            label: _providerLabel(provider),
          ),
    ];
  }

  String _providerLabel(AppAiProviderSettings provider) {
    final name = provider.name.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final baseUrl = provider.baseUrl.trim();
    if (baseUrl.isEmpty) {
      return provider.id;
    }
    final uri = Uri.tryParse(baseUrl);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host;
    }
    return baseUrl;
  }
}

class _FilterSelect extends StatelessWidget {
  const _FilterSelect({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: colors.muted, fontSize: 12)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _UsageMetric {
  const _UsageMetric({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final String value;
}

class _UsageSummaryCard extends StatelessWidget {
  const _UsageSummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.rows,
    this.subtitle,
  });

  final String title;
  final String value;
  final String unit;
  final String? subtitle;
  final List<_UsageMetric> rows;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _UsageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: colors.text, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(unit, style: TextStyle(color: colors.muted, fontSize: 13)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.line),
          const SizedBox(height: 10),
          for (final row in rows) _UsageMetricRow(metric: row),
        ],
      ),
    );
  }
}

class _UsageMiniCard extends StatelessWidget {
  const _UsageMiniCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _UsageCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: colors.text, fontSize: 13)),
          const Spacer(),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(unit, style: TextStyle(color: colors.muted, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageMetricRow extends StatelessWidget {
  const _UsageMetricRow({required this.metric});

  final _UsageMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: metric.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              metric.label,
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ),
          Text(
            metric.value,
            style: TextStyle(color: colors.text, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _UsageChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _UsageCard(
      child: SizedBox(
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editorText(context, '每日词元用量', 'Daily Token Usage'),
              style: TextStyle(
                color: colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _editorText(context, '过去 30 天', 'Last 30 days'),
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _UsageLegendItem(
                  color: Colors.black,
                  label: _editorText(context, '输入', 'Input'),
                ),
                _UsageLegendItem(
                  color: const Color(0xFF00A878),
                  label: _editorText(context, '缓存读取', 'Cache Read'),
                ),
                _UsageLegendItem(
                  color: const Color(0xFF333333),
                  label: _editorText(context, '缓存写入', 'Cache Write'),
                ),
                _UsageLegendItem(
                  color: const Color(0xFF777777),
                  label: _editorText(context, '输出', 'Output'),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  _editorText(context, '暂无数据', 'No data'),
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageLegendItem extends StatelessWidget {
  const _UsageLegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: colors.muted, fontSize: 12)),
      ],
    );
  }
}

class _UsageDetailTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editorText(context, '用量明细', 'Usage Details'),
          style: TextStyle(
            color: colors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 38,
                color: colors.background,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _UsageHeaderCell(
                        label: _editorText(context, '时间', 'Time'), flex: 2),
                    _UsageHeaderCell(
                        label: _editorText(context, '提供商', 'Provider'),
                        flex: 2),
                    _UsageHeaderCell(
                        label: _editorText(context, '模型', 'Model'), flex: 3),
                    _UsageHeaderCell(
                        label: _editorText(context, '输入', 'Input'), flex: 1),
                    _UsageHeaderCell(
                        label: _editorText(context, '输出', 'Output'), flex: 1),
                    _UsageHeaderCell(
                        label: _editorText(context, '积分', 'Credits'), flex: 1),
                  ],
                ),
              ),
              SizedBox(
                height: 68,
                child: Center(
                  child: Text(
                    _editorText(context, '暂无用量记录', 'No usage records'),
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsageHeaderCell extends StatelessWidget {
  const _UsageHeaderCell({
    required this.label,
    required this.flex,
  });

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        style: TextStyle(
          color: colors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
  }
}

class _StorageSettingsPage extends StatefulWidget {
  const _StorageSettingsPage({
    required this.settings,
    required this.onChanged,
    required this.onBackupNow,
    required this.onRestoreBackup,
  });

  final AppStorageSettings settings;
  final ValueChanged<AppStorageSettings> onChanged;
  final StorageBackupCallback onBackupNow;
  final StorageRestoreCallback onRestoreBackup;

  @override
  State<_StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<_StorageSettingsPage> {
  late final _retentionController = TextEditingController(
    text: widget.settings.changeRetentionDays.toString(),
  );
  var _busy = false;

  @override
  void didUpdateWidget(covariant _StorageSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.settings.changeRetentionDays.toString();
    if (_retentionController.text != nextText) {
      _retentionController.text = nextText;
    }
  }

  @override
  void dispose() {
    _retentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: _editorText(context, '存储', 'Storage'),
            description: _editorText(
              context,
              '管理存储空间、变更记录保留时间和数据备份。',
              'Manage storage, change history retention, and data backups.',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _editorText(context, '变更记录保存时间', 'Change History Retention'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            _editorText(
              context,
              '超过该天数的变更记录将被自动清理。',
              'Change records older than this will be cleaned up automatically.',
            ),
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 160,
            child: TextField(
              key: const ValueKey('storage-retention-field'),
              controller: _retentionController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: _editorText(context, '天', 'days'),
              ),
              onChanged: _changeRetentionDays,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: _editorText(context, '备份', 'Backup'),
            description: _editorText(
              context,
              '配置数据库自动备份。',
              'Configure database backups.',
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            children: [
              _ControlRow(
                title: _editorText(context, '备份目录', 'Backup Directory'),
                description: _editorText(
                  context,
                  '选择备份保存位置。',
                  'Choose where backups are saved.',
                ),
                control: _BackupDirectoryPicker(
                  path: widget.settings.backupDirectory,
                  onChoose: _chooseBackupDirectory,
                ),
              ),
              const Divider(height: 1),
              _ControlRow(
                title: _editorText(context, '备份频率', 'Backup Frequency'),
                description: '',
                control: AppSelectField<AppBackupFrequency>(
                  label: _editorText(context, '备份频率', 'Backup Frequency'),
                  value: widget.settings.backupFrequency,
                  hint: _editorText(context, '仅手动', 'Manual only'),
                  options: [
                    for (final frequency in AppBackupFrequency.values)
                      AppSelectOption(
                        value: frequency,
                        label: _backupFrequencyLabel(context, frequency),
                      ),
                  ],
                  onChanged: (frequency) {
                    if (frequency == null) {
                      return;
                    }
                    widget.onChanged(
                      widget.settings.copyWith(backupFrequency: frequency),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        color: colors.muted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastBackupText(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const ValueKey('storage-backup-now-button'),
                onPressed: _busy ? null : _backupNow,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: Text(_editorText(context, '立即备份', 'Back Up Now')),
              ),
              OutlinedButton.icon(
                key: const ValueKey('storage-restore-button'),
                onPressed: _busy ? null : _restoreBackup,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(
                  _editorText(context, '从备份恢复', 'Restore from Backup'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _changeRetentionDays(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }
    widget.onChanged(
      widget.settings.copyWith(changeRetentionDays: parsed.clamp(1, 3650)),
    );
  }

  Future<void> _chooseBackupDirectory() async {
    final path = await getDirectoryPath(
      confirmButtonText: _editorText(context, '选择', 'Choose'),
    );
    if (path == null) {
      return;
    }
    widget.onChanged(widget.settings.copyWith(backupDirectory: path));
  }

  Future<void> _backupNow() async {
    final directory = widget.settings.backupDirectory.trim();
    if (directory.isEmpty) {
      _showStorageMessage(
        _editorText(context, '请先选择备份目录。', 'Choose a backup directory first.'),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final path = await widget.onBackupNow(directory);
      if (!mounted) {
        return;
      }
      widget.onChanged(widget.settings.copyWith(lastBackupAt: DateTime.now()));
      _showStorageMessage(
        _editorText(context, '已备份到 $path', 'Backed up to $path'),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showStorageMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restoreBackup() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: _editorText(context, '数据库备份', 'Database Backup'),
          extensions: const ['sqlite', 'db'],
        ),
      ],
      confirmButtonText: _editorText(context, '恢复', 'Restore'),
    );
    if (file == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.onRestoreBackup(file.path);
      if (!mounted) {
        return;
      }
      _showStorageMessage(
        _editorText(context, '已从备份恢复。', 'Restored from backup.'),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      _showStorageMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showStorageMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _lastBackupText(BuildContext context) {
    final lastBackupAt = widget.settings.lastBackupAt;
    if (lastBackupAt == null) {
      return _editorText(context, '上次备份: 从未', 'Last backup: Never');
    }
    return _editorText(
      context,
      '上次备份: ${_formatDateTime(lastBackupAt)}',
      'Last backup: ${_formatDateTime(lastBackupAt)}',
    );
  }
}

class _BackupDirectoryPicker extends StatelessWidget {
  const _BackupDirectoryPicker({
    required this.path,
    required this.onChoose,
  });

  final String path;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final hasPath = path.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Text(
            hasPath
                ? path
                : _editorText(
                    context,
                    '选择备份保存位置',
                    'Choose backup location',
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: hasPath ? colors.text : colors.muted),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          key: const ValueKey('storage-choose-directory-button'),
          onPressed: onChoose,
          child: Text(_editorText(context, '选择...', 'Choose...')),
        ),
      ],
    );
  }
}

String _backupFrequencyLabel(
  BuildContext context,
  AppBackupFrequency frequency,
) {
  switch (frequency) {
    case AppBackupFrequency.manual:
      return _editorText(context, '仅手动', 'Manual only');
    case AppBackupFrequency.daily:
      return _editorText(context, '每天', 'Daily');
    case AppBackupFrequency.weekly:
      return _editorText(context, '每周', 'Weekly');
    case AppBackupFrequency.monthly:
      return _editorText(context, '每月', 'Monthly');
  }
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class _DreamSettingsPage extends StatefulWidget {
  const _DreamSettingsPage({
    required this.aiSettings,
    required this.settings,
    required this.onChanged,
  });

  final AppAiSettings aiSettings;
  final AppDreamSettings settings;
  final ValueChanged<AppDreamSettings> onChanged;

  @override
  State<_DreamSettingsPage> createState() => _DreamSettingsPageState();
}

class _DreamSettingsPageState extends State<_DreamSettingsPage> {
  late final _intervalController = TextEditingController(
    text: widget.settings.intervalHours.toString(),
  );

  @override
  void didUpdateWidget(covariant _DreamSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.settings.intervalHours.toString();
    if (_intervalController.text != nextText) {
      _intervalController.text = nextText;
    }
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final activeModels = widget.aiSettings.activeModels;
    final hasModels = activeModels.isNotEmpty;
    final selectedModel = widget.settings.model;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: _editorText(context, '梦境', 'Dreams'),
            description: _editorText(
              context,
              '定期审视并整理已有记忆，合并重复条目，将重要记忆升级为核心，移除过时内容。',
              'Regularly review memories, merge duplicates, promote important memories, and remove stale content.',
            ),
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _editorText(context, '记忆整理', 'Memory Cleanup'),
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _editorText(
                              context,
                              '定期审视并整理已有记忆，合并重复条目，将重要记忆升级为核心，移除过时内容。',
                              'Regularly review memories, merge duplicates, promote important memories, and remove stale content.',
                            ),
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Switch(
                      key: const ValueKey('dream-memory-cleanup-switch'),
                      value: widget.settings.memoryCleanupEnabled,
                      onChanged: _toggleMemoryCleanup,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _editorText(context, '整理间隔（小时）', 'Cleanup Interval (hours)'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            _editorText(
              context,
              '多久执行一次记忆整理',
              'How often memory cleanup should run.',
            ),
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 160,
            child: TextField(
              key: const ValueKey('dream-interval-field'),
              controller: _intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(suffixText: 'h'),
              onChanged: _changeInterval,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _editorText(context, '整理模型', 'Cleanup Model'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 6),
          Text(
            _editorText(
              context,
              '用于记忆整理的模型，开启记忆整理前必须选择。',
              'Choose the model used for memory cleanup before enabling it.',
            ),
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: hasModels ? 1 : 0.55,
            child: AbsorbPointer(
              absorbing: !hasModels,
              child: AppSelectField<String>(
                label: _editorText(context, '整理模型', 'Cleanup Model'),
                value: selectedModel.isEmpty ? null : selectedModel,
                hint: hasModels
                    ? _editorText(context, '未设置', 'Not set')
                    : _editorText(context, '先读取模型', 'Fetch models first'),
                options: [
                  for (final model in activeModels)
                    AppSelectOption(value: model, label: model),
                ],
                onChanged: (model) {
                  if (model == null) {
                    return;
                  }
                  widget.onChanged(widget.settings.copyWith(model: model));
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _editorText(context, '上次运行', 'Last Run'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 10),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_outlined, color: colors.muted, size: 18),
                const SizedBox(width: 8),
                Text(
                  _lastRunText(context),
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMemoryCleanup(bool enabled) {
    if (enabled && widget.settings.model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editorText(
              context,
              '请先选择整理模型。',
              'Choose a cleanup model first.',
            ),
          ),
        ),
      );
      return;
    }
    widget.onChanged(widget.settings.copyWith(memoryCleanupEnabled: enabled));
  }

  void _changeInterval(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }
    widget.onChanged(
      widget.settings.copyWith(intervalHours: parsed.clamp(1, 8760)),
    );
  }

  String _lastRunText(BuildContext context) {
    final lastRunAt = widget.settings.lastRunAt;
    if (lastRunAt == null) {
      return _editorText(context, '从未运行', 'Never run');
    }
    final local = lastRunAt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _AiProviderSettingsPage extends StatefulWidget {
  const _AiProviderSettingsPage({
    required this.settings,
    required this.onChanged,
  });

  final AppAiSettings settings;
  final ValueChanged<AppAiSettings> onChanged;

  @override
  State<_AiProviderSettingsPage> createState() =>
      _AiProviderSettingsPageState();
}

class _AiProviderSettingsPageState extends State<_AiProviderSettingsPage> {
  String? _selectedProviderId;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final providers = widget.settings.providers;
    final selectedProvider = providers.firstWhere(
      (provider) => provider.id == _selectedProviderId,
      orElse: () => providers.first,
    );

    return Row(
      children: [
        SizedBox(
          width: 190,
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: providers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _AiProviderListItem(
                      provider: provider,
                      selected: provider.id == selectedProvider.id,
                      onTap: () {
                        setState(() => _selectedProviderId = provider.id);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: OutlinedButton.icon(
                    key: const ValueKey('ai-add-provider-button'),
                    onPressed: _addProvider,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      _editorText(context, '添加自定义', 'Add Custom'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: colors.line),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  title: _editorText(context, 'AI 供应商', 'AI Providers'),
                  description: _editorText(
                    context,
                    '选择左侧配置，填写 API Key 和基础 URL 后读取或添加模型；配置会保存到本地。',
                    'Choose a provider config, enter API key and base URL, then fetch or add models. Settings are saved locally.',
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.settings.isReady
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: widget.settings.isReady
                            ? colors.success
                            : colors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.settings.isReady
                              ? _editorText(
                                  context,
                                  '已启用可用供应商',
                                  'Provider ready',
                                )
                              : _editorText(
                                  context,
                                  '未启用：至少需要一个已启用且配置完整的供应商。',
                                  'Not enabled: at least one enabled provider must be complete.',
                                ),
                          style: TextStyle(color: colors.text, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ControlRow(
                  title: _editorText(context, '拆书并发上限', 'Book Concurrency'),
                  description: _editorText(
                    context,
                    '同时运行的拆书 Agent 数量，默认 3；过高可能触发供应商限流。',
                    'Number of book agents running at once. Default is 3; higher values may hit provider rate limits.',
                  ),
                  controlWidth: 180,
                  control: AppSelectField<int>(
                    label: 'Book Concurrency',
                    value: widget.settings.bookDeconstructionConcurrency,
                    hint: '3',
                    options: [
                      for (var value = 1; value <= 8; value++)
                        AppSelectOption(
                          value: value,
                          label: value.toString(),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      widget.onChanged(
                        widget.settings.copyWith(
                          bookDeconstructionConcurrency: value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _AiProviderCard(
                  key: ValueKey('ai-provider-card-${selectedProvider.id}'),
                  provider: selectedProvider,
                  canDelete: widget.settings.providers.length > 1,
                  onChanged: (nextProvider) {
                    widget.onChanged(
                      widget.settings.updateProvider(nextProvider),
                    );
                  },
                  onDelete: () => _deleteProvider(selectedProvider.id),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addProvider() {
    final nextSettings = widget.settings.addProvider();
    setState(() => _selectedProviderId = nextSettings.providers.last.id);
    widget.onChanged(nextSettings);
  }

  void _deleteProvider(String providerId) {
    final nextSettings = widget.settings.removeProvider(providerId);
    setState(() => _selectedProviderId = nextSettings.providers.first.id);
    widget.onChanged(nextSettings);
  }
}

class _AiProviderListItem extends StatelessWidget {
  const _AiProviderListItem({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final AppAiProviderSettings provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final providerName = provider.name.trim().isEmpty
        ? _editorText(context, '未命名供应商', 'Unnamed Provider')
        : provider.name.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.line.withValues(alpha: 0.45)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: provider.enabled ? colors.success : colors.line,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    provider.enabled
                        ? _editorText(context, '已启用', 'Enabled')
                        : _editorText(context, '未启用', 'Disabled'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiProviderCard extends StatefulWidget {
  const _AiProviderCard({
    super.key,
    required this.provider,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final AppAiProviderSettings provider;
  final bool canDelete;
  final ValueChanged<AppAiProviderSettings> onChanged;
  final VoidCallback onDelete;

  @override
  State<_AiProviderCard> createState() => _AiProviderCardState();
}

class _AiProviderCardState extends State<_AiProviderCard> {
  late final _nameController =
      TextEditingController(text: widget.provider.name);
  late final _apiKeyController =
      TextEditingController(text: widget.provider.apiKey);
  late final _baseUrlController =
      TextEditingController(text: widget.provider.baseUrl);
  final _customModelController = TextEditingController();
  var _loadingModels = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void didUpdateWidget(covariant _AiProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_nameController, widget.provider.name);
    _syncController(_apiKeyController, widget.provider.apiKey);
    _syncController(_baseUrlController, widget.provider.baseUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final provider = widget.provider;
    final canChooseModel = provider.availableModels.isNotEmpty;

    return _SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: provider.enabled ? colors.success : colors.line,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: ValueKey('ai-provider-name-${provider.id}'),
                  controller: _nameController,
                  decoration: const InputDecoration(border: InputBorder.none),
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: (value) =>
                      _updateProvider(provider.copyWith(name: value.trim())),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                provider.enabled
                    ? _editorText(context, '已启用', 'Enabled')
                    : _editorText(context, '未启用', 'Disabled'),
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(width: 10),
              IconButton(
                key: const ValueKey('ai-delete-selected-provider-button'),
                tooltip: _editorText(context, '删除配置', 'Delete Config'),
                onPressed: widget.canDelete ? _confirmDelete : null,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
              const SizedBox(width: 4),
              Switch(
                key: ValueKey('ai-provider-enabled-${provider.id}'),
                value: provider.enabled,
                onChanged: (enabled) =>
                    _updateProvider(provider.copyWith(enabled: enabled)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _ControlRow(
          title: 'API Key',
          description: _editorText(
            context,
            '会保存到本地配置文件，重新启动后自动恢复。',
            'Saved to a local settings file and restored after restart.',
          ),
          controlWidth: 300,
          control: TextField(
            key: ValueKey('ai-api-key-field-${provider.id}'),
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: _editorText(context, '输入你的 API Key', 'Enter API key'),
            ),
            onChanged: (value) =>
                _updateProvider(provider.copyWith(apiKey: value)),
          ),
        ),
        const Divider(height: 1),
        _ControlRow(
          title: _editorText(context, '基础 URL', 'Base URL'),
          description: _editorText(
            context,
            '使用 OpenAI 兼容地址，例如 https://api.example.com/v1。',
            'Use an OpenAI-compatible URL, such as https://api.example.com/v1.',
          ),
          controlWidth: 300,
          control: TextField(
            key: ValueKey('ai-base-url-field-${provider.id}'),
            controller: _baseUrlController,
            decoration: InputDecoration(
              hintText: _editorText(context, '输入基础 URL', 'Enter base URL'),
            ),
            onChanged: (value) =>
                _updateProvider(provider.copyWith(baseUrl: value)),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _editorText(
                    context,
                    '从 /models 自动读取模型列表。',
                    'Fetch the model list from /models.',
                  ),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                key: ValueKey('ai-fetch-models-button-${provider.id}'),
                onPressed: _loadingModels ? null : _fetchModels,
                icon: _loadingModels
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_sync_outlined, size: 18),
                label: Text(
                  _loadingModels
                      ? _editorText(context, '读取中', 'Fetching')
                      : _editorText(context, '读取模型', 'Fetch Models'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _ControlRow(
          title: _editorText(context, '模型', 'Model'),
          description: _editorText(
            context,
            '读取模型后选择该供应商默认使用的模型。',
            'Choose this provider default model after fetching models.',
          ),
          controlWidth: 300,
          control: Opacity(
            opacity: canChooseModel ? 1 : 0.55,
            child: AbsorbPointer(
              absorbing: !canChooseModel,
              child: AppSelectField<String>(
                label: '${provider.name}-model',
                value: provider.selectedModel.isEmpty
                    ? null
                    : provider.selectedModel,
                hint: canChooseModel
                    ? _editorText(context, '请选择模型', 'Choose a model')
                    : _editorText(context, '先读取模型列表', 'Fetch models first'),
                options: [
                  for (final model in provider.availableModels)
                    AppSelectOption(value: model, label: model),
                ],
                onChanged: (model) {
                  if (model == null) {
                    return;
                  }
                  _updateProvider(provider.copyWith(selectedModel: model));
                },
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        _ControlRow(
          title: _editorText(context, '手动模型', 'Manual Model'),
          description: _editorText(
            context,
            'API 未返回时可以手动添加到该供应商。',
            'Add one to this provider when the API does not return it.',
          ),
          controlWidth: 300,
          control: Row(
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('ai-custom-model-field-${provider.id}'),
                  controller: _customModelController,
                  decoration: InputDecoration(
                    hintText: _editorText(context, '输入模型 ID', 'Enter model ID'),
                  ),
                  onSubmitted: (_) => _addModel(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                key: ValueKey('ai-add-model-button-${provider.id}'),
                onPressed: _addModel,
                child: Text(_editorText(context, '添加模型', 'Add Model')),
              ),
            ],
          ),
        ),
        if (_message != null) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              _message!,
              style: TextStyle(
                color: _messageIsError
                    ? Theme.of(context).colorScheme.error
                    : colors.success,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  void _updateProvider(AppAiProviderSettings provider) {
    setState(() {
      _message = null;
      _messageIsError = false;
    });
    widget.onChanged(provider);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_editorText(context, '删除配置', 'Delete Config')),
          content: Text(
            _editorText(
              context,
              '确定删除这个 AI 供应商配置吗？此操作会移除它的 API Key、基础 URL 和模型列表。',
              'Delete this AI provider config? This removes its API key, base URL, and model list.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_editorText(context, '取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_editorText(context, '删除', 'Delete')),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      widget.onDelete();
    }
  }

  void _addModel() {
    final model = _customModelController.text.trim();
    if (model.isEmpty) {
      return;
    }
    if (widget.provider.availableModels.contains(model)) {
      setState(() {
        _message = _editorText(context, '模型已存在。', 'Model already exists.');
        _messageIsError = true;
      });
      return;
    }
    _customModelController.clear();
    _updateProvider(widget.provider.addModels([model]));
  }

  Future<void> _fetchModels() async {
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    if (apiKey.isEmpty || baseUrl.isEmpty) {
      setState(() {
        _message = _editorText(
          context,
          '请先填写 API Key 和基础 URL。',
          'Enter API key and base URL first.',
        );
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _loadingModels = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final models = await fetchOpenAiCompatibleModels(
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
      if (!mounted) {
        return;
      }
      widget.onChanged(
        widget.provider.addModels(models).copyWith(
              apiKey: apiKey,
              baseUrl: baseUrl,
            ),
      );
      setState(() {
        _message = _editorText(
          context,
          '已读取 ${models.length} 个模型。',
          'Fetched ${models.length} models.',
        );
        _messageIsError = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      widget.onChanged(
        widget.provider.copyWith(apiKey: apiKey, baseUrl: baseUrl),
      );
      setState(() {
        _message = error.toString();
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingModels = false);
      }
    }
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                selected ? colors.brand.withValues(alpha: 0.04) : colors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? colors.brand : colors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_outline,
                  color: colors.brand,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorSettingsPage extends StatefulWidget {
  const _EditorSettingsPage({
    required this.settings,
    required this.onChanged,
  });

  final AppEditorSettings settings;
  final ValueChanged<AppEditorSettings> onChanged;

  @override
  State<_EditorSettingsPage> createState() => _EditorSettingsPageState();
}

class _EditorSettingsPageState extends State<_EditorSettingsPage> {
  final _customFontController = TextEditingController();
  var _showAnnotationPalette = false;

  @override
  void dispose() {
    _customFontController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: _editorText(context, '编辑器', 'Editor'),
            description: _editorText(
              context,
              '配置编辑器的字体、间距和排版。',
              'Configure editor font, spacing, and layout.',
            ),
          ),
          const SizedBox(height: 14),
          _EditorPreview(settings: widget.settings),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              _ControlRow(
                title: _editorText(context, '编辑器字体', 'Editor Font'),
                description: _editorText(
                  context,
                  '从系统字体中选择编辑器显示字体，或输入自定义字体名称。',
                  'Choose a common system font, or add a custom font family.',
                ),
                control: AppSelectField<String>(
                  label: _editorText(context, '编辑器字体', 'Editor Font'),
                  value: widget.settings.fontFamily,
                  hint: _editorText(context, '请选择字体', 'Choose a font'),
                  options: [
                    for (final font in widget.settings.fontOptions)
                      AppSelectOption(value: font, label: font),
                  ],
                  onChanged: (font) {
                    if (font == null) {
                      return;
                    }
                    widget
                        .onChanged(widget.settings.copyWith(fontFamily: font));
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customFontController,
                        decoration: InputDecoration(
                          hintText: _editorText(
                            context,
                            '输入自定义字体名称',
                            'Enter custom font family',
                          ),
                        ),
                        onSubmitted: (_) => _addCustomFont(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _addCustomFont,
                      child: Text(_editorText(context, '添加', 'Add')),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _SliderRow(
                title: _editorText(context, '编辑器字号', 'Editor Font Size'),
                description: _editorText(
                  context,
                  '设置编辑器内容区域的文字大小。',
                  'Set the text size used in the editor content area.',
                ),
                value: widget.settings.fontSize,
                min: 12,
                max: 28,
                divisions: 16,
                displayValue: widget.settings.fontSize.round().toString(),
                onChanged: (value) {
                  widget.onChanged(widget.settings.copyWith(fontSize: value));
                },
              ),
              const Divider(height: 1),
              _SliderRow(
                title: _editorText(context, '字间距', 'Letter Spacing'),
                description: _editorText(
                  context,
                  '设置编辑器内容的字间距。',
                  'Set letter spacing for editor text.',
                ),
                value: widget.settings.letterSpacing,
                min: 0,
                max: 4,
                divisions: 8,
                displayValue: widget.settings.letterSpacing.toStringAsFixed(1),
                onChanged: (value) {
                  widget.onChanged(
                    widget.settings.copyWith(letterSpacing: value),
                  );
                },
              ),
              const Divider(height: 1),
              _SliderRow(
                title: _editorText(context, '行间距', 'Line Height'),
                description: _editorText(
                  context,
                  '设置编辑器内容的行高。',
                  'Set line height for editor text.',
                ),
                value: widget.settings.lineHeight,
                min: 1,
                max: 2.4,
                divisions: 14,
                displayValue: widget.settings.lineHeight.toStringAsFixed(2),
                onChanged: (value) {
                  widget.onChanged(widget.settings.copyWith(lineHeight: value));
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: _editorText(context, '实体标记', 'Entity Markers'),
            description: _editorText(
              context,
              '配置章节正文中识别到角色、物品等实体时使用的行内样式。',
              'Configure inline styles for detected characters, items, and entities.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in EditorEntityStyle.values)
                _ToggleChip(
                  label: _entityStyleLabel(context, style),
                  selected: widget.settings.entityStyles.contains(style),
                  onTap: () {
                    final styles = {...widget.settings.entityStyles};
                    styles.contains(style)
                        ? styles.remove(style)
                        : styles.add(style);
                    widget.onChanged(
                      widget.settings.copyWith(entityStyles: styles),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: _editorText(context, '自动排版', 'Auto Layout'),
            description: _editorText(
              context,
              '配置章节正文的自动排版行为。',
              'Configure automatic formatting behavior for chapter text.',
            ),
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            children: [
              _SliderRow(
                title: _editorText(context, '段首缩进', 'Paragraph Indent'),
                description: _editorText(
                  context,
                  '每段开头的全角空格数量（0–8）。',
                  'Number of full-width spaces at the start of each paragraph.',
                ),
                value: widget.settings.paragraphIndent.toDouble(),
                min: 0,
                max: 8,
                divisions: 8,
                displayValue: widget.settings.paragraphIndent.toString(),
                onChanged: (value) {
                  widget.onChanged(
                    widget.settings.copyWith(
                      paragraphIndent: value.round(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _ControlRow(
                title: _editorText(context, '段落间距', 'Paragraph Spacing'),
                description: _editorText(
                  context,
                  '段落之间是否插入一个空行。',
                  'Whether to insert a blank line between paragraphs.',
                ),
                control: Wrap(
                  spacing: 8,
                  children: [
                    _ToggleChip(
                      label: _editorText(context, '不空行', 'No Blank Line'),
                      selected: widget.settings.paragraphSpacing ==
                          EditorParagraphSpacing.none,
                      onTap: () => widget.onChanged(
                        widget.settings.copyWith(
                          paragraphSpacing: EditorParagraphSpacing.none,
                        ),
                      ),
                    ),
                    _ToggleChip(
                      label: _editorText(context, '空一行', 'Blank Line'),
                      selected: widget.settings.paragraphSpacing ==
                          EditorParagraphSpacing.blankLine,
                      onTap: () => widget.onChanged(
                        widget.settings.copyWith(
                          paragraphSpacing: EditorParagraphSpacing.blankLine,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _ControlRow(
                title: _editorText(context, '保留空格', 'Keep Spaces'),
                description: _editorText(
                  context,
                  '开启后，中英文之间的间距会被规范化；关闭后，所有空格将被移除。',
                  'Keep and normalize spaces instead of removing all spaces.',
                ),
                control: Switch(
                  value: widget.settings.keepSpaces,
                  onChanged: (value) {
                    widget
                        .onChanged(widget.settings.copyWith(keepSpaces: value));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _ControlRow(
            title: _editorText(context, '线条标注', 'Line Annotations'),
            description: _editorText(
              context,
              '配置编辑器线条标注的显示、风格和颜色。',
              'Configure editor line annotation visibility, style, and color.',
            ),
            control: Switch(
              value: widget.settings.annotationEnabled,
              onChanged: (value) {
                widget.onChanged(
                  widget.settings.copyWith(annotationEnabled: value),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _SettingsGroup(
            enabled: widget.settings.annotationEnabled,
            children: [
              _ControlRow(
                title: _editorText(context, '线条风格', 'Line Style'),
                description: '',
                control: Wrap(
                  spacing: 8,
                  children: [
                    for (final style in EditorAnnotationLineStyle.values)
                      _ToggleChip(
                        label: _lineStyleLabel(context, style),
                        enabled: widget.settings.annotationEnabled,
                        selected: widget.settings.annotationLineStyle == style,
                        onTap: () => widget.onChanged(
                          widget.settings.copyWith(annotationLineStyle: style),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _ControlRow(
                title: _editorText(context, '线条颜色', 'Line Color'),
                description: '',
                control: _LineColorControl(
                  color: widget.settings.annotationColor,
                  enabled: widget.settings.annotationEnabled,
                  expanded: _showAnnotationPalette,
                  onToggle: () {
                    setState(() {
                      _showAnnotationPalette = !_showAnnotationPalette;
                    });
                  },
                  onChanged: (color) {
                    widget.onChanged(
                      widget.settings.copyWith(annotationColor: color),
                    );
                    setState(() {
                      _showAnnotationPalette = false;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                child: _AnnotationLinePreview(settings: widget.settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addCustomFont() {
    final next = widget.settings.addCustomFont(_customFontController.text);
    if (next != widget.settings) {
      widget.onChanged(next);
    }
    _customFontController.clear();
  }
}

class _AppearanceSettingsPage extends StatelessWidget {
  const _AppearanceSettingsPage({
    required this.appearance,
    required this.onAppearanceChanged,
  });

  final AppAppearance appearance;
  final ValueChanged<AppAppearance> onAppearanceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: l10n.text('appearance.themeMode'),
            description: l10n.text('appearance.themeMode.description'),
          ),
          const SizedBox(height: 12),
          for (final preference in AppThemePreference.values) ...[
            _OptionRow(
              icon: _themePreferenceIcon(preference),
              title: _themePreferenceLabel(context, preference),
              selected: appearance.themePreference == preference,
              onTap: () => onAppearanceChanged(
                appearance.copyWith(themePreference: preference),
              ),
            ),
            if (preference != AppThemePreference.values.last)
              const SizedBox(height: 10),
          ],
          const SizedBox(height: 22),
          _SectionTitle(
            title: l10n.text('appearance.theme'),
            description: l10n.text('appearance.theme.description'),
          ),
          const SizedBox(height: 12),
          AppSelectField<AppVisualTheme>(
            label: l10n.text('appearance.theme'),
            value: appearance.visualTheme,
            hint: l10n.text('appearance.theme.description'),
            itemHeight: 64,
            options: [
              for (final theme in AppVisualTheme.values)
                AppSelectOption(
                  value: theme,
                  label: _visualThemeLabel(context, theme),
                  description: _visualThemeDescription(context, theme),
                  leadingBuilder: (_) => _ThemePreview(theme: theme),
                ),
            ],
            onChanged: (theme) {
              if (theme == null) {
                return;
              }
              onAppearanceChanged(appearance.copyWith(visualTheme: theme));
            },
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: l10n.text('appearance.background'),
            description: l10n.text('appearance.background.description'),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.text('appearance.solidBackground'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SwatchChip(
                label: l10n.text('appearance.noBackground'),
                color: AppPalette.of(context).background,
                selected: appearance.backgroundKind == AppBackgroundKind.none,
                onTap: () => onAppearanceChanged(
                  appearance.copyWith(backgroundKind: AppBackgroundKind.none),
                ),
              ),
              for (final background in AppSolidBackground.values)
                _SwatchChip(
                  label: _solidBackgroundLabel(context, background),
                  color: background.color,
                  selected:
                      appearance.backgroundKind == AppBackgroundKind.solid &&
                          appearance.solidBackground == background,
                  onTap: () => onAppearanceChanged(
                    appearance.copyWith(
                      backgroundKind: AppBackgroundKind.solid,
                      solidBackground: background,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.text('appearance.fillMode'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 10),
          AppSelectField<AppBackgroundFit>(
            label: l10n.text('appearance.fillMode'),
            value: appearance.backgroundFit,
            hint: l10n.text('appearance.fillMode'),
            options: [
              for (final fit in AppBackgroundFit.values)
                AppSelectOption(
                  value: fit,
                  label: _backgroundFitLabel(context, fit),
                ),
            ],
            onChanged: (fit) {
              if (fit == null) {
                return;
              }
              onAppearanceChanged(appearance.copyWith(backgroundFit: fit));
            },
          ),
          const SizedBox(height: 18),
          Text(
            l10n.text('appearance.builtInBackground'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final background in AppBuiltInBackground.values)
                _BackgroundTile(
                  label: _builtInBackgroundLabel(context, background),
                  gradient: background.gradient,
                  selected:
                      appearance.backgroundKind == AppBackgroundKind.builtIn &&
                          appearance.builtInBackground == background,
                  onTap: () => onAppearanceChanged(
                    appearance.copyWith(
                      backgroundKind: AppBackgroundKind.builtIn,
                      builtInBackground: background,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.text('appearance.customBackground'),
            style: _labelStyle(context),
          ),
          const SizedBox(height: 10),
          _CustomBackgroundPicker(
            appearance: appearance,
            onChanged: onAppearanceChanged,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.text,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(color: colors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                selected ? colors.brand.withValues(alpha: 0.04) : colors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? colors.brand : colors.line),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, color: selected ? colors.brand : colors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_outline,
                  color: colors.brand,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwatchChip extends StatelessWidget {
  const _SwatchChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.line),
        ),
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? colors.brand : colors.text,
        side: BorderSide(color: selected ? colors.brand : colors.line),
        backgroundColor:
            selected ? colors.brand.withValues(alpha: 0.04) : colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  const _BackgroundTile({
    required this.label,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Gradient gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return SizedBox(
      width: 112,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? colors.brand : colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: gradient,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final AppVisualTheme theme;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final palette =
        AppTheme.lightFor(theme).extension<AppPalette>() ?? AppPalette.light;

    return Container(
      width: 62,
      height: 42,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 14, color: palette.brand),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: palette.muted.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.children,
    this.enabled = true,
  });

  final List<Widget> children;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.line),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.title,
    required this.description,
    required this.control,
    this.controlWidth = 365,
  });

  final String title;
  final String description;
  final Widget control;
  final double controlWidth;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(width: controlWidth, child: control),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.title,
    required this.description,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String title;
  final String description;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _ControlRow(
      title: title,
      description: description,
      control: Row(
        children: [
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.line),
            ),
            child: Text(
              displayValue,
              style: TextStyle(color: colors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? colors.text : colors.muted,
        side: BorderSide(color: selected ? colors.text : colors.line),
        backgroundColor:
            selected ? colors.line.withValues(alpha: 0.35) : colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? colors.text : colors.line,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _LineColorControl extends StatelessWidget {
  const _LineColorControl({
    required this.color,
    required this.enabled,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
  });

  final Color color;
  final bool enabled;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? onToggle : null,
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _colorHex(color),
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                  Tooltip(
                    message: _editorText(context, '调色盘', 'Palette'),
                    child: Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: enabled ? colors.muted : colors.line,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: enabled ? colors.muted : colors.line,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final swatch in _annotationColors)
              _ColorDot(
                color: swatch,
                enabled: enabled,
                selected: color == swatch,
                onTap: () => onChanged(swatch),
              ),
          ],
        ),
        if (expanded) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.line),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final swatch in _annotationPaletteColors)
                  _ColorDot(
                    color: swatch,
                    enabled: enabled,
                    selected: color == swatch,
                    onTap: () => onChanged(swatch),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _EditorPreview extends StatelessWidget {
  const _EditorPreview({required this.settings});

  final AppEditorSettings settings;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final baseStyle = TextStyle(
      color: colors.text,
      fontFamily: settings.fontFamily,
      fontSize: settings.fontSize,
      letterSpacing: settings.letterSpacing,
      height: settings.lineHeight,
    );
    final markerStyle = _entityTextStyle(baseStyle, settings);
    final indent = '　' * settings.paragraphIndent;
    final gap = settings.paragraphSpacing == EditorParagraphSpacing.blankLine
        ? '\n\n'
        : '\n';
    final space = settings.keepSpaces ? ' ' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: '${indent}The quick brown fox jumps over'),
            TextSpan(text: '${space}the lazy dog.', style: markerStyle),
            TextSpan(text: gap),
            TextSpan(text: '$indent秋风萧瑟天气凉，'),
            TextSpan(text: '草木摇落露为霜。', style: markerStyle),
          ],
        ),
      ),
    );
  }
}

class _AnnotationLinePreview extends StatelessWidget {
  const _AnnotationLinePreview({required this.settings});

  final AppEditorSettings settings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: CustomPaint(
        painter: _AnnotationLinePainter(settings),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AnnotationLinePainter extends CustomPainter {
  const _AnnotationLinePainter(this.settings);

  final AppEditorSettings settings;

  @override
  void paint(Canvas canvas, Size size) {
    if (!settings.annotationEnabled) {
      return;
    }

    final paint = Paint()
      ..color = settings.annotationColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;

    switch (settings.annotationLineStyle) {
      case EditorAnnotationLineStyle.solid:
        canvas.drawLine(
            Offset.zero.translate(0, y), Offset(size.width, y), paint);
      case EditorAnnotationLineStyle.dashed:
        _drawPattern(canvas, size, paint, 12, 7, y);
      case EditorAnnotationLineStyle.dotted:
        _drawPattern(canvas, size, paint, 2, 8, y);
    }
  }

  void _drawPattern(
    Canvas canvas,
    Size size,
    Paint paint,
    double mark,
    double gap,
    double y,
  ) {
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + mark).clamp(0, size.width), y),
        paint,
      );
      x += mark + gap;
    }
  }

  @override
  bool shouldRepaint(_AnnotationLinePainter oldDelegate) {
    return settings != oldDelegate.settings;
  }
}

class _CustomBackgroundPicker extends StatelessWidget {
  const _CustomBackgroundPicker({
    required this.appearance,
    required this.onChanged,
  });

  final AppAppearance appearance;
  final ValueChanged<AppAppearance> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;
    final path = appearance.customBackgroundPath;
    final file = path == null ? null : File(path);
    final hasImage = file != null && file.existsSync();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 58,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.line),
              image: hasImage
                  ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                  : null,
            ),
            child: hasImage
                ? null
                : Icon(Icons.image_outlined, color: colors.muted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hasImage
                  ? file.path.split(Platform.pathSeparator).last
                  : l10n.text('appearance.noCustomImage'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: hasImage ? colors.text : colors.muted),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () async {
              final file = await openFile(
                acceptedTypeGroups: [
                  XTypeGroup(
                    label: l10n.text('appearance.imageBackground'),
                    extensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
                  ),
                ],
                confirmButtonText: l10n.text('appearance.chooseImage'),
              );
              if (file == null) {
                return;
              }
              onChanged(
                appearance.copyWith(
                  backgroundKind: AppBackgroundKind.custom,
                  customBackgroundPath: file.path,
                ),
              );
            },
            child: Text(l10n.text('appearance.chooseImage')),
          ),
        ],
      ),
    );
  }
}

TextStyle _labelStyle(BuildContext context) {
  final colors = AppPalette.of(context);
  return TextStyle(
      color: colors.text, fontSize: 13, fontWeight: FontWeight.w700);
}

String _editorText(BuildContext context, String zhCn, String en) {
  return context.l10n.isEnglish ? en : zhCn;
}

String _entityStyleLabel(BuildContext context, EditorEntityStyle style) {
  switch (style) {
    case EditorEntityStyle.italic:
      return _editorText(context, '斜体', 'Italic');
    case EditorEntityStyle.bold:
      return _editorText(context, '粗体', 'Bold');
    case EditorEntityStyle.underline:
      return _editorText(context, '划线', 'Underline');
    case EditorEntityStyle.highlight:
      return _editorText(context, '高亮', 'Highlight');
  }
}

String _lineStyleLabel(BuildContext context, EditorAnnotationLineStyle style) {
  switch (style) {
    case EditorAnnotationLineStyle.solid:
      return _editorText(context, '实线', 'Solid');
    case EditorAnnotationLineStyle.dashed:
      return _editorText(context, '稀疏虚线', 'Dashed');
    case EditorAnnotationLineStyle.dotted:
      return _editorText(context, '密集虚线', 'Dotted');
  }
}

TextStyle _entityTextStyle(
  TextStyle baseStyle,
  AppEditorSettings settings,
) {
  var style = baseStyle.copyWith();
  final entityStyles = settings.entityStyles;

  if (entityStyles.contains(EditorEntityStyle.italic)) {
    style = style.copyWith(fontStyle: FontStyle.italic);
  }
  if (entityStyles.contains(EditorEntityStyle.bold)) {
    style = style.copyWith(fontWeight: FontWeight.w700);
  }
  if (entityStyles.contains(EditorEntityStyle.underline)) {
    style = style.copyWith(decoration: TextDecoration.underline);
  }
  if (entityStyles.contains(EditorEntityStyle.highlight)) {
    style = style.copyWith(backgroundColor: const Color(0xFFFFF3A3));
  }
  return style;
}

String _colorHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

const _annotationColors = [
  Color(0xFFFF6F6F),
  Color(0xFF7C6DFF),
  Color(0xFF6BCB77),
  Color(0xFFFFBE76),
  Color(0xFFB967FF),
  Color(0xFF6EDBDD),
  Color(0xFFE3E76F),
  Color(0xFFFF8FB3),
  Color(0xFF9E9E9E),
  Color(0xFFC8C8C8),
  Color(0xFF6B6B6B),
  Color(0xFFD9A76C),
];

const _annotationPaletteColors = [
  ..._annotationColors,
  Color(0xFFE53935),
  Color(0xFFD81B60),
  Color(0xFF8E24AA),
  Color(0xFF5E35B1),
  Color(0xFF3949AB),
  Color(0xFF1E88E5),
  Color(0xFF039BE5),
  Color(0xFF00ACC1),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF7CB342),
  Color(0xFFC0CA33),
  Color(0xFFFDD835),
  Color(0xFFFFB300),
  Color(0xFFFB8C00),
  Color(0xFFF4511E),
  Color(0xFF795548),
  Color(0xFF546E7A),
  Color(0xFF212121),
  Color(0xFFFFFFFF),
];

IconData _themePreferenceIcon(AppThemePreference preference) {
  switch (preference) {
    case AppThemePreference.light:
      return Icons.light_mode_outlined;
    case AppThemePreference.dark:
      return Icons.dark_mode_outlined;
    case AppThemePreference.system:
      return Icons.brightness_auto_outlined;
  }
}

String _themePreferenceLabel(
  BuildContext context,
  AppThemePreference preference,
) {
  switch (preference) {
    case AppThemePreference.light:
      return context.l10n.text('appearance.light');
    case AppThemePreference.dark:
      return context.l10n.text('appearance.dark');
    case AppThemePreference.system:
      return context.l10n.text('appearance.system');
  }
}

String _visualThemeLabel(BuildContext context, AppVisualTheme theme) {
  return context.l10n.text('visualTheme.${theme.name}');
}

String _visualThemeDescription(BuildContext context, AppVisualTheme theme) {
  return context.l10n.text('visualTheme.${theme.name}.description');
}

String _solidBackgroundLabel(
    BuildContext context, AppSolidBackground background) {
  return context.l10n.text('visualTheme.${background.name}');
}

String _builtInBackgroundLabel(
  BuildContext context,
  AppBuiltInBackground background,
) {
  return context.l10n.text('background.${background.name}');
}

String _backgroundFitLabel(BuildContext context, AppBackgroundFit fit) {
  return context.l10n.text('appearance.fit.${fit.name}');
}
