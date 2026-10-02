[English](README.md) | [한국어](README.ko.md) | **简体中文**

# NeverStuck

当你的智能体在同一个问题上失败了十多次，这个技能让第十一次尝试变得不一样 ——
做根因诊断，而不是凭感觉调参。

如果你反复输入过"再帮我调一下这个值"，这个技能就是为你准备的。那个死循环不是因为模型笨，
而是因为提示词在要求它**修补症状**。NeverStuck 检测到卡死状态后，会把你的下一条提示词改写成
**解释机制**的要求。

> 一个在每种上下文里都需要重新调整的参数不是常量 ——
> 它是某个变化量的函数，被误当成了标量。

> NeverStuck 的核心原理、触发条件、验收标准

不限领域。

## 安装（30 秒上手）

**Claude Code**

```
/plugin marketplace add chldbwnstm/NeverStuck
/plugin install neverstuck@neverstuck
```

用 `/neverstuck` 调用（也会显示为 `/neverstuck:neverstuck`）。更新：先运行
`/plugin marketplace update neverstuck`，再在 `/plugin` 里对该插件选 **Update now** ——
第三方市场默认不自动更新。在 shell 里则是先 `claude plugin marketplace update neverstuck`，
再 `claude plugin update neverstuck@neverstuck`。

**Codex 及其他智能体**

```bash
npx skills@latest add chldbwnstm/NeverStuck
```

更新时重新运行同一条命令 —— 仓库在多个文件夹里放了同一个技能，所以 `npx skills update`
可能会跳过它。

**脚本安装（一次装好 Claude Code + Codex 的用户全局）**

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.sh | bash
# one agent only: ... | bash -s -- claude   (or codex)
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1 | iex
# one agent only:
& ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1).Content)) -Target codex
```

更新就是重新运行同一行。每个智能体只选一种安装方式 —— 插件、npx、脚本或复制；装两次会留下
两份彼此漂移的副本。

**给爱折腾的人**

克隆即用 —— 在本仓库内，Claude Code（`.claude/skills/`）和 Codex（`.agents/skills/`）会
自动识别技能。想放进自己的项目，把这两个文件夹复制过去并提交，所有协作者自动获得。完全没有
智能体？把 [`PROTOCOL.md`](PROTOCOL.md) + [`TEMPLATE.md`](adapters/prompt-doctor/TEMPLATE.md)
粘贴进任何聊天窗口即可 —— 协议是纯文本，在哪里都一样。

| 智能体 | 用户全局安装路径 | 调用方式 |
|---|---|---|
| Claude Code | `~/.claude/skills/neverstuck/`（或 `$CLAUDE_CONFIG_DIR/skills/neverstuck/`） | `/neverstuck "问题"` |
| Codex (CLI/IDE) | `~/.agents/skills/neverstuck/` | `$neverstuck` 或 `/skills` |

完整安装是一个文件夹里同时有 `SKILL.md`、`PROTOCOL.md` 和 `examples/teampoint-laser-pointer.md`；
上面每种安装方式都会把这三个文件一起装好。手动复制时三个都要带上 —— 只有 `SKILL.md` 的话，它只是一个
指向 `PROTOCOL.md` 的说明。

## 使用示例

```
/neverstuck "test_order_export 只在 CI 里间歇性失败。我把超时先后
加到 5秒、10秒、20秒，一共三次，每次都撑几天然后又挂。"
```

你会得到（摘要 —— 完整报告见
[examples/flaky-ci-test.md](examples/flaky-ci-test.md)）：

```
[触发检查] 同一旋钮（超时）调了 3 次 + "好了又坏" → 启动。

[访谈 —— ≤5 个问题，一条消息]
失败日志是 TimeoutError 还是别的错误？/ 本地和 CI 有什么不同？/
有原始日志吗？/ 还有什么没查过？

[UNSTUCK REPORT]
A. 诊断 —— 你在调的旋钮根本不在因果链上：失败是行数不一致，
   不是超时。所有尝试共享的未验证假设 = "失败 = 太慢"。
B. 假说 —— H1 同一分片里的兄弟测试写了同一张表（共享状态）；
   H2 资源争用 → 被日志（行数不一致）否决；H3 代码内部的真实竞态 → 被削弱（单独运行从不失败）。
C. 改写后的提示词 —— 禁止再改超时。要求一个能回溯预测
   "为什么 5→10→20 秒各撑了几天"的机制。
D. 一个实验 —— 把该测试与每个兄弟测试逐一固定进同一分片运行。
   只与某一个兄弟测试同分片时复现 ⇒ H1；都不复现 ⇒ 重新检视 H3。
