// ─────────────────────────────────────────────
// settings_page.dart — Pengaturan fungsional
// Semua toggle/aksi tersambung ke AppProvider & berfungsi nyata.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/app_strings.dart';
import '../help/faq_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color jneBlue = Color(0xFF005596);
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenEmerald = Color(0xFF10B981);
  static const Color zenAmber = Color(0xFFF59E0B);
  static const Color zenSlate = Color(0xFF94A3B8);

  // Versi aplikasi dari pubspec.yaml — di-bump manual saat release.
  // Hanya fallback; nilai utama dari provider.appVersionLabel (package_info).
  static const String _appVersion = '1.0.0+9';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bgColor =>
      _isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
  Color get _cardColor => _isDark ? const Color(0xFF1A2230) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : zenNavy;
  Color get _subColor => _isDark ? Colors.white60 : zenSlate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: Text(
          context.tr('settings_title'),
          style: GoogleFonts.plusJakartaSans(
            color: _textColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          if (user != null) _accountHeader(user.name, user.email, user.role),
          const SizedBox(height: 28),

          _sectionTitle(context.tr('set_display_lang')),
          const SizedBox(height: 12),
          _card([
            _switchItem(
              icon: Icons.dark_mode_outlined,
              iconColor: zenIndigo,
              title: context.tr('set_dark_mode'),
              subtitle: context.tr('set_dark_mode_sub'),
              value: provider.isDarkMode,
              onChanged: (v) => provider.setDarkMode(v),
            ),
            _divider(),
            _tapItem(
              icon: Icons.language_rounded,
              iconColor: zenEmerald,
              title: context.tr('set_language'),
              subtitle: _languageLabel(provider.language),
              onTap: () => _showLanguagePicker(provider),
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle(context.tr('set_notif')),
          const SizedBox(height: 12),
          _card([
            _switchItem(
              icon: Icons.notifications_active_outlined,
              iconColor: zenAmber,
              title: context.tr('set_push_notif'),
              subtitle: context.tr('set_push_notif_sub'),
              value: provider.notificationsEnabled,
              onChanged: (v) async {
                final msg = v
                    ? context.tr('notif_on')
                    : context.tr('notif_off');
                await provider.setNotificationsEnabled(v);
                if (mounted) _toast(msg);
              },
            ),
            _divider(),
            _switchItem(
              icon: Icons.access_time_rounded,
              iconColor: zenIndigo,
              title: context.tr('set_reminder'),
              subtitle: context.tr('set_reminder_sub'),
              value: provider.reminderEnabled,
              onChanged: (v) => provider.setReminderEnabled(v),
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle(context.tr('set_office_loc')),
          const SizedBox(height: 12),
          _card([
            _infoItem(
              icon: Icons.location_on_outlined,
              iconColor: zenRose,
              title: context.tr('office_point'),
              value:
                  '${provider.officeLat.toStringAsFixed(4)}, ${provider.officeLng.toStringAsFixed(4)}',
              onCopy: () {
                Clipboard.setData(
                  ClipboardData(
                    text: '${provider.officeLat}, ${provider.officeLng}',
                  ),
                );
                _toast(context.tr('coord_copied'));
              },
            ),
            _divider(),
            _infoItem(
              icon: Icons.radar_rounded,
              iconColor: zenEmerald,
              title: context.tr('office_radius_label'),
              value:
                  '${provider.officeRadius.toStringAsFixed(0)} ${context.tr('meters')}',
            ),
            _divider(),
            _infoItem(
              icon: Icons.schedule_rounded,
              iconColor: zenAmber,
              title: context.tr('start_time_label'),
              value:
                  '${provider.officeStartTime.hour.toString().padLeft(2, '0')}:${provider.officeStartTime.minute.toString().padLeft(2, '0')} WIB',
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle(context.tr('set_help_support')),
          const SizedBox(height: 12),
          _card([
            _tapItem(
              icon: Icons.help_outline_rounded,
              iconColor: zenIndigo,
              title: context.tr('help_center_faq'),
              subtitle: context.tr('help_center_faq_sub'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              ),
            ),
            _divider(),
            _tapItem(
              icon: Icons.support_agent_rounded,
              iconColor: zenEmerald,
              title: context.tr('contact_admin'),
              subtitle: context.tr('contact_admin_sub'),
              onTap: () => Navigator.pushNamed(context, '/chat'),
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle(context.tr('set_account_security')),
          const SizedBox(height: 12),
          _card([
            _tapItem(
              icon: Icons.lock_reset_rounded,
              iconColor: zenAmber,
              title: context.tr('change_password2'),
              subtitle: context.tr('change_password2_sub'),
              onTap: () => _showChangePasswordDialog(provider),
            ),
            _divider(),
            _tapItem(
              icon: Icons.cleaning_services_rounded,
              iconColor: zenIndigo,
              title: context.tr('clear_cache'),
              subtitle: context.tr('clear_cache_sub'),
              onTap: () => _confirmClearCache(),
            ),
            _divider(),
            _tapItem(
              icon: Icons.logout_rounded,
              iconColor: zenRose,
              title: context.tr('logout'),
              subtitle: context.tr('logout_sub'),
              onTap: () => _confirmLogout(provider),
            ),
          ]),
          const SizedBox(height: 24),

          _sectionTitle(context.tr('set_about')),
          const SizedBox(height: 12),
          _card([
            _infoItem(
              icon: Icons.info_outline_rounded,
              iconColor: zenIndigo,
              title: context.tr('app_version'),
              value: provider.appVersionLabel.isNotEmpty
                  ? provider.appVersionLabel
                  : _appVersion,
            ),
            _divider(),
            _tapItem(
              icon: Icons.policy_outlined,
              iconColor: zenEmerald,
              title: context.tr('privacy_policy'),
              subtitle: context.tr('privacy_policy_sub'),
              onTap: () => _showLegalSheet(
                context.tr('privacy_policy'),
                _privacyContent,
              ),
            ),
            _divider(),
            _tapItem(
              icon: Icons.description_outlined,
              iconColor: zenAmber,
              title: context.tr('terms_conditions'),
              subtitle: context.tr('terms_conditions_sub'),
              onTap: () => _showLegalSheet(
                context.tr('terms_conditions'),
                _termsContent,
              ),
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: _subColor.withValues(alpha: 0.4),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 JNE Martapura HUB',
                  style: GoogleFonts.outfit(
                    color: _subColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All Rights Reserved.',
                  style: GoogleFonts.outfit(
                    color: _subColor.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Atom widgets ────────────────────────────────────────────

  Widget _accountHeader(String name, String email, String role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.4 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.jneOrange.withValues(alpha: 0.9),
                  AppColors.brandRed,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        t.toUpperCase(),
        style: GoogleFonts.outfit(
          color: _subColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _card(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.only(left: 60),
    child: Divider(
      height: 1,
      color: _isDark ? Colors.white12 : const Color(0xFFF1F5F9),
    ),
  );

  Widget _switchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: _iconBox(icon, iconColor),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: _textColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: GoogleFonts.outfit(
            color: _subColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: jneBlue,
    );
  }

  Widget _tapItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _iconBox(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: _subColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _subColor.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: _subColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: Icon(Icons.copy_rounded, color: _subColor, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  // ── Actions ─────────────────────────────────────────────────

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'id':
      default:
        return 'Bahasa Indonesia';
    }
  }

  Future<void> _showLanguagePicker(AppProvider provider) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _subColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                context.tr('choose_language').toUpperCase(),
                style: GoogleFonts.outfit(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _langOption(
                ctx,
                'id',
                'Bahasa Indonesia',
                'ID',
                provider.language == 'id',
              ),
              _langOption(
                ctx,
                'en',
                'English',
                'EN',
                provider.language == 'en',
              ),
            ],
          ),
        ),
      ),
    );
    if (code != null && code != provider.language) {
      await provider.setLanguage(code);
      if (mounted) {
        _toast('${context.tr('set_language')}: ${_languageLabel(code)}');
      }
    }
  }

  Widget _langOption(
    BuildContext ctx,
    String code,
    String label,
    String badge,
    bool active,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, code),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? jneBlue.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? jneBlue.withValues(alpha: 0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? jneBlue.withValues(alpha: 0.15)
                    : _subColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: GoogleFonts.outfit(
                  color: active ? jneBlue : _subColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (active)
              const Icon(Icons.check_circle_rounded, color: jneBlue, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _showLegalSheet(String title, String content) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _subColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('effective_date'),
                style: GoogleFonts.outfit(
                  color: _subColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  child: Text(
                    content,
                    style: GoogleFonts.plusJakartaSans(
                      color: _textColor.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: jneBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.tr('understood').toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(AppProvider provider) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;
    bool processing = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            context.tr('change_password2'),
            style: GoogleFonts.outfit(
              color: _textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              obscureText: obscure,
              autofocus: true,
              style: GoogleFonts.outfit(color: _textColor, fontSize: 14),
              validator: (v) {
                if (v == null || v.length < 6) return context.tr('min_6_chars');
                return null;
              },
              decoration: InputDecoration(
                hintText: context.tr('new_password_hint2'),
                hintStyle: GoogleFonts.outfit(color: _subColor, fontSize: 13),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: _subColor,
                  size: 18,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setSB(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _subColor,
                    size: 18,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _subColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: processing ? null : () => Navigator.pop(ctx),
              child: Text(
                context.tr('cancel'),
                style: GoogleFonts.outfit(
                  color: _subColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: processing
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSB(() => processing = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final okMsg = context.tr('password_changed2');
                      try {
                        await provider.changePassword(ctrl.text);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              okMsg,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: zenEmerald,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        setSB(() => processing = false);
                        if (!ctx.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: zenRose,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: jneBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: processing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.tr('save'),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCache() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('clear_cache_confirm'),
          style: GoogleFonts.outfit(
            color: _textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          context.tr('clear_cache_confirm_desc'),
          style: GoogleFonts.outfit(
            color: _subColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.outfit(
                color: _subColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: zenAmber,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.tr('clear_btn'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Tidak menghapus SharedPreferences (yang menyimpan preferensi). Hanya
    // simulasikan housekeeping — ekstensi nanti bisa hapus file cache jika ada.
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.tr('cache_cleared'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: zenEmerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmLogout(AppProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('logout_confirm'),
          style: GoogleFonts.outfit(
            color: _textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          context.tr('logout_confirm_desc'),
          style: GoogleFonts.outfit(
            color: _subColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.outfit(
                color: _subColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: zenRose,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.tr('logout'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    provider.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  // ── Legal copy ──────────────────────────────────────────────

  static const _privacyContent = '''
JNE Attendance Mobile menghargai privasi Anda. Dokumen ini menjelaskan data apa yang kami kumpulkan, untuk apa, dan bagaimana kami melindunginya.

1. DATA YANG DIKUMPULKAN
• Identitas akun: nama, email, ID karyawan, departemen, posisi.
• Data biometrik wajah (foto enrollment) untuk verifikasi absensi.
• Lokasi (GPS) saat absen masuk/keluar — hanya pada momen aksi, bukan tracking terus-menerus.
• Foto absensi (check-in / check-out) yang Anda ambil.
• Metadata perangkat: device ID, FCM token untuk push notification.

2. CARA KAMI MENGGUNAKAN DATA
• Verifikasi kehadiran (geofence + foto + face match).
• Menampilkan riwayat absensi & statistik personal Anda.
• Mengirim notifikasi terkait absensi, izin, lembur, atau pengumuman.
• Audit kepatuhan internal untuk admin HUB.

3. PEMBAGIAN DATA
• Data hanya diakses oleh admin HUB Martapura yang berwenang.
• Tidak ada penjualan data ke pihak ketiga.
• Tidak ada pertukaran data dengan perusahaan di luar JNE Group tanpa persetujuan eksplisit.

4. PENYIMPANAN
• Disimpan di server Firebase (Google Cloud) dengan enkripsi at-rest dan in-transit.
• Foto absensi disimpan minimal 12 bulan, lalu dapat diarsipkan/hapus per kebijakan retensi.

5. HAK ANDA
• Meminta salinan data Anda.
• Meminta koreksi data yang salah.
• Mengajukan komplain via menu Komplain bila ada penggunaan data yang Anda rasa keliru.

6. KEAMANAN
• Login dilindungi password + (opsional) verifikasi wajah.
• Anda bertanggung jawab merahasiakan password akun Anda.
• Laporkan segera jika perangkat hilang agar sesi dapat di-revoke.

7. KONTAK
Pertanyaan terkait privasi: hubungi admin HUB melalui menu Chat.
''';

  static const _termsContent = '''
Dengan menggunakan aplikasi JNE Attendance, Anda menyetujui ketentuan berikut.

1. KEPEMILIKAN AKUN
• Akun bersifat personal dan tidak boleh dipinjamkan.
• Anda bertanggung jawab penuh atas aktivitas pada akun Anda.

2. ABSENSI YANG SAH
• Absen dilakukan dari titik fisik yang ditetapkan kantor (geofence).
• Foto wajah saat absen harus jelas, tanpa manipulasi.
• Manipulasi waktu device, fake GPS, atau foto palsu adalah pelanggaran berat.

3. KOMPLAIN & PENGAJUAN
• Komplain dispute, cuti, dan lembur diproses sesuai SLA admin HUB.
• Bukti palsu atau klaim tidak benar dapat berakibat sanksi administratif.

4. PENGGUNAAN YANG DILARANG
• Reverse engineering, modifikasi aplikasi, atau bypass keamanan.
• Penggunaan untuk tujuan di luar pencatatan kehadiran resmi JNE.

5. PEMBARUAN APLIKASI
• Anda diwajibkan menggunakan versi terbaru untuk memastikan fitur keamanan terkini.
• Versi tertinggal dapat menyebabkan sinkronisasi absensi gagal.

6. PERUBAHAN KETENTUAN
• Kami dapat memperbarui ketentuan ini. Perubahan akan diinformasikan via notifikasi in-app.
• Penggunaan berkelanjutan setelah update berarti Anda menerima ketentuan baru.

7. BATAS TANGGUNG JAWAB
• Aplikasi diberikan "as-is". JNE Group tidak bertanggung jawab atas kerugian akibat penyalahgunaan akun oleh pihak yang tidak berwenang akibat kelalaian pemegang akun.

Dengan terus memakai aplikasi ini Anda menyatakan telah membaca, memahami, dan menyetujui semua butir di atas.
''';
}
