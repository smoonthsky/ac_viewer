import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../theme/icons.dart';
import '../../common/action_mixins/feedback.dart';
import '../aves_dialog.dart';

class PresentationUnlockPasswordChangeDialog extends StatefulWidget {
  final String passwordSaved;

  static const routeName = '/settings/present_unlock_password_change';

  const PresentationUnlockPasswordChangeDialog({
    super.key,
    required this.passwordSaved,
  });

  @override
  State<PresentationUnlockPasswordChangeDialog> createState() =>
      _PresentationUnlockPasswordChangeDialogState();
}

class _PresentationUnlockPasswordChangeDialogState extends State<PresentationUnlockPasswordChangeDialog>
    with FeedbackMixin {
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(false);
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  final oldPasswordFormKey = 'old_presentation_unlock_password';
  final newPasswordFormKey = 'new_presentation_unlock_password';
  final confirmPasswordFormKey = 'confirm_presentation_unlock_password';
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  final String passwordSaved = settings.presentationLockPassword;
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
      title: context.l10n.unlockPresentationPasswordChangeDialogTitle,
      content: Padding(
        padding: contentHorizontalPadding + const EdgeInsets.only(bottom: 8),
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            onChanged: () {
              _formKey.currentState!.save();
              _validate();
              debugPrint(_formKey.currentState!.value.toString());
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: <Widget> [
                FormBuilderTextField(
                  name: oldPasswordFormKey,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.maxLength(30),
                    FormBuilderValidators.minLength(1),
                    FormBuilderValidators.equal(passwordSaved),
                  ]),
                  obscureText: !_oldPasswordVisible,
                  decoration: InputDecoration(
                    labelText: context.l10n.unlockPresentationOldPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_oldPasswordVisible
                          ? AIcons.hide
                          : AIcons.show),
                      onPressed: () =>
                          setState(() => _oldPasswordVisible = !_oldPasswordVisible),
                    ),
                  ),
                ),
                FormBuilderTextField(
                  name: newPasswordFormKey,
                  validator:
                  FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.maxLength(30),
                    FormBuilderValidators.minLength(1),
                  ]),
                  obscureText: !_newPasswordVisible,
                  decoration: InputDecoration(
                    labelText: context.l10n.unlockPresentationNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_newPasswordVisible
                          ? AIcons.hide
                          : AIcons.show),
                      onPressed: () => setState(
                            () => _newPasswordVisible = !_newPasswordVisible,
                      ),
                    ),
                  ),
                ),
                FormBuilderTextField(
                  name: confirmPasswordFormKey,
                  validator:
                  FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.maxLength(30),
                    FormBuilderValidators.minLength(1),
                  ]),
                  obscureText: !_confirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText:  context.l10n.unlockPresentationConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_confirmPasswordVisible
                          ? AIcons.hide
                          : AIcons.show),
                      onPressed: () => setState(
                            () => _confirmPasswordVisible = !_confirmPasswordVisible,
                      ),
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
      final passwordValid = _formKey.currentState!.value[oldPasswordFormKey] == passwordSaved;
      final newPasswordValid = _formKey.currentState!.value[newPasswordFormKey] ==  _formKey.currentState!.value[confirmPasswordFormKey];
      debugPrint('newPasswordValid:$newPasswordValid  | passwordValid:$passwordSaved');
      _isValidNotifier.value = newPasswordValid && passwordValid ;
    }
  }

  void _submit(BuildContext context) {
    debugPrint(_formKey.currentState!.value.toString());
    if (_isValidNotifier.value) {
      if (_formKey.currentState != null &&
          _formKey.currentState!.saveAndValidate()) {
        settings.presentationLockPassword = _formKey.currentState!.value[newPasswordFormKey];
        showFeedback(context, 'password saved');
        Navigator.pop(context);
      } else {
        _formKey.currentState!.reset();
        showFeedback(context, context.l10n.genericFailureFeedback);
      }
    }
  }
}
