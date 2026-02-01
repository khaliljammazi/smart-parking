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
    if (value.length == 1) {
      if (index < widget.otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Check if all fields are filled
        final otp = _controllers.map((c) => c.text).join();
        if (otp.length == widget.otpLength) {
          widget.onCompleted(otp);
        }
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _handlePaste(String text) {
    if (text.length >= widget.otpLength) {
      for (int i = 0; i < widget.otpLength; i++) {
        _controllers[i].text = text[i];
      }
      _focusNodes[widget.otpLength - 1].unfocus();
      widget.onCompleted(text.substring(0, widget.otpLength));
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
                maxLength: 1,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF252B48) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E88E5) : const Color(0xFF064789),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white30 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF1E88E5) : const Color(0xFF064789),
                      width: 2,
                    ),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                onChanged: (value) => _onChanged(value, index),
                onTap: () {
                  _controllers[index].selection = TextSelection.fromPosition(
                    TextPosition(offset: _controllers[index].text.length),
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
              foregroundColor: isDark ? const Color(0xFF1E88E5) : const Color(0xFF064789),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Paste from clipboard hint
        TextButton.icon(
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data != null && data.text != null) {
              _handlePaste(data.text!);
            }
          },
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
