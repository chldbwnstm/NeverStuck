[English](README.md) | **한국어** | [简体中文](README.zh-CN.md)

# NeverStuck

에이전트가 같은 문제에서 열 번 넘게 실패할 때, 열한 번째 시도를 다르게 만들어주는 스킬.
바이브 튜닝을 반복하는 대신 근본 원인을 진단한다.

https://github.com/user-attachments/assets/025ec4f2-b782-45ae-bae1-8e3158c80fc4

[English introduction video](README.md)

"값 좀 다시 맞춰줘"를 반복해 본 적 있다면 이 스킬을 쓸 만하다. 루프는 프롬프트가
**증상을 고치라고** 시키기 때문에 생긴다. 모델이 멍청해서 생기는 게 아니다. NeverStuck은 stuck을
감지하고, 다음 프롬프트를 **메커니즘을 설명하라**는 요구로 바꾼다.

> 컨텍스트마다 다시 튜닝해야 하는 파라미터는 상수가 아니다 —
> 변하는 무언가의 함수가 스칼라로 오인된 것이다.

> NeverStuck의 핵심 원리이자, 발화 조건이자, 수용 기준

도메인은 가리지 않는다.

## 설치 — 에이전트에게 맡기기

내 컴퓨터에서 실행되는 세션을 연다 — Claude Code(터미널, IDE, 또는 데스크톱 앱 Code 탭의 Local
세션) 또는 Codex(CLI, IDE, 앱 — 클라우드가 아니라 이 컴퓨터에서 작업). 그리고 이렇게 보낸다:

```text
지금 쓰고 있는 에이전트에 NeverStuck 스킬을 설치해줘.
https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/INSTALL.md 를
내려받아 요약이 아닌 전체를 읽고, 그대로 따라 설치를 대신 해줘. 이 에이전트에만 한 번
설치하고, 이미 설치돼 있으면 사본을 하나 더 만들지 말고 그 설치를 업데이트해줘. 어디에
설치했는지, 어떻게 호출하는지, 재시작이 필요한지 알려줘.
```

에이전트가 파일 세 개를 스킬 폴더에 복사하고 확인한다. 앱이 설치 허락을 물으면 허락한다.
NeverStuck이 바로 보이지 않으면 새 세션을 시작한다.

| 에이전트 | 설치 위치 | 호출 |
|---|---|---|
| Claude Code | `~/.claude/skills/neverstuck/` (또는 `$CLAUDE_CONFIG_DIR/skills/neverstuck/`) | `/neverstuck "문제"` |
| Codex | `~/.agents/skills/neverstuck/` | `$neverstuck` 또는 `/skills` |

**업데이트:** 같은 메시지를 다시 보낸다. **삭제:** 대신 이렇게 보낸다:

```text
지금 쓰고 있는 에이전트에서 NeverStuck을 제거해줘.
https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/INSTALL.md 를
내려받아 요약이 아닌 전체를 읽고, "Updating and uninstalling" 절을 따라줘.
```

한 프로젝트에만, 또는 두 에이전트 모두에 설치하고 싶으면 설치 메시지를 그렇게 고쳐서 보낸다.
완전한 설치는 `SKILL.md`, `PROTOCOL.md`, `examples/teampoint-laser-pointer.md` 세 파일이 든 폴더
하나이고 에이전트가 따르는 절차는 [INSTALL.md](INSTALL.md)에 있다.

## 사용 예

```
/neverstuck "test_order_export가 CI에서만 간헐적으로 실패해. 타임아웃을
세 번(5초, 10초, 20초로) 올렸는데, 그때마다 며칠 가다가 또 실패해."
```

돌아오는 것 (요약 — 전체 리포트는 [examples/flaky-ci-test.md](examples/flaky-ci-test.md)):

