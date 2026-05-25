import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../models/note_model.dart';
import 'note_editor_page.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  Future<List<Note>> loadArchivedNotes() {
    return DBHelper.getArchivedNotes();
  }

  Future<void> openEditor(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> restoreNote(Note note) async {
    await DBHelper.updateNote(
      Note(
        id: note.id,
        title: note.title,
        content: note.content,
        category: note.category,
        isPinned: note.isPinned,
        isFavorite: note.isFavorite,
        isArchived: false,
      ),
    );

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan dikembalikan ke Home'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: SafeArea(
        child: FutureBuilder<List<Note>>(
          future: loadArchivedNotes(),
          builder: (context, snapshot) {
            final notes = snapshot.data ?? [];

            if (notes.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada catatan arsip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];

                return GestureDetector(
                  onTap: () => openEditor(note),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFEDEEF2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.045),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.archive_rounded,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                note.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => restoreNote(note),
                              icon: const Icon(
                                Icons.unarchive_outlined,
                                color: Color.fromARGB(255, 243, 79, 166),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          note.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          note.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 245, 82, 155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}