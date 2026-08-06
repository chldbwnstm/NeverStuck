[English](README.md) | **한국어** | [简体中文](README.zh-CN.md)

# NeverStuck

에이전트가 같은 문제에서 열 번 넘게 실패할 때, 열한 번째 시도를 다르게 만들어주는 스킬 —
바이브 튜닝이 아니라 근본 원인 진단.

"값 좀 다시 맞춰줘"를 반복해 본 적 있다면 이 스킬은 당신 것이다. 그 루프는 모델이 멍청해서
생기는 게 아니다. 프롬프트가 **증상을 고치라고** 시키기 때문에 생긴다. NeverStuck은 stuck을
감지하고, 다음 프롬프트를 **메커니즘을 설명하라**는 요구로 바꾼다.

> 컨텍스트마다 다시 튜닝해야 하는 파라미터는 상수가 아니다 —
> 변하는 무언가의 함수가 스칼라로 오인된 것이다.

> NeverStuck의 핵심 원리이자, 발화 조건이자, 수용 기준

도메인은 가리지 않는다.

## 설치 (30초 세팅)

**Claude Code**

```
/plugin marketplace add chldbwnstm/NeverStuck
/plugin install neverstuck@neverstuck
```

**Codex 및 기타 에이전트**

```bash
npx skills@latest add chldbwnstm/NeverStuck
```