```
[발화 확인] 같은 노브(타임아웃) 3회 조정 + "됐다가 다시 깨짐" → 진행.

[인터뷰 — 질문 ≤5개, 한 메시지]
실패 로그는 TimeoutError야, 다른 에러야? / 로컬과 CI는 뭐가 달라? /
원시 로그 있어? / 아직 안 본 곳은?

[UNSTUCK REPORT]
A. 진단 — 튜닝하던 노브가 인과 경로에 없다: 실패는 타임아웃이 아니라
   행 개수 불일치. 모든 시도가 공유한 미검증 가정 = "실패 = 느려서".
B. 가설 — H1 같은 샤드의 형제 테스트가 같은 테이블을 씀 (공유 상태)
          H2 리소스 경합 → 로그(카운트 불일치)가 기각.
          H3 코드 내부의 진짜 경쟁 상태 → 약화 (단독 실행에선 안 깨짐).
C. 재작성 프롬프트 — 타임아웃 변경 금지. "5→10→20초가 각각 왜 며칠씩은
   먹혔는지"를 역예측하는 메커니즘 요구.
D. 실험 1개 — 형제 테스트와 하나씩 같은 샤드에 고정 실행.
   특정 형제와만 재현 ⇒ H1 / 어느 것과도 재현 안 됨 ⇒ H3 재검토.
```

D를 실행한 뒤: `test_bulk_import`와 10/10 재현 → 테스트별 스키마 격리로 수정, 타임아웃은
5초로 원복.

## 왜 이 스킬이 필요한가

### #1: "값 좀 다시 맞춰줘"는 절대 수렴하지 않는다

실화: 서드파티 SDK의 정규화 좌표를 픽셀로 매핑하는데 X축이 세션마다 15~60px씩 어긋났다.
개발자는 10세션 넘게 에이전트에게 오차 로그를 주며 X_SCALE을 0.85 → 0.90 → 0.95로
튜닝시켰다. 매번 그 세션에서는 맞았고 다음 세션에서 깨졌다. 답을 SDK 내부 고정 750×500
캔버스의 기하학에서 *유도하면* **2/3** = 500/750이라는 상수가 나온다. 더 나은 추측값을 찾으려고
0.9 근처를 아무리 튜닝해도 닿을 수 없는 값이었다.
([워크드 예제](examples/teampoint-laser-pointer.md)는 이 사례를 이상화된 모델로 재구성한 것이다.)

**The Fix.** 같은 노브를 3번 조정하고도 실패하면 NeverStuck은 노브 조정을 **금지**하고
이렇게 요구한다: *"왜 '맞는 값'이 세션마다 달라지는지부터 설명해. 네 설명은 과거 튜닝이
각각 왜 한 번씩은 먹혔는지 역예측해야 해."* 이 요구를 통과하는 답은 메커니즘뿐이다.

### #2: 치료제는 이미 답변 안에 있었다 — 버려졌을 뿐

소규모 blind 실험에서 (Opus 5·Sonnet 5, 2026-08, arm당 1회·합성 데이터):

> 두 모델 모두 첫 접촉에서 letterbox 가설과 "무엇을 측정해야 하는지"를 스스로 도출했다.
> 그러나 답변에는 "급하면 이 값" 임시방편도 함께 들어 있었다 — 바쁜 인간은 숫자만 채택하고
> 진단을 버린다. 그 순간 10세션 루프가 시작된다.
>
> — NeverStuck 실험 노트 (8-arm, 각 1회, Opus 5·Sonnet 5)

**The Fix.** NeverStuck은 답변 속 임시값에 `[loop-bait]` 태그를 붙이고 임시값을 무효화할
실험에 묶는다. 숫자를 집어갈 때도 임시값이라는 표시와 실험이 함께 남는다.

### #3: 데이터를 더 줘도 못 푸는 이유

같은 실험의 역설적 관찰 (arm당 1회라 법칙이 아니라 힌트):

> Sonnet 5는 원시 데이터가 풍부한 조건에서 함정에 빠졌고(피팅해서 상수 하나 내고 사고 정지),
> 데이터가 전혀 없는 조건에서 탈출했다. 숫자는 "풀 수 있는 것"을 주고, 말로 서술된 증상의
> 형태는 "설명해야 하는 것"을 준다.

