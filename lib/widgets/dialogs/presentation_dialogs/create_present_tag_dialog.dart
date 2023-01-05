
import 'package:aves/model/present.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';

import '../aves_dialog.dart';

class CreatePresentTagDialog extends StatefulWidget {
  const CreatePresentTagDialog({super.key});

  @override
  State<CreatePresentTagDialog> createState() => _CreatePresentTagDialogState();
}

class _CreatePresentTagDialogState extends State<CreatePresentTagDialog> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFieldFocusNode = FocusNode();
  final ValueNotifier<bool> _existsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFieldFocusNode.dispose();
    _existsNotifier.dispose();
    _isValidNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const contentHorizontalPadding = EdgeInsets.symmetric(horizontal: AvesDialog.defaultHorizontalContentPadding);

    return AvesDialog(
      title: context.l10n.presentTagEditorPageNewTagFieldLabel,
        content :
        Padding(
          padding: contentHorizontalPadding + const EdgeInsets.only(bottom: 8),
          child: ValueListenableBuilder<bool>(
              valueListenable: _existsNotifier,
              builder: (context, exists, child) {
                return TextField(
                  controller: _nameController,
                  focusNode: _nameFieldFocusNode,
                  decoration: InputDecoration(
                    labelText: context.l10n.tagPageTitle,
                    helperText: exists ? context.l10n.presentTagAlreadyExistsHelper : '',
                  ),
                  maxLength: 30,
                  autofocus: true,
                  onChanged: (_) => _validate(),
                  onSubmitted: (_) => _submit(context),
                );
              }),
        ),
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
              child: Text(context.l10n.createAlbumButtonLabel),
            );
          },
        ),
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
    final name = _nameController.text;
    if (_isValidNotifier.value) {
      PresentTagRow newPresentTag=PresentTagRow(presentTagId: presentTags.getOneValidPresentTagid(), presentTagString: name);
      Navigator.pop(context, newPresentTag.toJson());
    }
  }
}
