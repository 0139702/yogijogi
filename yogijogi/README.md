# 요기조기 개발 환경

Flutter 앱은 API Gateway의 HTTPS 주소로 요청을 보냅니다. API Gateway는 Lambda로 전달하고, Lambda는 DynamoDB에 제보를 저장합니다. 로컬에서는 같은 제보 API를 메모리 저장소로 실행할 수 있습니다.

| 경로 | 역할 |
| --- | --- |
| `lib/core/` | Flutter 실행 환경과 API 주소 |
| `lib/features/map/` | 지도 탭 및 지도 기능을 붙일 위치 |
| `lib/features/reports/` | 제보 모델, API 클라이언트, 제보 화면 |
| `config/` | Android 에뮬레이터, iOS 시뮬레이터, 팀 개발 API 설정 예시 |
| `backend/src/` | 공통 HTTP 처리와 Lambda의 DynamoDB 연결 |
| `backend/template.yaml` | API Gateway HTTP API, Lambda, 제보·행사·강의실 DynamoDB 테이블 |

현재 지도 탭은 자리 표시 화면입니다. 제보 화면에서는 유형·위치·발생 시각·설명을 입력하고 제보를 등록·조회·수정할 수 있습니다. 행사·강의실은 테이블만 준비했습니다. 사진 업로드 작업에서 S3를 추가할 예정입니다.

## 팀원 로컬 실행

앱 폴더(`pubspec.yaml`이 있는 곳)에서 실행합니다. Flutter **3.50.1**(Dart **3.14.0**)과 Node.js **24.x**를 사용합니다. Flutter의 `bin`을 PATH에 추가한 뒤 `flutter doctor -v`에서 사용할 플랫폼을 확인합니다. Android는 Android SDK, JDK 17 이상, 에뮬레이터가 필요합니다. iOS 시뮬레이터는 macOS와 Xcode에서 실행합니다. [Android 설정](https://docs.flutter.dev/platform-integration/android/setup) · [iOS 설정](https://docs.flutter.dev/platform-integration/ios/setup)

첫 번째 터미널에서 로컬 API를 실행합니다. Node 패키지 설치와 AWS 자격 증명 없이 실행됩니다.

```sh
cd backend
npm start
```

기본 주소는 `http://127.0.0.1:3000`입니다. 브라우저로 `http://127.0.0.1:3000/health`를 열면 동작을 확인할 수 있습니다. 포트를 바꾸려면 `backend/.env.example`을 `backend/.env`로 복사하고 `PORT`를 변경한 뒤 Flutter 설정 주소에도 같은 포트를 사용합니다. 로컬 제보 데이터는 서버를 재시작하면 초기화됩니다. 서버가 켜질 때 `backend/local-seed.mjs`의 샘플 제보 5건을 피드에 넣으며(이 중 처리 진행 중인 1건은 앱을 켠 뒤 처음 가입한 시연용 계정 `demo-1`의 제보), `.env`에 `SEED_REPORTS=false`를 넣으면 빈 피드로 시작합니다.

두 번째 터미널에서 앱을 실행합니다.

```sh
flutter pub get
flutter devices
flutter run -d DEVICE_ID --dart-define-from-file=config/android.example.json
```

`DEVICE_ID`를 `flutter devices`에 나온 값으로 바꿉니다. iOS 시뮬레이터에서는 `config/ios.example.json`을 사용합니다. 실기기에서는 아래 팀 개발용 HTTPS 주소를 사용합니다.

```sh
flutter analyze
flutter test
```

## 팀 개발용 AWS 환경

배포 담당자는 AWS CLI와 AWS SAM CLI를 설정하고 팀 AWS 프로필로 로그인합니다. IAM Identity Center를 쓰는 팀은 `aws sso login --profile TEAM_PROFILE`로 로그인합니다. AWS 리전은 시작값으로 서울(`ap-northeast-2`)을 사용합니다.

```sh
cd backend
sam validate --lint --region ap-northeast-2
sam build
sam deploy --guided --profile TEAM_PROFILE --region ap-northeast-2
```

첫 배포의 스택 이름은 `yogijogi-dev`를 사용합니다. IAM 리소스 생성에는 확인이 필요합니다. 기본값으로 배포하면 `GET /health`를 사용할 수 있고 제보 요청은 403을 반환합니다. 인증 없는 팀 데모가 필요한 경우에만 `EnableDemoReports=true`를 선택합니다. 이 경우 **인터넷에서 누구나 제보를 읽고 등록하고 수정할 수 있으므로 샘플 데이터만 사용**합니다. 실제 제보를 받기 전에 API 인증과 제보별 수정 권한을 연결합니다. Lambda에는 제보 테이블에 필요한 권한만 부여합니다. [AWS SAM 배포](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/using-sam-cli-deploy.html)

팀원은 스택 출력의 `ApiBaseUrl`만 공유받으면 됩니다. `config/dev.example.json`을 `config/dev.local.json`으로 복사하고 `API_BASE_URL`을 스택 출력값으로 바꿉니다.

```sh
flutter run -d DEVICE_ID --dart-define-from-file=config/dev.local.json
```

Flutter 설정은 앱에 포함되므로 `APP_ENV`와 `API_BASE_URL`처럼 공개 가능한 값만 넣습니다. AWS 자격 증명은 개인 AWS CLI 프로필에서 관리합니다. Lambda의 테이블 이름과 데모 사용 여부는 SAM이 환경 변수로 주입합니다. 예시 파일만 Git으로 공유하며 실제 `.env`, `config/*.local.json`, SAM의 개인 배포 설정은 Git에서 제외합니다.

## 제보 API

| 메서드와 경로 | 기능 |
| --- | --- |
| `GET /health` | 실행 환경과 제보 API 활성화 여부 |
| `GET /reports` | 제보 목록(최대 50건, 초기 개발 범위) |
| `POST /reports` | 제보 등록 |
| `GET /reports/{id}` | 제보 한 건 조회 |
| `PUT /reports/{id}` | 제보 유형·위치·설명·발생 시각 갱신 |
| `DELETE /reports/{id}` | 제보와 첨부 사진 삭제(작성자 본인, 담당자 확인 전 상태만. 처리가 시작됐으면 409) |

등록/수정 본문은 `{"type":"시설 문제","location":"본관 1층","description":"테스트 제보","occurredAt":"2026-11-20T02:00:00Z"}` 형식입니다. 발생 시각은 타임존을 포함한 ISO 8601 문자열을 사용합니다. ID, 출처, 처리 상태, 생성 및 갱신 시각은 서버가 관리합니다.

등록·수정·사진 요청에는 로그인 사용자 ID를 `x-user-id` 헤더로 보냅니다. 서버는 등록할 때 이 값을 `authorId`로 저장하고, 수정과 사진 추가·삭제는 작성자 본인만 할 수 있게 합니다(헤더가 없으면 401, 다른 사용자면 403). 앱은 내가 올린 제보에만 수정 버튼을 보여 줍니다. 이 헤더는 앱이 직접 보내는 값이라 위조할 수 있으므로 시연·개발용입니다. 실제 제보를 받기 전에 Cognito 토큰 검증으로 바꿉니다.