**The Fix.** NeverStuck의 인터뷰는 데이터 수집에 그치지 않고 **시그니처의 언어화**를 요구한다:
무엇이 틀리고 무엇이 *유독 멀쩡한지*, 실패가 무엇과 함께 변하고 무엇과는 안
변하는지. 네 문장이 가설 공간의 대부분을 잘라낸다.

## 스킬

**User- or model-invoked**

- **[neverstuck](skills/neverstuck/SKILL.md)** — 반복-실패 루프 탈출. 같은 수정 부류 3회+
  실패, "됐다가 다시 깨짐", 유도 근거 없는 상수 튜닝, 또는 반복 실패에 대한 좌절("아직도 안
  돼", "또 그러네")에 사용. 첫 실패에는 발화하지 않는다.

**호출하면 일어나는 일**

1. **발화 억제 우선** — 3회 게이트 + 하드 시그널 S7("맞는 값이 컨텍스트마다 달랐나?" — dev/prod
   처럼 의도된 환경별 설정은 제외) + 취향-경계 가드. stuck이 아니면 그렇게 말하고 빠진다.
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
- **[INSTALL.md](INSTALL.md)** — 에이전트가 NeverStuck을 설치할 때 따르는 절차: 세 파일,
  설치 위치, 확인 방법.
- **[examples/teampoint-laser-pointer.md](examples/teampoint-laser-pointer.md)** — 모티브
  사례: 실제 10+세션 루프를 프로토콜 2턴 실행으로 재구성 (one-shot 시연용).
- **[examples/flaky-ci-test.md](examples/flaky-ci-test.md)** — 타임아웃 튜닝 루프. 노브가
  숫자가 아니어도 구조는 같다.
- **[examples/llm-prompt-loop.md](examples/llm-prompt-loop.md)** — 막힌 것이 프롬프트 자체인
  경우 (도그푸딩) + 취향-경계 각주.
- **[adapters/prompt-doctor/TEMPLATE.md](adapters/prompt-doctor/TEMPLATE.md)** — 설치 없이
  아무 챗에나 복붙하는 버전.

## 품질 보증

적합성 테스트: `PROTOCOL.md` + 새 도메인의 Stuck Packet을 임의의 주류 모델에 붙여넣어
①A/B/C/D 4섹션 ②가설=메커니즘 ③기존 노브의 새 값 없음 ④실험 정확히 1개 — 를 확인한다.
2026-08-06, 예제에 없는 ETL 페이지네이션 케이스로 Opus 5·Sonnet 5 각 1회 실행 **2/2 통과**
(1위 가설 = 숨겨둔 정답). 이 패킷은 저장소에 없다. 다시 돌려볼 수 있는 케이스는
[`conformance/CASES.md`](conformance/CASES.md)에 있다 — 리포트를 *내면 안 되는* 경우(아직 stuck
아님, 취향)와 임시값 태그 확인 포함. 주류 모델이 실패하면 어댑터를 특화하지 말고 프로토콜을
단순화할 것.

---

정본은 루트 `PROTOCOL.md`, `adapters/claude-code/SKILL.md`, `examples/teampoint-laser-pointer.md`.
저장소 내 복사본(`.claude/skills/`, `.agents/skills/`, `skills/`)은 `install.ps1 -Sync` /
`./install.sh sync`로 동기화하고, 어긋나면 CI가 실패한다. 스킬을 바꾸면
`.claude-plugin/plugin.json`의 `version`을 올릴 것 — 플러그인 사용자는 새 버전만 받는다.
전역 설치본(`~/.claude/skills/`)이 저장소 복사본보다 우선하므로, 로컬 변경을 시험하려면
에이전트에게 체크아웃에서 NeverStuck을 다시 설치해 달라고 하거나(INSTALL.md 3단계), 체크아웃에서
`./install.sh claude`(또는 `.\install.ps1 -Target claude`)를 실행한다.

[MIT](LICENSE) 라이선스.