```

跑完 D 之后：与 `test_bulk_import` 同分片时 10/10 复现 → 按测试隔离 schema 修复，超时改回
5 秒。

## 为什么需要这个技能

### #1："再帮我调一下这个值"永远不会收敛

真实案例：把第三方 SDK 的归一化坐标映射到像素时，X 轴每个会话偏移 15~60px 且各不相同。
开发者在 10 多个会话里不断把误差日志喂给智能体，让它把 X_SCALE 从 0.85 → 0.90 → 0.95 地调。
每个值都在当时的会话里"对了"，下个会话又崩。真正的答案是 **2/3** = 500/750 —— 不是更好的
猜测值，而是从 SDK 内部固定的 750×500 画布*推导*出的常量，在 0.9 附近怎么调都碰不到。是几何，
不是值。（[示例](examples/teampoint-laser-pointer.md)用理想化模型重构了这个案例。）

**The Fix.** 同一个旋钮调了 3 次仍失败时，NeverStuck 会**禁用**这个旋钮并提出要求：
*"先解释为什么'正确的值'每个会话都不一样。你的解释必须能回溯预测过去每次调参为什么都恰好
灵了一次。"* 能通过这个考验的答案只有机制。

### #2：解药早就在回答里 —— 只是被扔掉了

来自一次小规模盲测（Opus 5 / Sonnet 5，2026-08；每组 1 次、合成数据）：

> 两个模型都在首次接触时就自行推导出了 letterbox 假说和"应该测量什么"。但回答里同时也给了
> "急用的话先拿这个值"的权宜之计 —— 忙碌的人只把数字拿走，把诊断扔掉。10 个会话的死循环
> 就从那一刻开始。
>
> —— NeverStuck 实验笔记（8 个实验组，各 1 次，Opus 5 / Sonnet 5）

**The Fix.** NeverStuck 会给回答中的权宜值打上 `[loop-bait]` 标签，并把它绑定到能让它作废的
那个实验上。它不拦着你拿数字 —— 只保证你是**睁着眼睛**拿的。

### #3：为什么给再多数据也解不开

同一实验的悖论式观察（每组只跑 1 次 —— 是线索，不是定律）：

> Sonnet 5 在原始数据充足的条件下掉进了陷阱（拟合出一个常量后停止思考），却在完全没有数据的
> 条件下成功逃脱。数字给模型的是"可以解的东西"，而用语言描述的症状形态给它的是"必须解释的
> 东西"。

**The Fix.** NeverStuck 的访谈强制的不是数据收集，而是**把症状特征用语言说出来**：
什么坏了、什么*反常地完好*、失败随什么变化、又与什么无关。这四句话能砍掉大部分假设空间。

## 技能

**User- or model-invoked**

- **[neverstuck](skills/neverstuck/SKILL.md)** —— 逃出反复失败的死循环。适用于同类修复失败
  3 次以上、"好了又坏"、在没有推导依据的情况下调常量、或对反复失败感到挫败（"还是不行"、
  "又来了"）时。首次失败不会触发。

**调用后会发生什么**

1. **先抑制误触发** —— 3 次门槛 + 硬信号 S7（"'正确的值'是否随上下文而不同？"——dev/prod 这类
   有意按环境区分的设置不算）+ 品味边界守卫。如果其实没卡住，它会直说并退出。
2. **Stuck Packet 访谈**（≤5 个问题，一条消息内）—— 尝试历史 → 症状形态 → 上下文之间的
   差异 → 原始数据 → 还没看过的东西。
3. **Unstuck Report** —— A 诊断 / B 根因假说 2~3 个（是模型，不是值）/ C 改写后的提示词
   （绝不给同一旋钮提新值）/ D **恰好一个实验**（每个假说的判定规则提前声明）。
4. **两轮解不开就诚实升级** —— 加测量 → 读第三方源码（提供 grep 字符串）→ 受控探针 →
   问人（提供提问草稿）。承认"提示词无法还原只存在于黑盒内部的事实"本身就是协议的一部分。

## 参考

- **[PROTOCOL.md](PROTOCOL.md)** —— 技能本体。领域中立、纯自然语言、可粘贴进任何 LLM。
  其余一切都是它的适配器。
- **[examples/teampoint-laser-pointer.md](examples/teampoint-laser-pointer.md)** —— 起源
  案例：真实的 10+ 会话死循环，按协议重构为 2 轮的运行（one-shot 示范用）。
- **[examples/flaky-ci-test.md](examples/flaky-ci-test.md)** —— 超时调参死循环。旋钮不是
  数字时结构也一样。
- **[examples/llm-prompt-loop.md](examples/llm-prompt-loop.md)** —— 卡住的东西是提示词本身
  的情况（自产自用）+ 品味边界脚注。
- **[adapters/prompt-doctor/TEMPLATE.md](adapters/prompt-doctor/TEMPLATE.md)** —— 零安装、
  粘贴进任何聊天即用的版本。

## 质量保证

一致性测试：把 `PROTOCOL.md` + 一个新领域的 Stuck Packet 粘贴给任意主流模型，检查
① A/B/C/D 四节齐全 ② 假说是机制而非值 ③ 没有给原旋钮提新值 ④ 恰好一个实验。
2026-08-06，用一个不在示例中的 ETL 分页案例在 Opus 5 和 Sonnet 5 上各跑 1 次，**2/2 通过**
（排名第一的假说 = 隐藏的真实答案）；该 packet 不在仓库里。可重复运行的案例见
[`conformance/CASES.md`](conformance/CASES.md)，其中包括*不应*产出报告的情况（还没卡住、品味问题）
和权宜值标签的检查。若主流模型未通过，应简化协议，而不是特化适配器。

---

规范源是仓库根目录的 `PROTOCOL.md`、`adapters/claude-code/SKILL.md` 与
`examples/teampoint-laser-pointer.md`。仓库内的副本（`.claude/skills/`、`.agents/skills/`、
`skills/`）用 `install.ps1 -Sync` / `./install.sh sync` 同步，不一致时 CI 会失败。技能有改动时，
请提升 `.claude-plugin/plugin.json` 里的 `version` —— 插件用户只会收到新版本。用户全局安装
（`~/.claude/skills/`）优先于仓库内副本，所以本地测试 `/neverstuck` 前，请在检出目录里运行
`./install.sh`（或 `.\install.ps1`）—— 一行命令安装的是 GitHub 上的 `master` —— 或者删除
`~/.claude/skills/neverstuck` 后运行 `./install.sh sync`（或 `.\install.ps1 -Sync`）。

采用 [MIT](LICENSE) 许可证。
