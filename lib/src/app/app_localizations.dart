import 'package:flutter/widgets.dart';

enum AppLanguage {
  zhCn(Locale('zh', 'CN'), '简体中文', 'zh-CN'),
  en(Locale('en'), 'English', 'en');

  const AppLanguage(this.locale, this.displayName, this.code);

  final Locale locale;
  final String displayName;
  final String code;
}

class AppLocalizations {
  const AppLocalizations(this.language);

  final AppLanguage language;

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLanguage.zhCn);
  }

  bool get isEnglish => language == AppLanguage.en;

  String text(String key) {
    final table = isEnglish ? _en : _zhCn;
    return table[key] ?? _zhCn[key] ?? key;
  }

  String date(DateTime date) {
    if (isEnglish) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return '${date.year}-${_two(date.month)}-${_two(date.day)} · '
          '${weekdays[date.weekday - 1]}';
    }

    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return '${date.year}年${date.month}月${date.day}日 · '
        '${weekdays[date.weekday - 1]}';
  }

  String projectStats(int projectCount, String words, {String? suffix}) {
    if (isEnglish) {
      final chapter = suffix == null || suffix.isEmpty ? '' : ' · $suffix';
      return '$projectCount projects · $words words$chapter';
    }
    final chapter = suffix == null || suffix.isEmpty ? '' : suffix;
    return '$projectCount 个项目 · 总字数 $words$chapter';
  }

  String goalProgress(int currentWords, int targetWords) {
    if (isEnglish) {
      return '$currentWords / $targetWords words';
    }
    return '$currentWords / $targetWords';
  }

  String searchEmpty(String query) {
    if (isEnglish) {
      return 'No novel projects match "$query"';
    }
    return '没有匹配“$query”的小说项目';
  }

  String tenThousands(String value) {
    return isEnglish ? '${value}0k' : '$value万';
  }

  String novelDetailLabel(String label, String value) {
    return isEnglish ? '$label: $value' : '$label：$value';
  }

  String unsetField(String fieldKey) {
    if (isEnglish) {
      return text('unset.$fieldKey');
    }
    return text('unset.$fieldKey');
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLanguage.values.any(
      (language) => language.locale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final language = AppLanguage.values.firstWhere(
      (language) => language.locale.languageCode == locale.languageCode,
      orElse: () => AppLanguage.zhCn,
    );
    return AppLocalizations(language);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _zhCn = {
  'app.title': 'AI 小说工坊',
  'app.subtitle': '智能小说创作平台',
  'brand.mark': '墨',
  'dashboard.welcome': '欢迎回来',
  'theme.light': '切换浅色模式',
  'theme.dark': '切换深色模式',
  'settings': '设置',
  'action.bookBreakdown': '拆书',
  'settings.close': '关闭设置',
  'settings.general': '通用',
  'settings.appearance': '外观',
  'settings.editor': '编辑器',
  'settings.aiAssistant': 'AI助手',
  'settings.aiProvider': 'AI供应商',
  'settings.aiModel': '智能体',
  'settings.dream': '梦境',
  'settings.usage': '用量',
  'settings.storage': '存储',
  'settings.about': '关于',
  'settings.pending': '该设置页将在后续步骤中完善。',
  'aiProvider.requiredToStart': '请先填写 API Key、基础 URL 并选择模型。',
  'settings.language': '语言',
  'settings.language.description': '选择应用界面语言。',
  'appearance.themeMode': '主题模式',
  'appearance.themeMode.description': '选择浅色、深色或跟随系统。',
  'appearance.light': '浅色',
  'appearance.dark': '深色',
  'appearance.system': '跟随系统',
  'appearance.theme': '主题',
  'appearance.theme.description': '选择应用主题风格。',
  'appearance.background': '应用背景',
  'appearance.background.description': '为整个应用设置互斥的纯色或图片背景。',
  'appearance.solidBackground': '纯色背景',
  'appearance.imageBackground': '图片背景',
  'appearance.fillMode': '背景填充模式',
  'appearance.builtInBackground': '内置背景',
  'appearance.customBackground': '自定义背景',
  'appearance.noBackground': '无背景',
  'appearance.noCustomImage': '未设置背景图片',
  'appearance.chooseImage': '选择图片',
  'appearance.fit.cover': '裁剪填满界面',
  'appearance.fit.contain': '完整显示',
  'appearance.fit.fill': '拉伸填充',
  'appearance.fit.tile': '平铺',
  'visualTheme.mirroric': 'Mirroric',
  'visualTheme.mirroric.description': '温暖文艺，如烛光下的陈年纸页',
  'visualTheme.manuscript': '手稿',
  'visualTheme.manuscript.description': '暖调羊皮纸与靛蓝墨痕，如学者的手稿',
  'visualTheme.ink': '水墨',
  'visualTheme.ink.description': '传统中国水墨画意，宣纸底色配朱砂点缀',
  'visualTheme.classic': '经典',
  'visualTheme.classic.description': '极简、永恒、高对比度',
  'visualTheme.azure': '碧空',
  'visualTheme.azure.description': '明净而宁静，如晴空万里',
  'visualTheme.jade': '翠色',
  'visualTheme.jade.description': '郁郁葱葱，如晨间花园',
  'visualTheme.violet': '紫罗兰',
  'visualTheme.violet.description': '细腻而富有表现力，如书页间压好的花朵',
  'visualTheme.ember': '余烬',
  'visualTheme.ember.description': '温暖宜人，如壁炉中的火光',
  'visualTheme.rose': '深红',
  'visualTheme.rose.description': '浓郁而热烈，如经年摩挲的皮革书脊',
  'visualTheme.ivory': '象牙',
  'visualTheme.ivory.description': '温柔而雅致，如陈年纸与乳脂',
  'visualTheme.starCloud': '星云',
  'visualTheme.starCloud.description': '浩瀚而璀璨，如薄夜星空',
  'background.vellum': '素纸',
  'background.distantMountain': '远山',
  'background.starrySky': '星空',
  'background.northernMist': '北雾',
  'background.bareTree': '枯树',
  'background.plumShadow': '梅影',
  'background.loneBoat': '孤舟',
  'action.newNovel': '新建小说',
  'action.importNovel': '导入小说',
  'action.continueWriting': '继续写作',
  'action.more': '更多',
  'action.create': '创建',
  'action.save': '保存',
  'action.cancel': '取消',
  'dashboard.loading.label': '正在加载',
  'dashboard.loading.title': '正在读取本地创作数据',
  'dashboard.loading.description': '请稍候',
  'dashboard.firstUse.label': '开始创作',
  'dashboard.firstUse.title': '还没有小说项目',
  'dashboard.firstUse.description': '创建或导入一个小说项目后，可以在这里继续写作。',
  'dashboard.populated.label': '继续上次',
  'dashboard.populated.titleFallback': '选择一本小说继续创作',
  'dashboard.selectProject.label': '选择项目',
  'dashboard.todayGoal': '今日写作目标',
  'dashboard.goalUnset': '未设置',
  'dashboard.goalEmpty': '没有今日目标',
  'dashboard.projectCount': '小说项目',
  'dashboard.totalWords': '总字数',
  'dashboard.myNovels': '我的小说',
  'dashboard.searchHint': '搜索小说...',
  'dashboard.emptyTitle': '暂无小说项目',
  'dashboard.emptyDescription': '创建或导入一个小说项目后，会显示在这里。',
  'dashboard.noSummary': '暂无简介',
  'dashboard.unsetType': '未设置类型',
  'detail.noSummary': '暂无简介',
  'detail.words': '字数',
  'detail.category': '分类',
  'detail.workType': '作品类型',
  'detail.tags': '标签',
  'detail.status': '状态',
  'unset.category': '未设置分类',
  'unset.workType': '未设置类型',
  'unset.tags': '未设置标签',
  'unset.status': '未设置状态',
  'newNovel.title': '新建作品',
  'newNovel.editTitle': '编辑作品信息',
  'newNovel.cover': '封面',
  'newNovel.chooseCover': '选择封面',
  'newNovel.changeCover': '更换封面',
  'newNovel.removeCover': '移除封面',
  'newNovel.name': '作品名称',
  'newNovel.nameHint': '请输入作品名称',
  'newNovel.nameRequired': '请输入作品名称',
  'newNovel.summary': '简介描述',
  'newNovel.summaryHint': '请输入简介描述',
  'newNovel.category': '分类',
  'newNovel.categoryHint': '请选择分类',
  'newNovel.customCategory': '自定义分类',
  'newNovel.customCategoryHint': '请输入自定义分类',
  'newNovel.customCategoryRequired': '请输入自定义分类',
  'newNovel.workType': '作品类型',
  'newNovel.workTypeHint': '请选择作品类型',
  'newNovel.customWorkType': '自定义作品类型',
  'newNovel.customWorkTypeHint': '请输入自定义作品类型',
  'newNovel.customWorkTypeRequired': '请输入自定义作品类型',
  'newNovel.tags': '标签',
  'newNovel.addTag': '添加标签',
  'file.novel': '小说文件',
  'webPreview.importUnavailable': 'Web 预览暂不连接本地文件导入',
};

const _en = {
  'app.title': 'AI Novel Studio',
  'app.subtitle': 'Intelligent novel creation platform',
  'brand.mark': 'AI',
  'dashboard.welcome': 'Welcome back',
  'theme.light': 'Switch to light mode',
  'theme.dark': 'Switch to dark mode',
  'settings': 'Settings',
  'action.bookBreakdown': 'Deconstruct',
  'settings.close': 'Close settings',
  'settings.general': 'General',
  'settings.appearance': 'Appearance',
  'settings.editor': 'Editor',
  'settings.aiAssistant': 'AI Assistant',
  'settings.aiProvider': 'AI Providers',
  'settings.aiModel': 'Agents',
  'settings.dream': 'Dreams',
  'settings.usage': 'Usage',
  'settings.storage': 'Storage',
  'settings.about': 'About',
  'settings.pending': 'This settings page will be completed in a later step.',
  'aiProvider.requiredToStart':
      'Enter API key, base URL, and choose a model first.',
  'settings.language': 'Language',
  'settings.language.description': 'Choose the application interface language.',
  'appearance.themeMode': 'Theme Mode',
  'appearance.themeMode.description': 'Choose light, dark, or system mode.',
  'appearance.light': 'Light',
  'appearance.dark': 'Dark',
  'appearance.system': 'System',
  'appearance.theme': 'Theme',
  'appearance.theme.description': 'Choose the application theme style.',
  'appearance.background': 'Application Background',
  'appearance.background.description':
      'Set a mutually exclusive solid or image background for the app.',
  'appearance.solidBackground': 'Solid Background',
  'appearance.imageBackground': 'Image Background',
  'appearance.fillMode': 'Background Fill Mode',
  'appearance.builtInBackground': 'Built-in Backgrounds',
  'appearance.customBackground': 'Custom Background',
  'appearance.noBackground': 'No background',
  'appearance.noCustomImage': 'No background image selected',
  'appearance.chooseImage': 'Choose Image',
  'appearance.fit.cover': 'Crop to Fill',
  'appearance.fit.contain': 'Show Entire Image',
  'appearance.fit.fill': 'Stretch to Fill',
  'appearance.fit.tile': 'Tile',
  'visualTheme.mirroric': 'Mirroric',
  'visualTheme.mirroric.description':
      'Warm and literary, like aged pages under candlelight',
  'visualTheme.manuscript': 'Manuscript',
  'visualTheme.manuscript.description':
      'Warm parchment with indigo ink, like a scholar\'s manuscript',
  'visualTheme.ink': 'Ink',
  'visualTheme.ink.description':
      'Traditional ink-wash calm with cinnabar accents',
  'visualTheme.classic': 'Classic',
  'visualTheme.classic.description': 'Minimal, timeless, and high contrast',
  'visualTheme.azure': 'Azure',
  'visualTheme.azure.description': 'Clear and quiet, like an open sky',
  'visualTheme.jade': 'Jade',
  'visualTheme.jade.description': 'Fresh and green, like a morning garden',
  'visualTheme.violet': 'Violet',
  'visualTheme.violet.description':
      'Delicate and expressive, like pressed flowers between pages',
  'visualTheme.ember': 'Ember',
  'visualTheme.ember.description': 'Warm and comfortable, like a hearth glow',
  'visualTheme.rose': 'Deep Rose',
  'visualTheme.rose.description':
      'Rich and warm, like a well-worn leather spine',
  'visualTheme.ivory': 'Ivory',
  'visualTheme.ivory.description':
      'Soft and elegant, like aged paper and cream',
  'visualTheme.starCloud': 'Star Cloud',
  'visualTheme.starCloud.description':
      'Vast and luminous, like stars in a thin night sky',
  'background.vellum': 'Vellum',
  'background.distantMountain': 'Distant Mountain',
  'background.starrySky': 'Starry Sky',
  'background.northernMist': 'Northern Mist',
  'background.bareTree': 'Bare Tree',
  'background.plumShadow': 'Plum Shadow',
  'background.loneBoat': 'Lone Boat',
  'action.newNovel': 'New Novel',
  'action.importNovel': 'Import Novel',
  'action.continueWriting': 'Continue Writing',
  'action.more': 'More',
  'action.create': 'Create',
  'action.save': 'Save',
  'action.cancel': 'Cancel',
  'dashboard.loading.label': 'Loading',
  'dashboard.loading.title': 'Reading local writing data',
  'dashboard.loading.description': 'Please wait',
  'dashboard.firstUse.label': 'Start Writing',
  'dashboard.firstUse.title': 'No novel projects yet',
  'dashboard.firstUse.description':
      'Create or import a novel project, then continue writing here.',
  'dashboard.populated.label': 'Continue',
  'dashboard.populated.titleFallback': 'Choose a novel to continue writing',
  'dashboard.selectProject.label': 'Choose Project',
  'dashboard.todayGoal': 'Today\'s Writing Goal',
  'dashboard.goalUnset': 'Not set',
  'dashboard.goalEmpty': 'No goal today',
  'dashboard.projectCount': 'Novel Projects',
  'dashboard.totalWords': 'Total Words',
  'dashboard.myNovels': 'My Novels',
  'dashboard.searchHint': 'Search novels...',
  'dashboard.emptyTitle': 'No novel projects',
  'dashboard.emptyDescription':
      'Create or import a novel project, and it will appear here.',
  'dashboard.noSummary': 'No summary yet',
  'dashboard.unsetType': 'Type not set',
  'detail.noSummary': 'No summary yet',
  'detail.words': 'Words',
  'detail.category': 'Category',
  'detail.workType': 'Work Type',
  'detail.tags': 'Tags',
  'detail.status': 'Status',
  'unset.category': 'Category not set',
  'unset.workType': 'Type not set',
  'unset.tags': 'Tags not set',
  'unset.status': 'Status not set',
  'newNovel.title': 'New Work',
  'newNovel.editTitle': 'Edit Work Info',
  'newNovel.cover': 'Cover',
  'newNovel.chooseCover': 'Choose Cover',
  'newNovel.changeCover': 'Change Cover',
  'newNovel.removeCover': 'Remove Cover',
  'newNovel.name': 'Work Name',
  'newNovel.nameHint': 'Enter a work name',
  'newNovel.nameRequired': 'Enter a work name',
  'newNovel.summary': 'Summary',
  'newNovel.summaryHint': 'Enter a summary',
  'newNovel.category': 'Category',
  'newNovel.categoryHint': 'Choose a category',
  'newNovel.customCategory': 'Custom Category',
  'newNovel.customCategoryHint': 'Enter a custom category',
  'newNovel.customCategoryRequired': 'Enter a custom category',
  'newNovel.workType': 'Work Type',
  'newNovel.workTypeHint': 'Choose a work type',
  'newNovel.customWorkType': 'Custom Work Type',
  'newNovel.customWorkTypeHint': 'Enter a custom work type',
  'newNovel.customWorkTypeRequired': 'Enter a custom work type',
  'newNovel.tags': 'Tags',
  'newNovel.addTag': 'Add Tag',
  'file.novel': 'Novel Files',
  'webPreview.importUnavailable': 'Web preview is not connected to file import',
};
