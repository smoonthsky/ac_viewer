
import 'package:aves/model/present.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:flutter/material.dart';

class RenamePresentTagDialog extends StatefulWidget {
  final PresentTagRow renamePresentTag;

  const RenamePresentTagDialog( {
    super.key,
    required this.renamePresentTag,
  });

  @override
  State<RenamePresentTagDialog> createState() => _RenamePresentTagDialogState();
}

class _RenamePresentTagDialogState extends State<RenamePresentTagDialog> {
  final TextEditingController _nameController = TextEditingController();
  final ValueNotifier<bool> _existsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);
  final FocusNode _nameFieldFocusNode = FocusNode();

  PresentTagRow get renamePresentTag => widget.renamePresentTag;


  @override
  void initState() {
    super.initState();
    _nameController.text = renamePresentTag.presentTagString;
    _validate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _existsNotifier.dispose();
    _isValidNotifier.dispose();
    _nameFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AvesDialog(
      content: ValueListenableBuilder<bool>(
          valueListenable: _existsNotifier,
          builder: (context, exists, child) {
            return TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.presentTagEditorPageRenameTagFieldLabel,
                helperText: exists ? context.l10n.presentTagAlreadyExistsHelper : '',
              ),
              autofocus: true,
              onChanged: (_) => _validate(),
              onSubmitted: (_) => _submit(context),
            );
          }),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isValidNotifier,
          builder: (context, isValid, child) {
            return TextButton(
              onPressed: isValid ? () => _submit(context) : null,
              child: Text(context.l10n.applyButtonLabel),
            );
          },
        )
      ],
    );
  }

  Future<void> _validate() async {
    final name = _nameController.text;
    final exists = presentTags.isPresentTag(name);
    _existsNotifier.value = exists;
    _isValidNotifier.value = name.isNotEmpty && !exists;
  }

  void _submit(BuildContext context) {
    if (_isValidNotifier.value) {
      final name = _nameController.text;
      PresentTagRow renamePresentTag=PresentTagRow(presentTagId: this.renamePresentTag.presentTagId, presentTagString: name);
      Navigator.pop(context, renamePresentTag.toJson());
    }
  }
}
