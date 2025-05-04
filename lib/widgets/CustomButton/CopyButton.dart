import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyButton extends StatefulWidget {
  final String text;
  final VoidCallback? onCopy;

  const CopyButton({
    Key? key,
    required this.text,
    this.onCopy,
  }) : super(key: key);

  @override
  _CopyButtonState createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _isPressed = false;

  void _copyText() async {
    setState(() {
      _isPressed = true;
    });

    await Clipboard.setData(ClipboardData(text: widget.text));

    if (widget.onCopy != null) {
      widget.onCopy!();
    }

    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _isPressed ? 0.95 : 1.0,
      child: Card(
        elevation: 8,
        shadowColor: Colors.blue.withOpacity(_isPressed ? 0.5 : 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.blue,
                Colors.blue.withOpacity(0.7),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
          child: InkWell(
            onTap: _copyText,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'نسخ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}