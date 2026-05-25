# Shotly Flutter 전환 메모

업데이트: 2026-05-25

## 현재 결정

Shotly는 iOS 출시가 필수이므로 Flutter를 메인 앱으로 사용한다. 기존 Kotlin/Jetpack Compose 앱은 삭제하지 않고 `../shotly-android`에 보존하며, 기능 정의와 native 구현 참고용 prototype으로 사용한다.

## 구조

- Flutter/Dart
  - UI
  - 화면 흐름
  - Stack/Set/Calendar/Search 모델
  - 로컬 상태 저장
  - Web mock preview
- Android Kotlin bridge
  - 사진 권한
  - MediaStore 스크린샷 조회
  - Android image picker
  - 썸네일 cache 파일 생성
- iOS Swift bridge 예정
  - Photos 권한
  - Screenshot/album 조회
  - iOS image picker
  - 썸네일 cache 파일 생성
- Web
  - 실제 로컬 사진 접근 불가
  - GitHub Pages 기반 mock preview 전용
  - 배포 링크는 항상 cache-busted `?v=<commit>` 사용

## 기존 PRD 대비 변경된 핵심 정의

- 지원 OS: `AOS Only` 폐기. Android+iOS 지원이 최신 정의.
- Stack: “동일 이미지”가 아니라 앱/서비스 단위 기본 정리 단위.
- 유사 화면: Stack 내부 보조 후보 보기. 전역 유사 검색/고도화 분류는 Phase 2.
- Set: Stack 내부에서 동일 날짜 + 첫 이미지 기준 1시간 이내 작업 세션.
- Calendar tab: 날짜 picker/filter가 아니라 전체 스크린샷 최신 날짜순 timeline/grid.
- 수동 동기화: 상단 refresh icon은 제거. pull-to-refresh 유지.
- 로컬 저장: Flutter 현재는 shared_preferences. MVP 안정화 전 Drift/Isar 등 구조화 DB 전환 필요.

## 구현된 것

### Flutter UI

- Stitch-style 홈 화면
- Shotly sticky top bar
- 스크린샷/Stack 개수 요약
- underline search
- Stack 리스트
- Calendar timeline tab
- floating bottom nav
- 검정 + 버튼
- + 메뉴: Stack 추가 / 이미지 추가
- Stack 상세 화면
  - 날짜별/유사 화면 chip toggle
  - Set section
  - Set memo edit
  - 3-column 9:16 thumbnail grid
  - Stack rename/hide menu
- 권한/빈 상태/에러 상태
- Web mock data preview

### Android bridge

MethodChannel: `shotly/native`

- `requestPhotoPermission`
- `getScreenshots`
- `pickImage`

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


### Smart Clean / 유사 이미지 묶기

- 앱/Stack 상세에서 Smart Clean 분석 실행
- 분석 범위는 해당 앱/Stack 안의 전체 스크린샷
- 10분 시간창 제한 제거
- 고정 분석 timeout 제거
- 이미 폴더에 들어간 이미지는 새 그룹 후보에서 제외
- 기존 폴더는 최신 이미지 1장을 대표 이미지로 사용
- 새 스크린샷은 기존 폴더 대표 이미지와 먼저 비교한 뒤, 남은 미분류끼리 비슷한 화면 후보 생성
- Smart Clean 후보는 '비슷한 화면'으로 통일 표시
- 후보 상세에서는 첫 이미지 잠금 없이 전체 선택 가능
- 선택된 이미지를 삭제하거나 폴더로 묶는 두 액션 제공
- 특징 추출은 10장 단위 isolate 배치로 실행
- 추출된 특징은 메모리에 캐시하여 같은 세션 재분석 시 재사용
- 64비트 perceptual hash 비교가 음수 hash에서 무한 루프에 빠지던 문제 수정

### 로컬 기능

- Stack 이름 수정
- Stack 숨기기
- 수동 Stack 생성
- Set 메모 저장
- 이미지 숨기기/제외
- 이미지 다른 Stack으로 이동
- 유사 화면 후보 보기
- Smart Clean 후보 검토 후 삭제/기존 폴더 추가/새 폴더 생성

## 검증 결과

최근 기준:

- `flutter analyze` 통과
- `flutter test` 통과
- `flutter build web --base-href /shotly-flutter/ --pwa-strategy=none` 통과
- `flutter build apk --debug` 통과
- Android 실기기 `SM S931N` debug install/run 통과
- Smart Clean 14장 Stack 분석 838ms 완료 로그 확인
- GitHub Pages deploy workflow 통과

## 남은 일

### P0

- iOS Photos bridge 추가
- 로컬 DB 결정 및 shared_preferences migration
- Settings 기본 화면
- 숨김/제외 복구 UX
- 개인정보처리방침/약관 초안 연결

### P1

- 중복 선택 방지 picker UX
- Set 합치기/분리
- Search 대상 강화: Set memo, alias dictionary 정리
- Stack 상세/Calendar visual QA polish
- Android app name extraction 개선

### P2

- 온디바이스 screenshot 판별 모델 검토
- OCR 검색
- 전역 유사 화면 검색
- Smart Clean 특징 캐시 영구 저장/DB migration
- 선택 로그인/클라우드 백업
- 멀티 디바이스 동기화
