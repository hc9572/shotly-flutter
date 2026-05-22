# Shotly Flutter 전환 메모

## 현재 상태

- 기존 Kotlin/Jetpack Compose 앱은 `../shotly-android`에 그대로 보존.
- 새 Flutter 앱은 `shotly-flutter`에 생성.
- Flutter SDK 설치 완료: 3.44.0 / Dart 3.12.0.
- Android debug APK 빌드 성공.

## 전환 방향

Shotly는 iOS 출시가 확정이므로 Flutter를 메인 앱으로 사용한다.

- Flutter/Dart
  - UI
  - 화면 흐름
  - Stack/Set 모델
  - 검색/필터
  - 로컬 상태/DB 예정
- Android Kotlin
  - 사진 권한
  - MediaStore 스크린샷 조회
  - 썸네일 cache 파일 생성
- iOS Swift 예정
  - Photos 권한
  - Screenshot/album 조회
  - 썸네일 cache 파일 생성

## 구현된 것

### Flutter UI

- 홈 화면
- Shotly 헤더
- 스크린샷/Stack 개수 요약
- 검색 필드
- 날짜 필터 row
- 캘린더는 버튼 클릭 시에만 표시
- 캘린더 열렸을 때 리스트와 겹치지 않음
- Stack 카드 리스트
- Stack 상세 화면
- 권한/빈 상태/에러 상태

### Android 브릿지

MethodChannel: `shotly/native`

- `requestPhotoPermission`
- `getScreenshots`

반환 데이터:

```json
{
  "id": "...",
  "displayName": "...",
  "relativePath": "...",
  "dateTakenMillis": 0,
  "appName": "...",
  "thumbnailPath": "..."
}
```

## 검증 결과

- `flutter analyze` 통과
- `flutter test` 통과
- `flutter build apk --debug` 성공

## 남은 일

- Android 실기기 재연결 후 APK 설치/실행 검증
- iOS Photos 브릿지 추가
- 기존 Kotlin 앱 기능 추가 포팅
  - 제외/숨김
  - 수동 Stack
  - Stack 이름 변경
  - Set 묶음
  - 유사 화면 그룹
  - 메모
- 로컬 DB 결정
  - Drift 또는 Isar 후보
- 디자인 툴 결과 반영
