import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CustomImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final imageUrl = embedContext.node.value.data as String;
    return _ResizableImageWidget(
      imageUrl: imageUrl,
      node: embedContext.node,
      controller: embedContext.controller,
    );
  }
}

class _ResizableImageWidget extends StatefulWidget {
  final String imageUrl;
  final Embed node;
  final QuillController controller;

  const _ResizableImageWidget({
    required this.imageUrl,
    required this.node,
    required this.controller,
  });

  @override
  State<_ResizableImageWidget> createState() => _ResizableImageWidgetState();
}

class _ResizableImageWidgetState extends State<_ResizableImageWidget> {
  late String _filePath;
  double _width = 300;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _parseUrl();
  }

  void _parseUrl() {
    try {
      final uri = Uri.parse(widget.imageUrl);
      _filePath = uri.path;
      if (uri.queryParameters.containsKey('w')) {
        _width = double.parse(uri.queryParameters['w']!);
      }
    } catch (e) {
      _filePath = widget.imageUrl;
    }
  }

  void _updateDocument() {
    final offset = widget.node.documentOffset;
    final length = widget.node.length;
    final newUrl = '$_filePath?w=${_width.toInt()}';
    
    // Replace the embed with the new URL to save size
    widget.controller.replaceText(offset, length, BlockEmbed.image(newUrl), null);
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = Container(
      width: _width,
      decoration: BoxDecoration(
        border: Border.all(
          color: _isHovering ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Image.file(
        File(_filePath),
        fit: BoxFit.contain,
      ),
    );

    final interactiveImage = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => setState(() => _isHovering = !_isHovering),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              imageWidget,
              if (_isHovering)
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _width = (_width + details.delta.dx).clamp(50.0, MediaQuery.of(context).size.width);
                      });
                    },
                    onPanEnd: (_) => _updateDocument(),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                      child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return LongPressDraggable<String>(
      data: jsonEncode({'path': _filePath, 'w': _width.toInt()}),
      feedback: Opacity(
        opacity: 0.7,
        child: Material(
          color: Colors.transparent,
          child: imageWidget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: imageWidget,
      ),
      onDragStarted: () {
        // Delete from current location so it visually moves
        final offset = widget.node.documentOffset;
        final length = widget.node.length;
        widget.controller.replaceText(offset, length, '', null);
      },
      onDraggableCanceled: (velocity, offset) {
        // Restore image if canceled
        final embed = BlockEmbed.image('$_filePath?w=${_width.toInt()}');
        widget.controller.replaceText(widget.node.documentOffset, 0, embed, null);
      },
      child: interactiveImage,
    );
  }
}
