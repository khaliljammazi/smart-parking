import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class OTPInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final Function() onResend;
  final int otpLength;
  final int countdownSeconds;

  const OTPInputWidget({
    super.key,
    required this.onCompleted,
    required this.onResend,
    this.otpLength = 6,
    this.countdownSeconds = 300, // 5 minutes
  });

  @override
  State<OTPInputWidget> createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(widget.otpLength, (_) => FocusNode());
    _remainingSeconds = widget.countdownSeconds;
    _startCountdown();

    // Listen for paste via clipboard on each focus node
    for (int i = 0; i < widget.otpLength; i++) {
      final index = i;
      _focusNodes[index].addListener(() {
        // When a field is focused, select all text so typing replaces it
        if (_focusNodes[index].hasFocus) {
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        }
      });
    }
  }

  void _startCountdown() {
    _canResend = false;
    _remainingSeconds = widget.countdownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onChanged(String value, int index) {
    // Handle pasted multi-character input (works on mobile & web)
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      _handlePaste(digits);
      return;
    }

    if (value.isNotEmpty) {
      // Ensure only digit
      final digit = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digit.isEmpty) {
        _controllers[index].clear();
        return;
      }
      _controllers[index].text = digit;
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: 1),
      );

      if (index < widget.otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      // Backspace — go back
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Check if all filled
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == widget.otpLength) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCompleted(otp);
      });
    }
  }

  void _handlePaste(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      for (int i = 0; i < widget.otpLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      // Move focus to last filled field
      final lastIndex = (digits.length - 1).clamp(0, widget.otpLength - 1);
      _focusNodes[lastIndex].requestFocus();

      if (digits.length >= widget.otpLength) {
        _focusNodes[widget.otpLength - 1].unfocus();
        widget.onCompleted(digits.substring(0, widget.otpLength));
      }
      setState(() {});
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _handlePaste(data.text!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // OTP Input Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.otpLength, (index) {
            return SizedBox(
              width: 45,
              height: 55,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                // No maxLength / LengthLimitingFormatter here — we handle
                // length manually in onChanged so paste works on all platforms
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF252B48)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFF064789),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _controllers[index].text.isNotEmpty
                          ? (isDark
                              ? const Color(0xFF1E88E5)
                              : const Color(0xFF064789))
                          : (isDark ? Colors.white30 : Colors.grey.shade300),
                      width: _controllers[index].text.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E88E5)
                          : const Color(0xFF064789),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) => _onChanged(value, index),
                // Allow long-press paste via context menu
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar(
                    anchors: editableTextState.contextMenuAnchors,
                    children: [
                      TextSelectionToolbarTextButton(
                        padding: const EdgeInsets.all(8),
                        onPressed: () async {
                          editableTextState.hideToolbar();
                          await _pasteFromClipboard();
                        },
                        child: const Text('Paste'),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Countdown Timer
        if (!_canResend)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                'Resend OTP in $_formattedTime',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          )
        else
          // Resend Button
          TextButton.icon(
            onPressed: () {
              widget.onResend();
              _startCountdown();
              // Clear all fields
              for (var controller in _controllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Resend OTP'),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? const Color(0xFF1E88E5) : const Color(0xFF064789),
            ),
          ),

        const SizedBox(height: 16),

        // Paste from clipboard button
        TextButton.icon(
          onPressed: _pasteFromClipboard,
          icon: Icon(
            Icons.content_paste,
            size: 18,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
          label: Text(
            'Paste OTP',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }
}
