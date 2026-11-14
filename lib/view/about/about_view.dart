// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../models/navigation_models.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../view_models/providers/settings_provider.dart';
import '../home/rapper.dart';
import '../main/screens.dart';

/// App version shown on the About page. Keep in sync with pubspec.yaml.
const String kAppVersion = '1.0.0+1';

/// "About & Help" — laid out like documentation, not like a pile of cards.
///
/// Desktop: two-pane docs layout (sticky table of contents on the left,
/// scrolling article on the right). Mobile/tablet: a single scrolling
/// document with numbered doc sections.
///
/// The navigation shortcut labels are computed from the live nav list, so they
/// stay correct when the optional Repairs module is turned on or off.
class AboutView extends ConsumerStatefulWidget {
  const AboutView({super.key});

  @override
  ConsumerState<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends ConsumerState<AboutView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final Map<String, GlobalKey> _sectionKeys = {
    'overview': GlobalKey(),
    'features': GlobalKey(),
    'shortcuts': GlobalKey(),
    'howto': GlobalKey(),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  void _jump(String sectionId) {
    final target = _sectionKeys[sectionId]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        alignment: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showRepairs = ref.watch(
      settingsProvider.select((s) => s.showRepairsModule),
    );
    final showShoppingList = ref.watch(
      settingsProvider.select((s) => s.showShoppingListModule),
    );
    final useMultiCart = ref.watch(
      settingsProvider.select((s) => s.useMultiCart),
    );
    final navItems = navItemsFor(showRepairs: showRepairs);

    // Live F-key labels for each nav section (F1–F10, then F12 for the 11th).
    final navKeys = <String, String>{
      for (var i = 0; i < navItems.length; i++)
        navItems[i].label: i < 10 ? 'F${i + 1}' : 'F12',
    };

    final modules = _buildModules(
      navKeys: navKeys,
      showRepairs: showRepairs,
      showShoppingList: showShoppingList,
      useMultiCart: useMultiCart,
    );
    final shortcuts = _buildShortcuts(navItems: navItems);

    final q = _query.trim().toLowerCase();
    final filteredModules =
        q.isEmpty
            ? modules
            : modules.where((m) => m.matches(q)).toList(growable: false);
    final filteredShortcuts =
        q.isEmpty
            ? shortcuts
            : shortcuts.where((s) => s.matches(q)).toList(growable: false);
    final filteredTasks =
        q.isEmpty
            ? _quickTasks
            : _quickTasks.where((t) => t.matches(q)).toList(growable: false);

    final article = _buildArticle(
      modules: filteredModules,
      shortcuts: filteredShortcuts,
      tasks: filteredTasks,
      query: _query,
    );

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'About & Help',
        context: context,
        actions: [
          IconButton(
            tooltip: 'Quick shortcuts',
            onPressed: () => _showShortcutSummary(context),
            icon: const Icon(Icons.keyboard_outlined),
          ),
          SizedBox(width: 6.w),
        ],
      ),
      // Docs layout: sticky in-page navigation on the left, article on the
      // right — the two-pane pattern of real documentation sites.
      body: ResponsiveWrapper(
        mobile: article,
        tablet: article,
        desktop: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 220.w,
              decoration: BoxDecoration(
                color: _isDark ? AppColors.dScafoldColor : Colors.white,
                border: Border(
                  right: BorderSide(
                    color: _isDark ? Colors.white12 : AppColors.border,
                  ),
                ),
              ),
              child: _buildTableOfContents(filteredModules),
            ),
            Expanded(child: article),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- article

  Widget _buildArticle({
    required List<_ModuleDoc> modules,
    required List<_ShortcutDoc> shortcuts,
    required List<_TaskDoc> tasks,
    required String query,
  }) {
    return Center(
      child: ConstrainedBox(
        // Scales with the app's ScreenUtil sizing like every other page.
        constraints: BoxConstraints(maxWidth: 760.w),
        child: ListView(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
          children: [
            _docSection(
              'overview',
              'Overview',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(),
                  SizedBox(height: 20.h),
                  ..._overviewParagraphs(),
                ],
              ),
            ),
            if (modules.isNotEmpty)
              _docSection(
                'features',
                'Features',
                subtitle:
                    'Every module, what it does, and exactly where to find it.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final m in modules) _moduleEntry(m)],
                ),
              ),
            if (shortcuts.isNotEmpty)
              _docSection(
                'shortcuts',
                'Keyboard shortcuts',
                subtitle: 'Press F11 anywhere for a quick reminder.',
                child: _shortcutTable(shortcuts),
              ),
            if (tasks.isNotEmpty)
              _docSection(
                'howto',
                'How do I…',
                subtitle: 'Common jobs and the exact path to them.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < tasks.length; i++)
                      _taskEntry(i + 1, tasks[i]),
                  ],
                ),
              ),
            if (modules.isEmpty &&
                shortcuts.isEmpty &&
                tasks.isEmpty &&
                query.trim().isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 16.spMin,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Nothing matched "$query".',
                      style: TextStyle(
                        fontSize: 12.spMin,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 32.h),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- content

  List<_ModuleDoc> _buildModules({
    required Map<String, String> navKeys,
    required bool showRepairs,
    required bool showShoppingList,
    required bool useMultiCart,
  }) {
    final modules = <_ModuleDoc>[
      _ModuleDoc(
        icon: TablerIcons.home,
        title: 'Home',
        navKey: navKeys['Home'],
        what:
            'Your starting point. Shows your products grouped by category, with '
            'three floating buttons for the fastest actions in the app.',
        where: 'Sidebar → Home',
        actions: [
          'Floating button "Add Product" (bottom-right) → new item form',
          'Floating button "Add Services" (bottom-right) → new service form',
          'Floating button "Shopping List" → restock list (if the module is on)',
          'App bar → "Add Items" button opens the new item form too',
          'Ctrl+N adds an item, Ctrl+P prints the current bill',
        ],
      ),
      _ModuleDoc(
        icon: TablerIcons.shopping_bag,
        title: 'Sales',
        navKey: navKeys['Sales'],
        what:
            useMultiCart
                ? 'Ring up a sale. Multi-cart mode is ON: you can keep several '
                    'carts open at once (e.g. one per customer) and switch between '
                    'them before completing each sale.'
                : 'Ring up a sale. Tap a product to add it to the cart, adjust '
                    'quantity, apply a discount, choose the customer and take '
                    'payment.',
        where: 'Sidebar → Sales',
        actions: [
          'Tap a product card — or press F1–F9 / 1–9 — to add it to the cart',
          'Cart → "Complete Sale" → customer & payment screen',
          'Cart → clear icon to empty the cart',
          'Out-of-stock products are blocked with a warning',
        ],
      ),
      _ModuleDoc(
        icon: TablerIcons.receipt,
        title: 'Receipts (Bills)',
        navKey: navKeys['Receipts'],
        what:
            'Every invoice you have created. Search, filter by date/status, open '
            'a bill, print it, save it as a PDF, share it or delete it.',
        where: 'Sidebar → Receipts',
        actions: [
          'Click a row to open that bill',
          'Select one row, then Ctrl+P → prints it immediately',
          'On the bill: ⋯ menu → Edit, Delete, Save PDF, Share, Select Printer, Print Thermal',
          'On mobile the bill has a bottom bar: Print · Save PDF · Share',
        ],
      ),
      _ModuleDoc(
        icon: TablerIcons.users,
        title: 'Customers',
        navKey: navKeys['Customers'],
        what:
            'Your customer book: names, phone numbers, addresses, outstanding '
            'balances and each customer\'s purchase history.',
        where: 'Sidebar → Customers',
        actions: [
          'Add / edit a customer from the list',
          'Open a customer to see their bills and balance',
        ],
      ),
      if (showRepairs)
        _ModuleDoc(
          icon: TablerIcons.tool,
          title: 'Repairs',
          navKey: navKeys['Repairs'],
          what:
              'Take a client\'s device (laptop, phone, etc.) in for repair, '
              'record the fault, the agreed charge and track the job status '
              'until it is returned.',
          where: 'Sidebar → Repairs',
          actions: [
            'New repair → device + customer + fault + charge',
            'Update status as the job moves along',
          ],
        ),
      _ModuleDoc(
        icon: TablerIcons.bell,
        title: 'Reminders',
        navKey: navKeys['Reminders'],
        what:
            'Follow-ups you do not want to forget: due payments, service '
            'pickups, call-backs. A dot appears on the sidebar icon when '
            'something is pending.',
        where: 'Sidebar → Reminders',
        actions: ['Create a reminder with a date', 'Mark it done when handled'],
      ),
      _ModuleDoc(
        icon: Icons.person_4_outlined,
        title: 'Profile',
        navKey: navKeys['Profile'],
        what:
            'Your shop\'s identity. This is what gets printed on every bill and '
            'purchase agreement: shop name, owner name, phone, address, logo '
            'and the "PAID" stamp.',
        where: 'Sidebar → Profile',
        actions: [
          'Edit shop details and upload a logo',
          'The logo is reused on bills and agreements automatically',
        ],
      ),
      _ModuleDoc(
        icon: TablerIcons.report_money,
        title: 'Expenses',
        navKey: navKeys['Expenses'],
        what:
            'Money going out: rent, bills, transport, stock purchases. Recording '
            'these makes the profit numbers on the Dashboard real.',
        where: 'Sidebar → Expenses',
        actions: [
          'Add an expense with amount, category, date and note',
          'Categories are managed here too',
        ],
      ),
      _ModuleDoc(
        icon: TablerIcons.chart_pie,
        title: 'Dashboard',
        navKey: navKeys['Dashboard'],
        what:
            'The numbers side of the shop: sales over time, expenses, profit, '
            'best-selling products and stock health — in charts.',
        where: 'Sidebar → Dashboard',
        actions: ['Switch the period to compare days / weeks / months'],
      ),
      _ModuleDoc(
        icon: TablerIcons.shopping_cart,
        title: 'Purchases (Local Purchase Agreements)',
        navKey: navKeys['Purchases'],
        what:
            'Use this when YOU buy items from a local person — the opposite of a '
            'sale. It records the seller\'s name, phone, ID card number and '
            'address, the items with quantity and price, the total, the payment '
            'type, both signatures (seller + shop owner) and the terms & '
            'conditions. It prints as a proper A4 agreement.',
        where: 'Sidebar → Purchases',
        actions: [
          'Ctrl+N → new agreement',
          'Ctrl+I → add another item row (or the "Add Item" button)',
          'Ctrl+S → save the agreement you are editing',
          'Ctrl+P → print it (Print · Save PDF · Share bar on mobile)',
          'Terms & conditions come from Settings → Purchase Agreement',
          'List: search, multi-select and delete old agreements',
        ],
      ),
      _ModuleDoc(
        icon: TablerIcons.settings,
        title: 'Settings',
        navKey: navKeys['Settings'],
        what:
            'Everything configurable lives here, grouped into collapsible cards.',
        where: 'Sidebar → Settings',
        actions: [
          'General Settings → auto-print after a sale + print format (PDF or USB thermal)',
          'Modules → turn the Shopping List and Repairs modules on/off',
          'Bill Settings → bill design, thermal receipt design',
          'Purchase Agreement → the terms & conditions printed on new agreements',
          'Theme → light / dark / system, app colour, icon style',
          'Paths → where your data folder lives (with migration)',
          'Data Management → backup, restore and export your data',
          'Screen Management / Home Page Settings → choose which fields and sections appear',
        ],
      ),
      if (showShoppingList)
        _ModuleDoc(
          icon: TablerIcons.clipboard_list,
          title: 'Shopping List',
          what:
              'A simple restock list. Add what you need to buy, tick items off '
              'as you get them, and print the list before you go out.',
          where: 'Home → floating "Shopping List" button',
          actions: ['Ctrl+P → print the current list'],
        ),
      _ModuleDoc(
        icon: TablerIcons.package,
        title: 'Add / Edit Product',
        what:
            'The product form: name, category, brand, barcode, cost price, '
            'selling price, stock, reorder level (for low-stock warnings) and an '
            'image. Products can be goods or services.',
        where: 'Home → "Add Product"  ·  or a product card → Edit',
        actions: [
          'Reorder level turns the stock badge red when you are running low',
          'Delete a product from its details page → ⋯ → Delete Product',
        ],
      ),
    ];
    return modules;
  }

  List<_ShortcutDoc> _buildShortcuts({required List<NavigationItem> navItems}) {
    final navRows = <_ShortcutDoc>[];
    for (var i = 0; i < navItems.length; i++) {
      navRows.add(
        _ShortcutDoc(
          keys: [i < 10 ? 'F${i + 1}' : 'F12'],
          action: 'Open ${navItems[i].label}',
          where: 'Anywhere (not while typing in the Sales search box)',
        ),
      );
    }

    return [
      ...navRows,
      const _ShortcutDoc(
        keys: ['F11'],
        action: 'Show the keyboard shortcuts dialog',
        where: 'Anywhere',
      ),
      const _ShortcutDoc(
        keys: ['F1', 'F2', '…', 'F9'],
        action: 'Add product 1–9 to the cart',
        where: 'Sales screen only (overrides the section jump)',
      ),
      const _ShortcutDoc(
        keys: ['1', '2', '…', '9'],
        action: 'Add product 1–9 to the cart (also numpad 1–9)',
        where: 'Sales screen only',
      ),
      const _ShortcutDoc(
        keys: ['Ctrl', 'N'],
        action: 'New product  ·  New purchase agreement',
        where: 'Home  ·  Purchases list',
      ),
      const _ShortcutDoc(
        keys: ['Ctrl', 'S'],
        action: 'Save the item you are editing',
        where: 'Home  ·  Purchase agreement form',
      ),
      const _ShortcutDoc(
        keys: ['Ctrl', 'I'],
        action: 'Add another item row',
        where: 'Purchase agreement form',
      ),
      const _ShortcutDoc(
        keys: ['Ctrl', 'P'],
        action: 'Print',
        where:
            'Receipts list (selected bill)  ·  Bill detail  ·  Purchase '
            'agreement  ·  Shopping list',
      ),
    ];
  }

  static const List<_TaskDoc> _quickTasks = [
    _TaskDoc(
      icon: TablerIcons.receipt_2,
      task: 'Make a bill and hand it to the customer',
      path:
          'Sales → tap the products (or F1–F9) → cart "Complete Sale" → pick '
          'customer & payment → "Save & Complete Sale". The bill opens by '
          'itself; then Print / Save PDF / Share.',
    ),
    _TaskDoc(
      icon: TablerIcons.printer,
      task: 'Print an old bill',
      path:
          'Receipts → select the bill row → Ctrl+P. Or open the bill and press '
          'Ctrl+P / tap Print.',
    ),
    _TaskDoc(
      icon: TablerIcons.share,
      task: 'Send a bill on WhatsApp',
      path:
          'Open the bill → Share (bottom bar on mobile) → choose WhatsApp. The '
          'bill goes out as a PDF.',
    ),
    _TaskDoc(
      icon: TablerIcons.file_download,
      task: 'Keep a PDF copy of a bill',
      path: 'Open the bill → Save PDF. It is written to your invoices folder.',
    ),
    _TaskDoc(
      icon: TablerIcons.shopping_cart,
      task: 'Record buying stock from a local person',
      path:
          'Purchases → Ctrl+N → fill seller details, items, payment → sign → '
          'Save. Then Print to hand them a copy.',
    ),
    _TaskDoc(
      icon: TablerIcons.settings,
      task: 'Set up the printer / turn on auto-print',
      path:
          'Settings → General Settings → "Enable Print Bills" → choose Thermal '
          '(USB) or PDF. In the bill you can also pick the printer from the ⋯ '
          'menu.',
    ),
    _TaskDoc(
      icon: TablerIcons.device_floppy,
      task: 'Back up my shop data',
      path:
          'Settings → Data Management. You can also see (and change) the data '
          'folder under Settings → Paths.',
    ),
    _TaskDoc(
      icon: TablerIcons.toggle_right,
      task: 'Turn the Repairs module on or off',
      path:
          'Settings → Modules → Repairs. The sidebar and its F-key update instantly.',
    ),
  ];

  // ---------------------------------------------------------------- piecewy

  /// One documentation section: heading, thin rule, then the content. The
  /// [sectionId] links it to the table of contents for scrolling.
  Widget _docSection(
    String sectionId,
    String title, {
    String? subtitle,
    required Widget child,
  }) {
    return KeyedSubtree(
      key: _sectionKeys[sectionId],
      child: Padding(
        padding: EdgeInsets.only(bottom: 36.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 19.spMin, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3.h),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5.spMin,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 10.h),
            ],
            Container(
              height: 1,
              color: _isDark ? Colors.white12 : AppColors.border,
            ),
            SizedBox(height: 16.h),
            child,
          ],
        ),
      ),
    );
  }

  List<Widget> _overviewParagraphs() {
    final line = TextStyle(fontSize: 12.5.spMin, height: 1.6);
    return [
      RichText(
        text: TextSpan(
          style: line.copyWith(
            color: _isDark ? Colors.white70 : AppColors.textPrimary,
          ),
          children: [
            const TextSpan(
              text: 'My Shop',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  ' is an offline-first point-of-sale and shop inventory '
                  'system, built for computer repair and accessories shops. '
                  'Version ',
            ),
            TextSpan(
              text: kAppVersion,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
      SizedBox(height: 10.h),
      Text(
        'It handles the full daily cycle of a small shop: selling and billing, '
        'printing receipts (PDF or USB thermal), tracking stock, recording '
        'expenses, taking devices in for repair, and buying stock from local '
        'people with printable agreements. All data stays on this device in a '
        'folder you control — no internet connection is needed to sell, bill '
        'or print.',
        style: line.copyWith(
          color: _isDark ? Colors.white70 : AppColors.textPrimary,
        ),
      ),
      SizedBox(height: 10.h),
      Wrap(
        spacing: 6.w,
        runSpacing: 6.h,
        children: [
          _keyChip('Runs on desktop & mobile'),
          _keyChip('Works fully offline'),
          _keyChip('Local data storage'),
        ],
      ),
    ];
  }

  /// One module entry, documentation style: heading + F-key, "where" line,
  /// a paragraph, then the actions as a bulleted list. No card around it.
  Widget _moduleEntry(_ModuleDoc m) {
    return Padding(
      padding: EdgeInsets.only(bottom: 26.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.title,
                  style: TextStyle(
                    fontSize: 15.spMin,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (m.navKey != null) _keyChip(m.navKey!),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            m.where,
            style: TextStyle(
              fontSize: 11.spMin,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            m.what,
            style: TextStyle(
              fontSize: 12.5.spMin,
              height: 1.55,
              color: _isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
          if (m.actions.isNotEmpty) ...[
            SizedBox(height: 8.h),
            ...m.actions.map(_bullet),
          ],
        ],
      ),
    );
  }

  /// Bulleted list item with a small indented bullet — documentation look.
  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 6.w, top: 4.h, bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Container(
              width: 8.w,
              height: 2.h,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5.spMin,
                height: 1.5,
                color: _isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shortcut reference rendered as a real table: header row, divided rows,
  /// fixed keys column — like an API reference.
  Widget _shortcutTable(List<_ShortcutDoc> shortcuts) {
    final borderColor = _isDark ? Colors.white12 : AppColors.border;
    Widget headerCell(String text, {bool right = false}) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.spMin,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: _isDark ? 0.10 : 0.05),
              border: Border(bottom: BorderSide(color: borderColor)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
            ),
            child: Row(
              children: [
                SizedBox(width: 96.spMin, child: headerCell('KEYS')),
                Expanded(child: headerCell('WHAT IT DOES')),
                Expanded(child: headerCell('WHERE', right: true)),
              ],
            ),
          ),
          for (var i = 0; i < shortcuts.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _shortcutRowContainer(shortcuts[i]),
          ],
        ],
      ),
    );
  }

  Widget _shortcutRowContainer(_ShortcutDoc s) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96.spMin,
            child: Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: s.keys.map(_keyChip).toList(growable: false),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              s.action,
              style: TextStyle(
                fontSize: 12.spMin,
                fontWeight: FontWeight.w500,
                color: _isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: Text(
              s.where,
              style: TextStyle(
                fontSize: 10.5.spMin,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Numbered how-to entries, as in a step list of a documentation guide.
  Widget _taskEntry(int number, _TaskDoc t) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.spMin,
            height: 24.spMin,
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 11.spMin,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.task,
                  style: TextStyle(
                    fontSize: 13.spMin,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  t.path,
                  style: TextStyle(
                    fontSize: 11.5.spMin,
                    height: 1.5,
                    color: _isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small key-cap chip (kbd style), reused everywhere.
  Widget _keyChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5.spMin,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: 'Search the documentation…',
        hintStyle: TextStyle(
          fontSize: 12.5.spMin,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(Icons.search, size: 20.spMin),
        suffixIcon:
            _query.isEmpty
                ? null
                : IconButton(
                  icon: Icon(Icons.close, size: 18.spMin),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: _isDark ? AppColors.dScafoldColor : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: _isDark ? Colors.white24 : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: _isDark ? Colors.white24 : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  // ------------------------------------------------------- table of contents

  /// Sticky in-page navigation (desktop): every jump target of the doc.
  Widget _buildTableOfContents(List<_ModuleDoc> modules) {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 10.w),
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.w, bottom: 6.h),
          child: Text(
            'ON THIS PAGE',
            style: TextStyle(
              fontSize: 10.spMin,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        _tocItem('overview', 'Overview', Icons.description_outlined),
        _tocItem('features', 'Features', Icons.apps),
        // Feature sub-links (placemarks ▸ indented).
        for (final m in modules)
          Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: _tocItem('features', '· ${m.title}', null, isSubItem: true),
          ),
        _tocItem('shortcuts', 'Keyboard shortcuts', Icons.keyboard_outlined),
        _tocItem('howto', 'How do I…', Icons.help_outline),
      ],
    );
  }

  Widget _tocItem(
    String sectionId,
    String label,
    IconData? icon, {
    bool isSubItem = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: () => _jump(sectionId),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15.spMin, color: AppColors.textSecondary),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSubItem ? 11.spMin : 12.spMin,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- footer

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(height: 1, color: _isDark ? Colors.white12 : AppColors.border),
        SizedBox(height: 12.h),
        Row(
          children: [
            const Spacer(),
            _keyChip('My Shop v$kAppVersion'),
            SizedBox(width: 6.w),
            _keyChip('Press F11 for shortcuts'),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  void _showShortcutSummary(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Quick shortcuts'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('F1–F10 / F12  ·  jump to a section'),
                  SizedBox(height: 6),
                  Text('F11  ·  this help'),
                  SizedBox(height: 6),
                  Text('F1–F9 or 1–9  ·  add product to cart (Sales)'),
                  SizedBox(height: 6),
                  Text('Ctrl+N  ·  new product / purchase agreement'),
                  SizedBox(height: 6),
                  Text('Ctrl+S  ·  save'),
                  SizedBox(height: 6),
                  Text('Ctrl+P  ·  print'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

// ------------------------------------------------------------------ models

class _ModuleDoc {
  final IconData icon;
  final String title;
  final String what;
  final String where;
  final List<String> actions;
  final String? navKey;

  const _ModuleDoc({
    required this.icon,
    required this.title,
    required this.what,
    required this.where,
    this.actions = const [],
    this.navKey,
  });

  bool matches(String q) =>
      title.toLowerCase().contains(q) ||
      what.toLowerCase().contains(q) ||
      where.toLowerCase().contains(q) ||
      actions.any((a) => a.toLowerCase().contains(q));
}

class _ShortcutDoc {
  final List<String> keys;
  final String action;
  final String where;

  const _ShortcutDoc({
    required this.keys,
    required this.action,
    required this.where,
  });

  bool matches(String q) =>
      action.toLowerCase().contains(q) ||
      where.toLowerCase().contains(q) ||
      keys.any((k) => k.toLowerCase().contains(q));
}

class _TaskDoc {
  final IconData icon;
  final String task;
  final String path;

  const _TaskDoc({required this.icon, required this.task, required this.path});

  bool matches(String q) =>
      task.toLowerCase().contains(q) || path.toLowerCase().contains(q);
}
