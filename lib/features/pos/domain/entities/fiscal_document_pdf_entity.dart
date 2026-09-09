import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class FiscalDocumentPdfEntity extends Equatable {
  const FiscalDocumentPdfEntity({required this.fileName, required this.contentType, required this.bytes});

  final String fileName;
  final String contentType;
  final Uint8List bytes;

  @override
  List<Object?> get props => [fileName, contentType, bytes.length];
}
