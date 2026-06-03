import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../login_page.dart';
import '../models/note_model.dart';
import '../session/session_manager.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({
    super.key,
    this.username = 'User',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color bgColor = Color(0xFFFFF7FB);
  static const Color primaryPink = Color(0xFFE992BD);
  static const Color softPink = Color(0xFFF8BBD0);
  static const Color lightPink = Color(0xFFFFEAF4);
  static const Color borderPink = Color(0xFFFFD6E8);
  static const Color textDark = Color(0xFF7A3755);
  static const Color textSoft = Color(0xFF9D7C8D);
  static const Color hintPink = Color(0xFFD8A7BE);

  late String username;

  int totalNotes = 0;
  int pinnedNotes = 0;
  int totalCategories = 0;

  bool notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    username = widget.username;
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    final List<Note> notes = await DBHelper.getNotes();
    final categories = notes.map((note) => note.category).toSet();

    if (!mounted) return;

    setState(() {
      totalNotes = notes.length;
      pinnedNotes = notes.where((note) => note.isPinned).length;
      totalCategories = categories.length;
    });
  }

  Future<void> logout() async {
    await SessionManager.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showEditProfileDialog() {
    final usernameController = TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Profil',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          content: TextField(
            controller: usernameController,
            cursorColor: primaryPink,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(color: textSoft),
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: primaryPink,
              ),
              filled: true,
              fillColor: lightPink,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: borderPink),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: primaryPink, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: textSoft),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newUsername = usernameController.text.trim();

                if (newUsername.isEmpty) {
                  showMessage('Username tidak boleh kosong');
                  return;
                }

                setState(() {
                  username = newUsername;
                });

                Navigator.pop(context);
                showMessage('Profil berhasil diperbarui');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void showAccountInfo() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Informasi Akun',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogInfoRow('Username', username),
              _dialogInfoRow('Total Catatan', totalNotes.toString()),
              _dialogInfoRow('Catatan Pinned', pinnedNotes.toString()),
              _dialogInfoRow('Kategori', totalCategories.toString()),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: textSoft,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  void showNotificationSettings() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Notifikasi',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              content: SwitchListTile(
                value: notificationEnabled,
                activeColor: primaryPink,
                title: const Text(
                  'Aktifkan notifikasi',
                  style: TextStyle(color: textDark),
                ),
                subtitle: const Text(
                  'Pengingat catatan sederhana',
                  style: TextStyle(color: textSoft),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    notificationEnabled = value;
                  });

                  setState(() {
                    notificationEnabled = value;
                  });
                },
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showMessage(
                      notificationEnabled
                          ? 'Notifikasi diaktifkan'
                          : 'Notifikasi dimatikan',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showSecurityDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Keamanan',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                cursorColor: primaryPink,
                decoration: InputDecoration(
                  labelText: 'Password lama',
                  labelStyle: const TextStyle(color: textSoft),
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: primaryPink,
                  ),
                  filled: true,
                  fillColor: lightPink,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: borderPink),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(color: primaryPink, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                cursorColor: primaryPink,
                decoration: InputDecoration(
                  labelText: 'Password baru',
                  labelStyle: const TextStyle(color: textSoft),
                  prefixIcon: const Icon(
                    Icons.lock_reset_rounded,
                    color: primaryPink,
                  ),
                  filled: true,
                  fillColor: lightPink,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: borderPink),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(color: primaryPink, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: textSoft),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (oldPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty) {
                  showMessage('Semua field wajib diisi');
                  return;
                }

                Navigator.pop(context);
                showMessage('Password berhasil diperbarui');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: 'My Notes',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.edit_note_rounded,
        color: primaryPink,
        size: 42,
      ),
      children: const [
        Text(
          'Aplikasi catatan sederhana untuk menyimpan catatan, kategori, dan pin catatan penting.',
        ),
      ],
    );
  }

  void showLogoutConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: borderPink,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 22),
              const Icon(
                Icons.logout_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 14),
              const Text(
                'Keluar dari akun?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu perlu login kembali untuk membuka catatan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textSoft,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: borderPink,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: textSoft),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 24),
              _buildProfileHeader(),
              const SizedBox(height: 28),
              _buildStatsSection(),
              const SizedBox(height: 26),
              _buildMenuSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderPink),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: textDark,
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            softPink,
            primaryPink,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.25),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 62,
                color: primaryPink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pengguna My Notes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: showEditProfileDialog,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryPink,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.note_alt_outlined,
            title: 'Catatan',
            value: totalNotes.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.push_pin_outlined,
            title: 'Pinned',
            value: pinnedNotes.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.folder_outlined,
            title: 'Kategori',
            value: totalCategories.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderPink,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: primaryPink,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: textSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.person_outline_rounded,
          title: 'Informasi Akun',
          subtitle: 'Lihat detail profil pengguna',
          onTap: showAccountInfo,
        ),
        _buildMenuTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifikasi',
          subtitle: notificationEnabled
              ? 'Notifikasi sedang aktif'
              : 'Notifikasi sedang mati',
          onTap: showNotificationSettings,
        ),
        _buildMenuTile(
          icon: Icons.security_rounded,
          title: 'Keamanan',
          subtitle: 'Kelola keamanan akun',
          onTap: showSecurityDialog,
        ),
        _buildMenuTile(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Aplikasi',
          subtitle: 'My Notes versi sederhana',
          onTap: showAboutApp,
        ),
        _buildMenuTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'Keluar dari akun saat ini',
          color: const Color(0xFFEF4444),
          onTap: showLogoutConfirmation,
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = primaryPink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderPink,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: textSoft,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: hintPink,
        ),
      ),
    );
  }
}