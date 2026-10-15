import 'package:flutter/material.dart';

import 'install_prompt_stub.dart'
    if (dart.library.js_interop) 'install_prompt_web.dart';

/// Opens the browser install prompt. Hidden where the page cannot be installed,
/// including widget tests and an already installed window.
class InstallButton extends StatefulWidget {
  const InstallButton({super.key});

  @override
  State<InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<InstallButton> {
  var _installed = false;

  @override
  Widget build(BuildContext context) {
    if (_installed || !installSupported) return const SizedBox.shrink();
    return Tooltip(
      message: 'Add a shortcut on this device',
      child: TextButton(
        key: const Key('install-app'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () async {
          final accepted = await requestInstall(context);
          if (accepted && mounted) setState(() => _installed = true);
        },
        child: const Text('Install'),
      ),
    );
  }
}
