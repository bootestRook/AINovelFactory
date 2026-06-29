import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../app/app_theme.dart';

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

class _NewNovelDialog extends StatefulWidget {
  const _NewNovelDialog();

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
                  '新建作品',
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
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('创建'),
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
      category: _selectedValue(_category, _customCategoryController),
      workType: _selectedValue(_workType, _customWorkTypeController),
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
  });

  final String? coverPath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final path = coverPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '封面',
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
          label: const Text('选择封面'),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledControl(
          label: '作品名称',
          child: TextFormField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '请输入作品名称'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入作品名称';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        _LabeledControl(
          label: '简介描述',
          child: TextFormField(
            controller: summaryController,
            minLines: 4,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '请输入简介描述'),
          ),
        ),
        const SizedBox(height: 14),
        _LabeledControl(
          label: '分类',
          child: _SelectField(
            label: '分类',
            value: category,
            hint: '请选择分类',
            options: novelCategories,
            onChanged: onCategoryChanged,
          ),
        ),
        if (category == '自定义新增') ...[
          const SizedBox(height: 10),
          _LabeledControl(
            label: '自定义分类',
            child: TextFormField(
              controller: customCategoryController,
              decoration: const InputDecoration(hintText: '请输入自定义分类'),
              validator: (value) {
                if (category == '自定义新增' &&
                    (value == null || value.trim().isEmpty)) {
                  return '请输入自定义分类';
                }
                return null;
              },
            ),
          ),
        ],
        const SizedBox(height: 14),
        _LabeledControl(
          label: '作品类型',
          child: _SelectField(
            label: '作品类型',
            value: workType,
            hint: '请选择作品类型',
            options: novelWorkTypes,
            onChanged: onWorkTypeChanged,
          ),
        ),
        if (workType == '自定义新增') ...[
          const SizedBox(height: 10),
          _LabeledControl(
            label: '自定义作品类型',
            child: TextFormField(
              controller: customWorkTypeController,
              decoration: const InputDecoration(hintText: '请输入自定义作品类型'),
              validator: (value) {
                if (workType == '自定义新增' &&
                    (value == null || value.trim().isEmpty)) {
                  return '请输入自定义作品类型';
                }
                return null;
              },
            ),
          ),
        ],
        const SizedBox(height: 14),
        _LabeledControl(
          label: '标签',
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
                hintText: '标签',
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
            label: const Text('添加标签'),
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

class _SelectField extends StatefulWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  State<_SelectField> createState() => _SelectFieldState();
}

class _SelectFieldState extends State<_SelectField> {
  static const _itemHeight = 48.0;
  static const _visibleItems = 4;

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(colors.card),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(8),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          menuChildren: [
            SizedBox(
              key: ValueKey('select-menu-${widget.label}'),
              width: constraints.maxWidth,
              height: _itemHeight *
                  (widget.options.length < _visibleItems
                      ? widget.options.length
                      : _visibleItems),
              child: Scrollbar(
                key: ValueKey('select-scrollbar-${widget.label}'),
                controller: _scrollController,
                thumbVisibility: widget.options.length > _visibleItems,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemExtent: _itemHeight,
                  primary: false,
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final selected = option == widget.value;

                    return Builder(
                      builder: (context) {
                        return InkWell(
                          onTap: () {
                            widget.onChanged(option);
                            MenuController.maybeOf(context)?.close();
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            color: selected
                                ? colors.line.withValues(alpha: 0.5)
                                : colors.card,
                            child: Text(
                              option,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.text),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          builder: (context, controller, child) {
            final currentValue = widget.value;

            return InkWell(
              key: ValueKey('select-field-${widget.label}'),
              onTap: () {
                controller.isOpen ? controller.close() : controller.open();
              },
              child: InputDecorator(
                isEmpty: currentValue == null || currentValue.isEmpty,
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentValue == null || currentValue.isEmpty
                            ? widget.hint
                            : currentValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: currentValue == null || currentValue.isEmpty
                              ? colors.muted
                              : colors.text,
                        ),
                      ),
                    ),
                    Icon(
                      controller.isOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _selectedValue(
    String? selected, TextEditingController customController) {
  if (selected == null) {
    return '';
  }
  if (selected != '自定义新增') {
    return selected;
  }
  return customController.text.trim();
}
