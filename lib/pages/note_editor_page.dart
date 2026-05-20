import 'dart:async';

import 'package:flutter/material.dart';

import '../db/db_helper.dart';
import '../models/note_model.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;

  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;

  double fontSize = 20;
  String selectedCategory = 'Kuliah';

  Timer? timer;
  DateTime currentDate = DateTime.now();

  final List<String> undoStack = [];
  final List<String> redoStack = [];

  String lastText = '';
  bool isUndoRedoAction = false;

  final List<String> categories = ['Kuliah', 'Pribadi', 'Tugas', 'Penting'];

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      titleController.text = widget.note!.title;
      contentController.text = widget.note!.content;
      selectedCategory = widget.note!.category;
    }

    lastText = contentController.text;
    undoStack.add(lastText);

    contentController.addListener(_handleTextChange);

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        currentDate = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    contentController.removeListener(_handleTextChange);
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    if (isUndoRedoAction) return;

    final currentText = contentController.text;

    if (currentText != lastText) {
      undoStack.add(currentText);

      if (undoStack.length > 100) {
        undoStack.removeAt(0);
      }

      redoStack.clear();
      lastText = currentText;
    }

    setState(() {});
  }

  bool get canUndo => undoStack.length > 1;
  bool get canRedo => redoStack.isNotEmpty;

  void undo() {
    if (!canUndo) return;

    isUndoRedoAction = true;

    final current = undoStack.removeLast();
    redoStack.add(current);

    final previous = undoStack.last;
    contentController.text = previous;
    contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: contentController.text.length),
    );

    lastText = previous;
    isUndoRedoAction = false;

    setState(() {});
  }

  void redo() {
    if (!canRedo) return;

    isUndoRedoAction = true;

    final redoText = redoStack.removeLast();
    undoStack.add(redoText);

    contentController.text = redoText;
    contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: contentController.text.length),
    );

    lastText = redoText;
    isUndoRedoAction = false;

    setState(() {});
  }

  int get characterCount {
    return contentController.text.replaceAll('\n', '').length;
  }

  TextStyle get noteTextStyle {
    return TextStyle(
      fontSize: fontSize,
      height: 1.6,
      color: const Color(0xFF1F2937),
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
    );
  }

  String get currentDateText {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = currentDate.day;
    final month = months[currentDate.month - 1];

    int hour = currentDate.hour;
    final minute = currentDate.minute.toString().padLeft(2, '0');
    final second = currentDate.second.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$day $month $hour:$minute:$second $period';
  }

  Future<void> saveNote() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan masih kosong'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (widget.note == null) {
        await DBHelper.insertNote(
          Note(
            title: title.isEmpty ? 'Tanpa Judul' : title,
            content: content,
            category: selectedCategory,
          ),
        );
      } else {
        await DBHelper.updateNote(
          Note(
            id: widget.note!.id,
            title: title.isEmpty ? 'Tanpa Judul' : title,
            content: content,
            category: selectedCategory,
            isPinned: widget.note!.isPinned,
          ),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan catatan: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String addStrikeThrough(String text) {
    return text.split('').map((char) {
      if (char.trim().isEmpty) return char;
      return '$char\u0336';
    }).join();
  }

  String removeStrikeThrough(String text) {
    return text.replaceAll('\u0336', '');
  }

  void toggleChecklistLine() {
    final text = contentController.text;
    final selection = contentController.selection;

    final cursor = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;

    int lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
    int lineEnd = text.indexOf('\n', cursor);

    if (lineEnd == -1) {
      lineEnd = text.length;
    }

    final currentLine = text.substring(lineStart, lineEnd);

    String newLine;

    if (currentLine.startsWith('☐ ')) {
      final cleanText = currentLine.substring(2);
      newLine = '☑ ${addStrikeThrough(cleanText)}';
    } else if (currentLine.startsWith('☑ ')) {
      final cleanText = removeStrikeThrough(currentLine.substring(2));
      newLine = '☐ $cleanText';
    } else if (currentLine.trim().isEmpty) {
      newLine = '☐ ';
    } else {
      final cleanText = removeStrikeThrough(currentLine);
      newLine = '☐ $cleanText';
    }

    final newText = text.replaceRange(lineStart, lineEnd, newLine);

    contentController.text = newText;
    contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: lineStart + newLine.length),
    );

    setState(() {});
  }

  void clearChecklistLine() {
    final text = contentController.text;
    final selection = contentController.selection;

    final cursor = selection.baseOffset < 0
        ? text.length
        : selection.baseOffset;

    int lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
    int lineEnd = text.indexOf('\n', cursor);

    if (lineEnd == -1) {
      lineEnd = text.length;
    }

    String currentLine = text.substring(lineStart, lineEnd);

    if (currentLine.startsWith('☐ ')) {
      currentLine = currentLine.substring(2);
    } else if (currentLine.startsWith('☑ ')) {
      currentLine = currentLine.substring(2);
    }

    final cleanLine = removeStrikeThrough(currentLine);

    final newText = text.replaceRange(lineStart, lineEnd, cleanLine);

    contentController.text = newText;
    contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: lineStart + cleanLine.length),
    );

    setState(() {});
  }

  Future<bool> handleBackButton() async {
    Navigator.pop(context, true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: handleBackButton,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFC),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleInput(),
                      const SizedBox(height: 14),
                      _buildInfoRow(),
                      const SizedBox(height: 20),
                      _buildCategoryChips(),
                      const SizedBox(height: 30),
                      _buildNoteInput(),
                    ],
                  ),
                ),
              ),
              _buildFormatToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.arrow_back_rounded),
            iconSize: 30,
            color: const Color(0xFF202124),
          ),
          const Spacer(),
          IconButton(
            onPressed: canUndo ? undo : null,
            icon: const Icon(Icons.undo_rounded),
            iconSize: 28,
            color: canUndo ? const Color(0xFF202124) : const Color(0xFFC8CBD2),
          ),
          IconButton(
            onPressed: canRedo ? redo : null,
            icon: const Icon(Icons.redo_rounded),
            iconSize: 28,
            color: canRedo ? const Color(0xFF202124) : const Color(0xFFC8CBD2),
          ),
          Container(
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 241, 113, 164),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    244,
                    118,
                    183,
                  ).withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              onPressed: saveNote,
              icon: const Icon(Icons.check_rounded),
              iconSize: 30,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: titleController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
        letterSpacing: -1,
      ),
      decoration: const InputDecoration(
        hintText: 'Judul',
        hintStyle: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: Color(0xFFC7CAD1),
          letterSpacing: -1,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildInfoRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEAFE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: Color.fromARGB(255, 249, 121, 191),
          ),
        ),
        Text(
          currentDateText,
          style: const TextStyle(fontSize: 14, color: Color(0xFF8A8D96)),
        ),
        Container(width: 1, height: 18, color: const Color(0xFFD8DAE0)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEAFE),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'Aa',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 250, 124, 194),
            ),
          ),
        ),
        Text(
          '$characterCount karakter',
          style: const TextStyle(fontSize: 14, color: Color(0xFF8A8D96)),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = selectedCategory == category;

        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          selectedColor: const Color(0xFFEEEAFE),
          backgroundColor: Colors.white,
          showCheckmark: false,
          labelStyle: TextStyle(
            color: isSelected
                ? const Color.fromARGB(255, 247, 118, 191)
                : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? const Color.fromARGB(255, 231, 107, 167)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          onSelected: (_) {
            setState(() {
              selectedCategory = category;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildNoteInput() {
    return TextField(
      controller: contentController,
      maxLines: null,
      minLines: 12,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: noteTextStyle,
      cursorColor: const Color.fromARGB(255, 247, 110, 167),
      cursorWidth: 2.5,
      onChanged: (_) {
        setState(() {});
      },
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: 'Tulis catatan kamu di sini...',
        hintStyle: TextStyle(fontSize: 20, color: Color(0xFFB8BBC4)),
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFormatToolbar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _toolbarIconButton(
            icon: Icons.check_box_outlined,
            onTap: toggleChecklistLine,
          ),
          _toolbarIconButton(
            icon: Icons.format_clear_rounded,
            onTap: clearChecklistLine,
          ),
          _toolbarTextButton(
            text: 'A+',
            active: true,
            onTap: () {
              setState(() {
                fontSize += 2;
              });
            },
          ),
          _toolbarTextButton(
            text: 'A-',
            onTap: () {
              setState(() {
                if (fontSize > 14) {
                  fontSize -= 2;
                }
              });
            },
          ),
          _toolbarTextButton(
            text: 'B',
            active: isBold,
            fontWeight: FontWeight.bold,
            onTap: () {
              setState(() {
                isBold = !isBold;
              });
            },
          ),
          _toolbarTextButton(
            text: 'I',
            active: isItalic,
            fontStyle: FontStyle.italic,
            onTap: () {
              setState(() {
                isItalic = !isItalic;
              });
            },
          ),
          _toolbarTextButton(
            text: 'U',
            active: isUnderline,
            decoration: TextDecoration.underline,
            onTap: () {
              setState(() {
                isUnderline = !isUnderline;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _toolbarIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEEEAFE) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 24,
          color: active
              ? const Color.fromARGB(255, 254, 123, 191)
              : const Color(0xFF2B2D33),
        ),
      ),
    );
  }

  Widget _toolbarTextButton({
    required String text,
    required VoidCallback onTap,
    bool active = false,
    FontWeight fontWeight = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
    TextDecoration decoration = TextDecoration.none,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEEEAFE) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
            color: active
                ? const Color.fromARGB(255, 227, 116, 192)
                : const Color(0xFF2B2D33),
          ),
        ),
      ),
    );
  }
}
