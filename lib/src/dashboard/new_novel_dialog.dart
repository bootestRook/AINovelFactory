import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import 'dashboard_models.dart';
import '../widgets/app_select_field.dart';

const novelCategories = [
  '玄幻',
  '仙侠',
  '修真',
  '都市',
  '言情',
  '历史',
  '科幻',
  '悬疑',
  '推理',
  '恐怖',
  '武侠',
  '游戏',
  '现实',
  '轻小说',
  '军事',
  '体育',
  '种田',
  '穿越',
  '重生',
  '末世',
  '校园',
  '商战',
  '宫斗',
  '自定义新增',
];

const novelWorkTypes = [
  '原创',
  '续作',
  '同人',
  '二创',
  '资料',
  '自定义新增',
];

const _imageTypes = [
  XTypeGroup(
    label: '图片',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
  ),
];

class NewNovelDraft {
  const NewNovelDraft({
    required this.title,
    required this.summary,
    required this.category,
    required this.workType,
    required this.tags,
    this.coverPath,
  });

  final String title;
  final String summary;
  final String category;
  final String workType;
  final List<String> tags;
  final String? coverPath;
}

Future<NewNovelDraft?> showNewNovelDialog(BuildContext context) {
  return showDialog<NewNovelDraft>(
    context: context,
    builder: (context) => const _NewNovelDialog(),
  );
}

Future<NewNovelDraft?> showEditNovelDialog(
  BuildContext context,
  NovelSummary novel,
) {
  return showDialog<NewNovelDraft>(
    context: context,
    builder: (context) => _NewNovelDialog(novel: novel),
  );
}

class _NewNovelDialog extends StatefulWidget {
  const _NewNovelDialog({this.novel});

  final NovelSummary? novel;

  @override
  State<_NewNovelDialog> createState() => _NewNovelDialogState();
}

