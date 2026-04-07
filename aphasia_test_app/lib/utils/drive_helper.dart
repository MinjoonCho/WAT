import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DriveHelper {

  // 선생님께서 붙여넣으실 Google Apps Script 웹앱 URL (배포 후 나오게 됩니다)
  static const String scriptUrl = 'REPLACE_WITH_YOUR_WEB_APP_URL';

  // 검사 데이터가 들어갈 부모 폴더 (WAT_검사데이터 폴더의 ID)
  static const String _parentFolderId = '1wDy7tewVwQ3PJXbVF3pfJgVSWvdjQYfH'; 

  /// 구글 드라이브 지정 폴더에 피험자 데이터를 업로드 
  static Future<void> uploadPatientFolder(
    Directory localDir,
    String patientRegNo, {
    required Function(String status) onProgress,
  }) async {
    try {
      if (scriptUrl.contains('REPLACE')) {
        onProgress('업로드 오류: Apps Script 웹앱 URL이 설정되지 않았습니다.');
        return;
      }

      final files = localDir.listSync().whereType<File>().toList();
      if (files.isEmpty) {
        onProgress('업로드할 파일이 없습니다.');
        return;
      }

      int uploadedCount = 0;
      for (final file in files) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        onProgress('업로드 중: $fileName (${uploadedCount + 1}/${files.length})');
        
        // 파일을 Base64로 인코딩
        List<int> fileBytes = await file.readAsBytes();
        String base64Data = base64Encode(fileBytes);
        
        String mimeType = 'text/csv';
        if (fileName.endsWith('.m4a')) mimeType = 'audio/mp4';

        // Apps Script로 POST 전송
        final response = await http.post(
          Uri.parse(scriptUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'parentId': _parentFolderId,
            'patientRegNo': patientRegNo,
            'name': fileName,
            'mimeType': mimeType,
            'data': base64Data,
          }),
        );
        
        // 구글 스크립트는 성공 시 응답이 리다이렉트 되거나 텍스트로 옵니다.
        if (response.statusCode == 200 || response.statusCode == 302) {
           final body = response.body;
           if (body.contains('Error')) {
             throw Exception('서버 에러: $body');
           }
           uploadedCount++;
        } else {
           throw Exception('HTTP 에러: ${response.statusCode}');
        }
      }

      onProgress('성공: 총 $uploadedCount개 파일 업로드 완료\n(구글 드라이브를 확인하세요!)');
    } catch (e) {
      print('Drive Upload Error: $e');
      onProgress('업로드 오류 발생: $e');
    }
  }
}
