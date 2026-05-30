part of 'main.dart';

class _ShotlyActionItem<T> {
  _ShotlyActionItem({
    required this.value,
    required this.icon,
    required this.title,
  });

  final T value;
  final IconData icon;
  final String title;
}

Future<T?> _showShotlyActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<_ShotlyActionItem<T>> items,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.62,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: const Color(0xFF727785)),
                      ),
                    ),
                  ],
                  ...items.map(
                    (item) => _ShotlyMenuRow(
                      icon: item.icon,
                      title: item.title,
                      onTap: () => Navigator.of(context).pop(item.value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<String?> _showShotlyTextDialog({
  required BuildContext context,
  required String title,
  String initialValue = '',
  required String hintText,
  required String primaryLabel,
  int minLines = 1,
  int maxLines = 1,
  String? Function(String value)? validator,
}) async {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => _ShotlyTextDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      primaryLabel: primaryLabel,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
    ),
  );
}

class _ShotlyTextDialog extends StatefulWidget {
  const _ShotlyTextDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.primaryLabel,
    required this.minLines,
    required this.maxLines,
    this.validator,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final String primaryLabel;
  final int minLines;
  final int maxLines;
  final String? Function(String value)? validator;

  @override
  State<_ShotlyTextDialog> createState() => _ShotlyTextDialogState();
}

class _ShotlyTextDialogState extends State<_ShotlyTextDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  static const _fieldFillColor = Color(0xFFF7F7F8);
  static const _fieldErrorColor = Color(0xFFB42318);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1A1C1C),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF727785),
                ),
                filled: true,
                fillColor: _fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                errorText: _errorText,
                errorStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _fieldErrorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onChanged: (value) => _validateLive(value),
              onSubmitted: widget.maxLines == 1
                  ? (value) => _submit(context)
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF727785),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(st('취소', 'Cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: _errorText == null ? () => _submit(context) : null,
                  child: Text(widget.primaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _validateLive(String value) {
    final error = widget.validator?.call(value);
    if (error != _errorText) setState(() => _errorText = error);
  }

  void _submit(BuildContext context) {
    final error = widget.validator?.call(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }
}

Future<void> _showShotlyInfoDialog({
  required BuildContext context,
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754)),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(st('확인', 'OK')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool?> _showShotlyConfirmDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String primaryLabel,
  bool destructive = false,
}) {
  final primaryColor = destructive
      ? const Color(0xFFB42318)
      : const Color(0xFF111111);
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF424754)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF727785),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(st('취소', 'Cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(primaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShotlyMenuRow extends StatelessWidget {
  const _ShotlyMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF424754)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1A1C1C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMenuTile extends StatelessWidget {
  const _AddMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 24, color: const Color(0xFF111111)),
      title: Text(title, style: Theme.of(context).textTheme.labelLarge),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