class _NewNovelDialogState extends State<_NewNovelDialog> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _customWorkTypeController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _tags = <String>[];
  String? _category;
  String _workType = novelWorkTypes.first;
  String? _coverPath;
  bool _isAddingTag = false;

  bool get _isEditing => widget.novel != null;

  @override
  void initState() {
    super.initState();
    final novel = widget.novel;
    if (novel == null) {
      return;
    }
    _titleController.text = novel.title;
    _summaryController.text = novel.summary;
    _category = _initialOption(
      novel.category,
      novelCategories,
      _customCategoryController,
    );
    _workType = _initialOption(
      novel.workType,
      novelWorkTypes,
      _customWorkTypeController,
    );
    _tags.addAll(novel.tags);
    _coverPath = novel.coverPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _customCategoryController.dispose();
    _customWorkTypeController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text(
                    _isEditing ? 'newNovel.editTitle' : 'newNovel.title',
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 620;
                        final form = _NovelForm(
                          titleController: _titleController,
                          summaryController: _summaryController,
                          customCategoryController: _customCategoryController,
                          customWorkTypeController: _customWorkTypeController,
                          category: _category,
                          workType: _workType,
                          tags: _tags,
                          tagController: _tagController,
                          isAddingTag: _isAddingTag,
                          onCategoryChanged: (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                          onWorkTypeChanged: (value) {
                            if (value != null) {
                              setState(() => _workType = value);
                            }
                          },
                          onStartAddingTag: () {
                            setState(() => _isAddingTag = true);
                          },
                          onConfirmTag: _confirmTag,
                          onRemoveTag: (tag) {
                            setState(() => _tags.remove(tag));
                          },
                        );

                        if (compact) {
                          return Column(
                            children: [
                              _CoverPicker(
                                coverPath: _coverPath,
                                onPick: _pickCover,
                                onRemove: _isEditing && _coverPath != null
                                    ? () => setState(() => _coverPath = null)
                                    : null,
                                buttonLabel: l10n.text(_isEditing
                                    ? 'newNovel.changeCover'
                                    : 'newNovel.chooseCover'),
                              ),
                              const SizedBox(height: 18),
                              form,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 164,
                              child: _CoverPicker(
                                coverPath: _coverPath,
                                onPick: _pickCover,
                                onRemove: _isEditing && _coverPath != null
                                    ? () => setState(() => _coverPath = null)
                                    : null,
                                buttonLabel: l10n.text(_isEditing
                                    ? 'newNovel.changeCover'
                                    : 'newNovel.chooseCover'),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(child: form),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(height: 1, color: colors.line),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.text('action.cancel')),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(
                        l10n.text(_isEditing ? 'action.save' : 'action.create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCover() async {
    final image = await openFile(acceptedTypeGroups: _imageTypes);
    if (image == null || !mounted) {
      return;
    }
    setState(() => _coverPath = image.path);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(NewNovelDraft(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      category: _selectedValue(
        _category,
        _customCategoryController,
        novelCategories.last,
      ),
      workType: _selectedValue(
        _workType,
        _customWorkTypeController,
        novelWorkTypes.last,
      ),
      tags: List.unmodifiable(_tags),
      coverPath: _coverPath,
    ));
  }

  void _confirmTag() {
    final tag = _tagController.text.trim();
    setState(() {
      if (tag.isNotEmpty && !_tags.contains(tag)) {
        _tags.add(tag);
      }
      _tagController.clear();
      _isAddingTag = false;
    });
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({
    required this.coverPath,
    required this.onPick,
    required this.buttonLabel,
    this.onRemove,
  });

  final String? coverPath;
  final VoidCallback onPick;
  final VoidCallback? onRemove;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final path = coverPath;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.text('newNovel.cover'),
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: path == null
                ? Icon(Icons.image_outlined, color: colors.muted, size: 30)
                : Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.image_outlined, size: 18),
          label: Text(buttonLabel),
        ),
        if (onRemove != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            label: Text(l10n.text('newNovel.removeCover')),
          ),
        ],
      ],
    );
  }
}

class _NovelForm extends StatelessWidget {
  const _NovelForm({
    required this.titleController,
    required this.summaryController,
    required this.customCategoryController,
    required this.customWorkTypeController,
    required this.category,
    required this.workType,
    required this.tags,
    required this.tagController,
    required this.isAddingTag,
    required this.onCategoryChanged,
    required this.onWorkTypeChanged,
    required this.onStartAddingTag,
    required this.onConfirmTag,
    required this.onRemoveTag,
  });

  final TextEditingController titleController;
  final TextEditingController summaryController;
  final TextEditingController customCategoryController;
  final TextEditingController customWorkTypeController;
  final TextEditingController tagController;
  final String? category;
  final String workType;
  final List<String> tags;
  final bool isAddingTag;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onWorkTypeChanged;
  final VoidCallback onStartAddingTag;
  final VoidCallback onConfirmTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledControl(
          label: l10n.text('newNovel.name'),
          child: TextFormField(
            controller: titleController,
            autofocus: true,
            decoration:
                InputDecoration(hintText: l10n.text('newNovel.nameHint')),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.text('newNovel.nameRequired');
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        _LabeledControl(
          label: l10n.text('newNovel.summary'),
          child: TextFormField(
            controller: summaryController,
            minLines: 4,
            maxLines: 4,
            decoration:
                InputDecoration(hintText: l10n.text('newNovel.summaryHint')),
          ),
        ),
        const SizedBox(height: 14),
        _LabeledControl(
          label: l10n.text('newNovel.category'),
          child: AppSelectField<String>(
            label: l10n.text('newNovel.category'),
            value: category,
            hint: l10n.text('newNovel.categoryHint'),
            options: [
              for (final category in novelCategories)
                AppSelectOption(value: category, label: category),
            ],
            onChanged: onCategoryChanged,
          ),
        ),
        if (category == novelCategories.last) ...[
          const SizedBox(height: 10),
          _LabeledControl(
            label: l10n.text('newNovel.customCategory'),
            child: TextFormField(
              controller: customCategoryController,
              decoration: InputDecoration(
                hintText: l10n.text('newNovel.customCategoryHint'),
              ),
              validator: (value) {
                if (category == novelCategories.last &&
                    (value == null || value.trim().isEmpty)) {
                  return l10n.text('newNovel.customCategoryRequired');
                }
                return null;
              },
            ),
          ),
        ],
        const SizedBox(height: 14),
        _LabeledControl(
          label: l10n.text('newNovel.workType'),
          child: AppSelectField<String>(
            label: l10n.text('newNovel.workType'),
            value: workType,
            hint: l10n.text('newNovel.workTypeHint'),
            options: [
              for (final workType in novelWorkTypes)
                AppSelectOption(value: workType, label: workType),
            ],
            onChanged: onWorkTypeChanged,
          ),
        ),
        if (workType == novelWorkTypes.last) ...[
          const SizedBox(height: 10),
          _LabeledControl(
            label: l10n.text('newNovel.customWorkType'),
            child: TextFormField(
              controller: customWorkTypeController,
              decoration: InputDecoration(
                hintText: l10n.text('newNovel.customWorkTypeHint'),
              ),
              validator: (value) {
                if (workType == novelWorkTypes.last &&
                    (value == null || value.trim().isEmpty)) {
                  return l10n.text('newNovel.customWorkTypeRequired');
                }
                return null;
              },
            ),
          ),
        ],
        const SizedBox(height: 14),
        _LabeledControl(
          label: l10n.text('newNovel.tags'),
          child: _TagEditor(
            tags: tags,
            controller: tagController,
            isAdding: isAddingTag,
            onStartAdding: onStartAddingTag,
            onConfirm: onConfirmTag,
            onRemove: onRemoveTag,
          ),
        ),
      ],
    );
  }
}

class _TagEditor extends StatelessWidget {
  const _TagEditor({
    required this.tags,
    required this.controller,
    required this.isAdding,
    required this.onStartAdding,
    required this.onConfirm,
    required this.onRemove,
  });

  final List<String> tags;
  final TextEditingController controller;
  final bool isAdding;
  final VoidCallback onStartAdding;
  final VoidCallback onConfirm;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tag in tags)
          InputChip(
            key: ValueKey('tag-chip-$tag'),
            label: Text(tag),
            onDeleted: () => onRemove(tag),
            deleteIcon: const Icon(Icons.close, size: 16),
            backgroundColor: colors.background,
            side: BorderSide(color: colors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        if (isAdding)
          SizedBox(
            width: 132,
            child: TextField(
              key: const ValueKey('tag-input'),
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onConfirm(),
              decoration: InputDecoration(
                hintText: l10n.text('newNovel.tags'),
                suffixIcon: IconButton(
                  key: const ValueKey('confirm-tag'),
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check, size: 18),
                ),
              ),
            ),
          )
        else
          OutlinedButton.icon(
            key: const ValueKey('add-tag'),
            onPressed: onStartAdding,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.text('newNovel.addTag')),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.muted,
              side: BorderSide(color: colors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}

class _LabeledControl extends StatelessWidget {
  const _LabeledControl({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

String _initialOption(
  String value,
  List<String> options,
  TextEditingController customController,
) {
  if (value.isEmpty || options.contains(value)) {
    return value.isEmpty ? options.first : value;
  }
  customController.text = value;
  return options.last;
}

String _selectedValue(
  String? selected,
  TextEditingController customController,
  String customOption,
) {
  if (selected == null) {
    return '';
  }
  if (selected != customOption) {
    return selected;
  }
  return customController.text.trim();
}
