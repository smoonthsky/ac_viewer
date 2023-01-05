import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../theme/icons.dart';
import '../../common/action_mixins/feedback.dart';
import '../aves_dialog.dart';

class PresentationUnlockDialog extends StatefulWidget {
  final String passwordSaved;

  const PresentationUnlockDialog({
    super.key,
    required this.passwordSaved,
  });

  @override
  State<PresentationUnlockDialog> createState() =>
      _PresentationUnlockDialogState();
}

class _PresentationUnlockDialogState extends State<PresentationUnlockDialog>
    with FeedbackMixin {
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _passwordVisible = false;
  final passwordFormKey = 'presentation_unlock_password';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const contentHorizontalPadding = EdgeInsets.symmetric(
        horizontal: AvesDialog.defaultHorizontalContentPadding);
    return AvesDialog(
      title: context.l10n.unlockPresentationDialogTitle,
      content: Padding(
        padding: contentHorizontalPadding + const EdgeInsets.only(bottom: 8),
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            onChanged: () {
              _formKey.currentState!.save();
              debugPrint(_formKey.currentState!.value.toString());
            },
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              children: [
                FormBuilderTextField(
                  name: passwordFormKey,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.maxLength(30),
                    FormBuilderValidators.minLength(1),
                  ]),
                  onChanged: (volume) {
                    _validate();
                  },
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: context.l10n.unlockPresentationPasswordTile,
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible
                          ? AIcons.hide
                          : AIcons.show),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isValidNotifier,
          builder: (context, isValid, child) {
            return TextButton(
              onPressed: isValid ? () => _submit(context) : null,
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            );
          },
        ),
      ],
    );
  }

  Future<void> _validate() async {
    if (_formKey.currentState != null) {
      _isValidNotifier.value =_formKey.currentState!.isValid ;
    }
  }

  void _submit(BuildContext context) {
    if (_isValidNotifier.value) {
      if (_formKey.currentState != null &&
          _formKey.currentState!.saveAndValidate()) {
        final password = _formKey.currentState!.value[passwordFormKey];
        if (password == widget.passwordSaved) {
          Navigator.pop(context, true);
        } else {
          _formKey.currentState!.reset();
          showFeedback(context, context.l10n.genericFailureFeedback);
        }
      }
    }
  }
}
