import 'package:aves/utils/time_utils.dart';
import 'package:aves/widgets/common/basic/wheel.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/providers/media_query_data_provider.dart';
import 'package:aves/widgets/dialogs/aves_dialog.dart';
import 'package:flutter/material.dart';

class DurationDialog extends StatefulWidget {
  final int initialSeconds;

  const DurationDialog({
    super.key,
    required this.initialSeconds,
  });

  @override
  State<DurationDialog> createState() => _DurationDialogState();
}

// 在编辑日期与时间时显示。
class _DurationDialogState extends State<DurationDialog> {
  late ValueNotifier<int> _hours,_minutes, _seconds;

  @override
  void initState() {
    super.initState();
    final seconds = widget.initialSeconds;
    _hours = ValueNotifier(seconds ~/ secondsInHours);
    _minutes = ValueNotifier((seconds % secondsInHours) ~/ secondsInMinute);
    _seconds = ValueNotifier(seconds % secondsInMinute);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQueryDataProvider(
      child: Builder(builder: (context) {
        final l10n = context.l10n;
        const textStyle = TextStyle(fontSize: 34);

        return AvesDialog(
          scrollableContent: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Table(
                  // even when ambient direction is RTL, time is displayed in LTR
                  textDirection: TextDirection.ltr,
                  children: [
                    TableRow(
                      children: [
                        Center(child: Text(context.l10n.durationDialogHours)),
                        const SizedBox(width: 16),
                        Center(child: Text(context.l10n.durationDialogMinutes)),
                        const SizedBox(width: 16),
                        Center(child: Text(context.l10n.durationDialogSeconds)),
                      ],
                    ),
                    TableRow(
                      children: [
                        Align(
                        alignment: Alignment.centerRight,
                        child: WheelSelector(
                          valueNotifier: _hours,
                          values: List.generate(hoursInTwoDays, (i) => i),
                          textStyle: textStyle,
                          textAlign: TextAlign.end,
                        ),
                      ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            ':',
                            style: textStyle,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: WheelSelector(
                            valueNotifier: _minutes,
                            values: List.generate(minutesInHour, (i) => i),
                            textStyle: textStyle,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            ':',
                            style: textStyle,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: WheelSelector(
                            valueNotifier: _seconds,
                            values: List.generate(secondsInMinute, (i) => i),
                            textStyle: textStyle,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    )
                  ],
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                ),
              ),
            ),
          ],
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_hours, _minutes, _seconds]),
              builder: (context, child) {
                final isValid = _hours.value > 0 || _minutes.value > 0 || _seconds.value > 0;
                return TextButton(
                  onPressed: isValid ? () => _submit(context) : null,
                  child: child!,
                );
              },
              child: Text(l10n.applyButtonLabel),
            ),
          ],
        );
      }),
    );
  }

  void _submit(BuildContext context) => Navigator.pop(context, _hours.value * secondsInHours + _minutes.value * secondsInMinute + _seconds.value);
}
