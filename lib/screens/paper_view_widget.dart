import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:page_curl_effect/page_curl_effect.dart';
class PaperViewWidget extends StatefulWidget {
  final List<Note> data;
  const PaperViewWidget({required this.data, super.key});

  @override
  State<PaperViewWidget> createState() => _PaperViewWidgetState();
}

class _PaperViewWidgetState extends State<PaperViewWidget> {
  late PageCurlController _pageCurlController;
  late Size _pageSize;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _pageSize = Size(
      MediaQuery.of(context).size.width,
      600,
    );

    _pageCurlController = PageCurlController(
        Size(_pageSize.width, _pageSize.height),
        pageCurlIndex: 0,
        /// A number of pages
        numberOfPage: widget.data.length);

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: PageCurlEffect(
        pageCurlController: _pageCurlController,
        // pages: [],
        pageBuilder: (context, index) {
          // return widget.child;
          final String n = Document.fromJson(jsonDecode(widget.data[index].content!)).toPlainText().trim();
          return  Container(
            alignment: Alignment.center,
            color: Colors.blue,
            width: _pageSize.width,
            height: _pageSize.height,
            child: Text(n),
          );
        },
        onForwardComplete: () {
          print('======next completed===');
        },
        onBackwardComplete: () {
          print('======back completed===');

        },
      ),
    );
  }
}