**스크립트로 (Claude Code + Codex 전역 동시 설치)**

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.sh | bash
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1 | iex
```

**팅커러용**

클론하면 끝 — 저장소 안에서는 Claude Code(`.claude/skills/`)와 Codex(`.agents/skills/`)가
스킬을 자동 인식한다. 자기 프로젝트에 넣으려면 두 폴더를 복사해 커밋하면 협업자 전원
자동 적용. 에이전트가 아예 없으면 [`PROTOCOL.md`](PROTOCOL.md) +
[`TEMPLATE.md`](adapters/prompt-doctor/TEMPLATE.md)를 아무 챗에나 복붙해도 된다 — 프로토콜은
순수 텍스트라 어디서든 같다.

| 에이전트 | 전역 설치 경로 | 호출 |
|---|---|---|
| Claude Code | `~/.claude/skills/neverstuck/` | `/neverstuck "문제"` |
| Codex (CLI/IDE) | `~/.agents/skills/neverstuck/` | `$neverstuck` 또는 `/skills` |

## 왜 이 스킬이 필요한가

### #1: "값 좀 다시 맞춰줘"는 절대 수렴하지 않는다

실화: 서드파티 SDK의 정규화 좌표를 픽셀로 매핑하는데 X축이 세션마다 15~60px씩 어긋났다.
개발자는 10세션 넘게 에이전트에게 오차 로그를 주며 X_SCALE을 0.85 → 0.90 → 0.95로
튜닝시켰다. 매번 그 세션에서는 맞았고, 다음 세션에서 깨졌다. 진짜 답은 SDK 내부의 고정
750×500 캔버스가 letterbox되며 생기는 상수 **2/3** — 값이 아니라 기하학이었다.

**The Fix.** 같은 노브를 3번 조정하고도 실패하면, NeverStuck은 그 노브를 **금지**하고
이렇게 요구한다: *"왜 '맞는 값'이 세션마다 달라지는지부터 설명해. 네 설명은 과거 튜닝이
각각 왜 한 번씩은 먹혔는지 역예측해야 해."* 이 요구를 통과하는 답은 메커니즘뿐이다.

### #2: 치료제는 이미 답변 안에 있었다 — 버려졌을 뿐

실측 결과 (Opus 5·Sonnet 5 blind 실험, 2026-08):

> 두 모델 모두 첫 접촉에서 letterbox 가설과 "무엇을 측정해야 하는지"를 스스로 도출했다.
> 그러나 답변에는 "급하면 이 값" 임시방편도 함께 들어 있었다 — 바쁜 인간은 숫자만 채택하고
> 진단을 버린다. 그 순간 10세션 루프가 시작된다.
>
> — NeverStuck 실증 실험 기록 (8-arm, Opus 5·Sonnet 5)

**The Fix.** NeverStuck은 답변 속 임시값에 `[loop-bait]` 태그를 붙이고, 그것을 무효화할
실험에 묶는다. 숫자를 집어가는 것은 막지 않는다 — 다만 **눈 뜨고 집어가게** 만든다.

### #3: 데이터를 더 줘도 못 푸는 이유

같은 실험의 역설적 발견:

> Sonnet 5는 원시 데이터가 풍부한 조건에서 함정에 빠졌고(피팅해서 상수 하나 내고 사고 정지),
> 데이터가 전혀 없는 조건에서 탈출했다. 숫자는 "풀 수 있는 것"을 주고, 말로 서술된 증상의
> 형태는 "설명해야 하는 것"을 준다.

**The Fix.** NeverStuck의 인터뷰는 데이터 수집이 아니라 **시그니처의 언어화**를 강제한다:
무엇이 틀리고, 무엇이 *conspicuously 멀쩡하고*, 실패가 무엇과 함께 변하고, 무엇과는 안
변하는가. 이 네 문장이 가설 공간의 90%를 잘라낸다.

## 스킬

**User-invoked**

- **[neverstuck](skills/neverstuck/SKILL.md)** — 반복-실패 루프 탈출. 같은 수정 부류 3회+
  실패, "됐다가 다시 깨짐", 유도 근거 없는 상수 튜닝, 또는 반복 실패에 대한 좌절("아직도 안
  돼", "또 그러네")에 사용. 첫 실패에는 발화하지 않는다.

**호출하면 일어나는 일**

1. **발화 억제 우선** — 3회 게이트 + 하드 시그널 S7("맞는 값이 컨텍스트마다 달랐나?") +
   취향-경계 가드. stuck이 아니면 그렇게 말하고 빠진다.
2. **Stuck Packet 인터뷰** (질문 ≤5개, 한 메시지) — 시도 이력 → 증상의 형태 → 컨텍스트 간
   차이 → 원시 데이터 → 아직 안 본 것.
3. **Unstuck Report** — A 진단 / B 근본원인 가설 2~3 (값이 아니라 모델) / C 재작성 프롬프트
   (같은 노브의 새 값 금지) / D **실험 정확히 1개** (가설별 판정 규칙 사전 선언).
4. **2라운드 안에 안 풀리면 정직하게 에스컬레이션** — 계측 → 서드파티 소스 읽기(grep 문자열
   제공) → 통제 프로브 → 사람에게 묻기(질문 초안 제공). "프롬프팅은 블랙박스 안의 사실을
   복원할 수 없다"는 것을 인정하는 것도 프로토콜의 일부다.

## 레퍼런스

- **[PROTOCOL.md](PROTOCOL.md)** — 스킬 그 자체. 도메인 중립, 순수 자연어, 어떤 LLM에든
  붙여넣기 가능. 나머지는 전부 이것의 어댑터다.
- **[examples/teampoint-laser-pointer.md](examples/teampoint-laser-pointer.md)** — 모티브
  사례: 10+세션 루프 → 2턴 종결 (one-shot 시연용).
- **[examples/flaky-ci-test.md](examples/flaky-ci-test.md)** — 타임아웃 튜닝 루프. 노브가
  숫자가 아니어도 구조는 같다.
- **[examples/llm-prompt-loop.md](examples/llm-prompt-loop.md)** — 막힌 것이 프롬프트 자체인
  경우 (도그푸딩) + 취향-경계 각주.
- **[adapters/prompt-doctor/TEMPLATE.md](adapters/prompt-doctor/TEMPLATE.md)** — 설치 없이
  아무 챗에나 복붙하는 버전.

## 품질 보증

적합성 테스트: `PROTOCOL.md` + 새 도메인의 Stuck Packet을 임의의 주류 모델에 붙여넣어
①A/B/C/D 4섹션 ②가설=메커니즘 ③기존 노브의 새 값 없음 ④실험 정확히 1개 — 를 확인한다.
2026-08-06, 예제에 없는 ETL 페이지네이션 케이스로 Opus 5·Sonnet 5 **2/2 통과** (1위 가설 =
숨겨둔 정답). 주류 모델이 실패하면 어댑터를 특화하지 말고 프로토콜을 단순화할 것.

---

정본은 루트 `PROTOCOL.md`와 `adapters/claude-code/SKILL.md`. 저장소 내 복사본
(`.claude/skills/`, `.agents/skills/`, `skills/`)은 `install.ps1 -Sync` /
`./install.sh sync`로 동기화한다.
