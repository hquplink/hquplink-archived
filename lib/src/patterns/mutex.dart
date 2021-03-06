import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

/// Provides a mutable interface for a [State] object's state [T].
abstract class Mutex<T, Y extends StatefulWidget> extends State<Y> {
  T _value;

  /// Value that is potentially mutated.
  @protected
  T get value => _value;

  @protected
  void setValue(
    T newValue, {
    String Function(T) describeRevert,
    BuildContext notifyRevert,
  }) {
    final oldValue = value;
    if (mounted) {
      setState(() => _value = newValue);
    }
    onUpdate();
    if (notifyRevert != null) {
      assert(mounted);
      assert(describeRevert != null);
      _promptUndo(notifyRevert, describeRevert(newValue), oldValue);
    }
  }

  void _promptUndo(BuildContext context, String description, T oldValue) {
    Scaffold.of(context)
      // TODO: Consider a better way of doing this.
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(description),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setValue(oldValue);
            },
          ),
        ),
      );
  }

  @override
  initState() {
    _value = initMutex();
    super.initState();
  }

  /// Override to provide updates to a parent widget about a new [value].
  ///
  /// Updates should be provided via `=`.
  @protected
  @visibleForOverriding
  void onUpdate();

  /// Override to provide the initial mutable value, often from the parent [widget].
  @protected
  @visibleForOverriding
  T initMutex();
}
