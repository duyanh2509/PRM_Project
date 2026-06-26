import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LocalImageService {
  LocalImageService._internal();

  static final LocalImageService instance = LocalImageService._internal();

  Future<File> saveProofImage(File sourceFile, String customerCode) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(
      path.join(appDirectory.path, 'proof_images'),
    );
    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final extension = path.extension(sourceFile.path).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final safeCustomerCode = customerCode.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    final fileName =
        '${safeCustomerCode}_${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final destinationPath = path.join(imageDirectory.path, fileName);

    return sourceFile.copy(destinationPath);
  }
}
