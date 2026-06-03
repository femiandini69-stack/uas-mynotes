import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../models/note_model.dart';
import 'note_editor_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color bgColor = Color(0xFFFFF7FB);
  static const Color primaryPink = Color(0xFFE992BD);
  static const Color lightPink = Color(0xFFFFEAF4);
  static const Color borderPink = Color(0xFFFFD6E8);
  static const Color textDark = Color(0xFF7A3755);
  static const Color textSoft = Color(0xFF9D7C8D);
  static const Color hintPink = Color(0xFFD8A7BE);

  List<Note> notes = [];

  String selectedCategory = "Semua";
  String searchQuery = "";

  List<String> categories = ["Semua", "Kuliah", "Pribadi", "Tugas", "Penting"];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final data = await DBHelper.getNotes();

    // Catatan yang sudah diarsipkan tidak ditampilkan di Home
    final activeNotes = data.where((note) => !note.isArchived).toList();

    // Catatan pin tetap muncul di atas
    activeNotes.sort((a, b) {
      if (a.isPinned == b.isPinned) return 0;
      return a.isPinned ? -1 : 1;
    });

    if (!mounted) return;

    setState(() {
      notes = activeNotes;
    });
  }

  Future<void> openEditor({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorPage(note: note)),
    );

    if (result == true) {
      loadNotes();
    }
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    loadNotes();
  }

  Future<void> togglePin(Note note) async {
    await DBHelper.updateNote(
      Note(
        id: note.id,
        title: note.title,
        content: note.content,
        category: note.category,
        isPinned: !note.isPinned,
        isFavorite: note.isFavorite,
        isArchived: note.isArchived,
      ),
    );

    loadNotes();
  }

  Future<void> toggleFavorite(Note note) async {
    await DBHelper.updateNote(
      Note(
        id: note.id,
        title: note.title,
        content: note.content,
        category: note.category,
        isPinned: note.isPinned,
        isFavorite: !note.isFavorite,
        isArchived: note.isArchived,
      ),
    );

    loadNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !note.isFavorite
              ? 'Catatan ditambahkan ke favorit'
              : 'Catatan dihapus dari favorit',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> archiveNote(Note note) async {
    await DBHelper.updateNote(
      Note(
        id: note.id,
        title: note.title,
        content: note.content,
        category: note.category,
        isPinned: note.isPinned,
        isFavorite: note.isFavorite,
        isArchived: true,
      ),
    );

    loadNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan dipindahkan ke arsip'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> deleteNote(Note note) async {
    if (note.id == null) return;

    await DBHelper.deleteNote(note.id!);
    loadNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan berhasil dihapus'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showDeleteConfirmation(Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                Icons.delete_outline_rounded,
                size: 46,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hapus catatan?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Catatan yang dihapus tidak bisa dikembalikan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textSoft),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: borderPink),
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
                        await deleteNote(note);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Hapus'),
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
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final filteredNotes = notes.where((n) {
      final matchCategory =
          selectedCategory == "Semua" || n.category == selectedCategory;

      final matchSearch =
          n.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          n.content.toLowerCase().contains(searchQuery.toLowerCase());

      return matchCategory && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      floatingActionButton: isKeyboardOpen
          ? null
          : FloatingActionButton(
              backgroundColor: primaryPink,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => openEditor(),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategoryFilter(),
            const SizedBox(height: 10),
            Expanded(
              child: filteredNotes.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: primaryPink,
                      onRefresh: loadNotes,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return _buildNoteCard(note);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'My Notes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: textDark,
              ),
            ),
          ),

          // Tombol profil
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryPink.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              onPressed: openProfile,
              icon: const Icon(Icons.person_rounded, color: primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: TextField(
        cursorColor: primaryPink,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, color: primaryPink),
          hintText: "Cari catatan...",
          hintStyle: const TextStyle(color: hintPink),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: lightPink,
              backgroundColor: Colors.white,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? primaryPink : textSoft,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: isSelected ? primaryPink : borderPink),
              ),
              onSelected: (_) {
                setState(() {
                  selectedCategory = cat;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return GestureDetector(
      onTap: () => openEditor(note: note),
      onLongPress: () => showDeleteConfirmation(note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderPink),
          boxShadow: [
            BoxShadow(
              color: primaryPink.withOpacity(0.09),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: note.isPinned ? const Color(0xFFFFEAEA) : lightPink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    note.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.note_alt_outlined,
                    color: note.isPinned
                        ? const Color(0xFFEF4444)
                        : primaryPink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Tanpa Judul' : note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => togglePin(note),
                  icon: Icon(
                    note.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    color: note.isPinned ? const Color(0xFFEF4444) : textSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              note.content.isEmpty ? 'Tidak ada isi catatan' : note.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: textSoft,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lightPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    note.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryPink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),

                // Icon favorit: klik untuk simpan/hapus dari favorit
                IconButton(
                  onPressed: () => toggleFavorite(note),
                  icon: Icon(
                    note.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: note.isFavorite ? primaryPink : textSoft,
                  ),
                ),

                // Icon arsip: klik untuk pindahkan catatan ke arsip
                IconButton(
                  onPressed: () => archiveNote(note),
                  icon: const Icon(Icons.archive_outlined, color: textSoft),
                ),

                // Icon edit
                IconButton(
                  onPressed: () => openEditor(note: note),
                  icon: const Icon(Icons.edit_outlined, color: textSoft),
                ),

                // Icon hapus
                IconButton(
                  onPressed: () => showDeleteConfirmation(note),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 70,
                color: primaryPink,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Belum ada catatan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol + untuk membuat catatan baru yang estetik.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: textSoft),
            ),
          ],
        ),
      ),
    );
  }
}
