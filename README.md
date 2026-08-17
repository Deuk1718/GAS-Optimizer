# GAS-Optimizer

[![Validate skill and installers](https://github.com/Deuk1718/GAS-Optimizer/actions/workflows/validate.yml/badge.svg)](https://github.com/Deuk1718/GAS-Optimizer/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Deuk1718/GAS-Optimizer)](https://github.com/Deuk1718/GAS-Optimizer/releases)

GAS-Optimizer는 정적 HTML, SSG, SSR 웹사이트를 **SEO, GEO, AEO, 접근성, 성능, 배포 준비도** 관점에서 분석하고 최적화하는 Aside 사용자 스킬입니다.

여기서 GAS는 **GEO · AEO · SEO**를 뜻하며 Google Apps Script와는 관계가 없습니다.

## 핵심 특징

- 6개 품질 영역을 각각 100점으로 평가
- 모든 영역이 개별적으로 95점 이상이어야 통과
- 평균 점수로 부족한 영역을 보완하지 않는 비보상식 게이트
- Critical·High 문제, HTML 검증 오류, 주요 기능 회귀, 허위 구조화 데이터가 있으면 통과 차단
- 측정할 수 없는 필수 항목을 임의로 통과시키지 않고 `[blocked]`로 기록
- Google, Bing, schema.org 및 웹 표준의 공식 자료를 우선 사용
- 크롤링 가능한 초기 HTML과 점진적 향상 원칙 적용
- 분석 승인과 구현 계획 승인을 분리한 2단계 승인
- 최적화 전 백업·체크섬·롤백 계획
- 기능·시각 회귀와 주장·외부 링크·JSON-LD 진실성 검사
- 독립 실행 가능한 동적 HTML 분석 보고서 템플릿 제공

## 품질 게이트

아래 여섯 영역이 **모두 95점 이상**이어야 합니다.

1. SEO
2. GEO
3. AEO
4. 접근성
5. 성능
6. 배포 준비도

공통 평가 기준은 [`quality-rubric.md`](skill/gas-optimizer/references/quality-rubric.md)에 있습니다. 프로젝트별 조건을 추가할 수 있지만 공통 기준이나 통과선을 낮출 수는 없습니다.

## 기본 실행 흐름

1. 프로젝트와 렌더링 결과 조사
2. 6개 영역의 증거 기반 분석
3. 동적 `analysis-plan.html` 보고서 생성
4. 사용자에게 분석 승인 요청
5. 파일별 구현·검증·백업 계획 작성
6. 사용자에게 계획 승인 요청
7. 승인 후 백업과 최적화 실행
8. 기능·시각·링크·스키마 회귀 검사
9. 6개 영역을 다시 측정하고 통과할 때까지 반복
10. 품질 게이트 결과와 롤백 방법 보고

## 선택형 확장 기능

다음 기능은 기본적으로 실행되지 않습니다. GAS-Optimizer는 먼저 필요성, 변경 대상, 외부 영향, 되돌리는 방법을 설명하고 사용자가 개별 승인한 항목만 수행합니다.

### 최적화 전에 선택 가능

- Git 버전 관리
- 항목별 전용 증거 원장
- 대규모 사이트 페이지 유형 표본화

### 95점 게이트 통과 후 선택 가능

- Vercel Preview·Production 배포
- Google Search Console 소유권 확인과 사이트맵 제출
- Bing Webmaster Tools 등록과 사이트맵 제출

한 기능의 승인은 다른 외부 작업의 승인을 의미하지 않습니다.

## 요구 사항

- Aside가 설치되어 있고 한 번 이상 실행되어 계정 폴더가 생성되어 있어야 합니다.
- 기본 Aside 계정 경로:
  - macOS: `~/.aside/u/0`
  - Windows: `%USERPROFILE%\.aside\u\0`
- 다른 계정 경로를 사용한다면 설치 명령의 `--account-root` 또는 `-AccountRoot` 옵션을 사용하십시오.

## macOS 설치

### Git으로 설치

```bash
git clone --branch v1.0.0 --depth 1 https://github.com/Deuk1718/GAS-Optimizer.git
cd GAS-Optimizer
chmod +x install.sh uninstall.sh
./install.sh
```

다른 Aside 계정 경로에 설치하려면:

```bash
./install.sh --account-root "/path/to/.aside/u/ACCOUNT_ID"
```

### Git 없이 설치

[GitHub Releases](https://github.com/Deuk1718/GAS-Optimizer/releases/latest)에서 Source code 압축 파일을 내려받아 압축을 푼 뒤 터미널에서 해당 폴더로 이동하고 다음을 실행합니다.

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

## Windows 설치

### Git으로 설치

PowerShell에서 실행합니다.

```powershell
git clone --branch v1.0.0 --depth 1 https://github.com/Deuk1718/GAS-Optimizer.git
Set-Location GAS-Optimizer
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

PowerShell 7을 사용한다면 마지막 명령을 다음처럼 실행할 수 있습니다.

```powershell
pwsh -File .\install.ps1
```

다른 Aside 계정 경로에 설치하려면:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -AccountRoot "C:\path\to\.aside\u\ACCOUNT_ID"
```

`-ExecutionPolicy Bypass`는 해당 PowerShell 프로세스에만 적용되며 시스템 실행 정책을 영구 변경하지 않습니다. 실행 전에 설치 스크립트 내용을 검토하는 것을 권장합니다.

### Git 없이 설치

[GitHub Releases](https://github.com/Deuk1718/GAS-Optimizer/releases/latest)에서 Source code ZIP을 내려받아 압축을 푼 뒤, 해당 폴더에서 `install.ps1`을 실행합니다.

## 설치 동작과 업데이트

설치기는 다음 세 파일만 Aside 계정의 `skills/user/gas-optimizer`에 복사합니다.

- `SKILL.md`
- `references/quality-rubric.md`
- `assets/analysis-plan-template.html`

기존 설치가 있으면 삭제 전에 다음 경로에 자동 백업합니다.

```text
<Aside account root>/backups/skills/gas-optimizer-<UTC timestamp>
```

업데이트는 새 버전을 내려받거나 새 태그를 체크아웃한 뒤 설치기를 다시 실행하면 됩니다. 설치 후에는 Aside를 다시 시작하거나 새 세션을 시작하여 스킬 목록을 새로 불러오십시오.

## 설치 확인

macOS:

```bash
test -f ~/.aside/u/0/skills/user/gas-optimizer/SKILL.md && echo "installed"
```

Windows PowerShell:

```powershell
Test-Path "$HOME\.aside\u\0\skills\user\gas-optimizer\SKILL.md"
```

## 제거

제거할 때도 현재 설치본을 먼저 백업합니다.

macOS:

```bash
./uninstall.sh
```

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall.ps1
```

자동화 환경에서는 macOS의 `--yes` 또는 Windows의 `-Yes` 옵션으로 확인 질문을 생략할 수 있습니다.

## 사용 예시

Aside에서 다음과 같이 요청할 수 있습니다.

```text
이 정적 사이트를 GAS-Optimizer 기준으로 분석해줘.
```

```text
이 SSG 프로젝트의 SEO, GEO, AEO와 웹 품질을 각각 95점 이상이 되도록 최적화하고 싶어. 우선 분석만 진행해줘.
```

스킬은 먼저 분석 보고서를 만들고 승인을 요청합니다. 분석 승인과 계획 승인 전에는 프로젝트 소스 최적화를 시작하지 않습니다.

## 저장소 구성

```text
GAS-Optimizer/
├── README.md
├── LICENSE
├── VERSION
├── install.sh
├── install.ps1
├── uninstall.sh
├── uninstall.ps1
├── .github/workflows/validate.yml
└── skill/gas-optimizer/
    ├── SKILL.md
    ├── references/quality-rubric.md
    └── assets/analysis-plan-template.html
```

## 보안과 한계

- 설치기는 Aside 계정 루트 밖에 파일을 쓰지 않습니다.
- 기존 스킬은 덮어쓰기 전에 자동 백업합니다.
- 심볼릭 링크 또는 예상과 다른 스킬은 자동으로 제거하지 않습니다.
- GAS-Optimizer의 점수는 근거가 확인된 감사 결과이며 검색 순위, 트래픽, AI 인용 또는 색인 등록을 보장하지 않습니다.
- 실제 배포, GitHub 푸시, Search Console, Bing 등록은 사용자가 선택하고 승인한 경우에만 수행합니다.

## 라이선스

[MIT License](LICENSE)로 공개합니다.

---

**English summary:** GAS-Optimizer is an Aside user skill for evidence-based SEO, GEO, AEO, accessibility, performance, and deployment-readiness optimization of static, SSG, and SSR websites. Each domain must independently score at least 95/100. macOS and Windows installers are included.
