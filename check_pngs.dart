import 'dart:io';

void main() {
  final resDir = Directory('android/app/src/main/res');
  if (!resDir.existsSync()) {
    print('Resource directory not found');
    return;
  }

  final pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  resDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('ic_launcher.png')) {
      final bytes = entity.readAsBytesSync();
      bool isValid = true;
      if (bytes.length < 8) {
        isValid = false;
      } else {
        for (int i = 0; i < 8; i++) {
          if (bytes[i] != pngHeader[i]) {
            isValid = false;
            break;
          }
        }
      }

      if (isValid) {
        print('VALID: ${entity.path}');
      } else {
        print('INVALID HEADER: ${entity.path}');
        if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
          print('  -> Looks like a JPEG file!');
        } else {
          print(
            '  -> Header: ${bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ")}',
          );
        }
      }
    }
  });
}
