// opencode-preset: managed
// Lightweight non-blocking /btw side-session plugin.
// Inspired by the ephemeral-session pattern used by opencode-advisor.

const MAX_CONTEXT_CHARS = 60000
const MAX_ANSWER_CHARS = 12000

const BTW_SYSTEM = `You are answering a by-the-way question while another coding agent continues the user's main task.

Use the supplied conversation context and repository tools when useful. Answer only the side question. Be concise, concrete, and self-contained. Do not ask follow-up questions and do not modify the user's files.`

function unwrap<T = any>(value: any): T {
  return (value?.data ?? value) as T
}

function textParts(parts: any[] | undefined): string {
  return (parts ?? [])
    .filter((part) => part?.type === "text" && typeof part.text === "string")
    .map((part) => part.text)
    .join("\n")
}

function configuredModel() {
  const raw = typeof process !== "undefined" ? process.env.OPENCODE_BTW_MODEL : undefined
  if (!raw || !raw.includes("/")) return undefined
  const [providerID, ...rest] = raw.split("/")
  return { providerID, modelID: rest.join("/") }
}

async function messages(client: any, sessionID: string) {
  try {
    return unwrap<any[]>(await client.session.messages({ sessionID })) ?? []
  } catch {
    return unwrap<any[]>(await client.session.messages({ path: { id: sessionID } })) ?? []
  }
}

async function createSession(client: any) {
  try {
    return unwrap<any>(await client.session.create({}))
  } catch {
    return unwrap<any>(await client.session.create({ body: {} }))
  }
}

async function deleteSession(client: any, sessionID: string) {
  try {
    await client.session.delete({ sessionID })
  } catch {
    await client.session.delete({ path: { id: sessionID } })
  }
}

async function prompt(client: any, sessionID: string, body: any) {
  try {
    return unwrap<any>(await client.session.prompt({ sessionID, ...body }))
  } catch {
    return unwrap<any>(await client.session.prompt({ path: { id: sessionID }, body }))
  }
}

function deriveModel(history: any[]) {
  const override = configuredModel()
  if (override) return override

  for (let index = history.length - 1; index >= 0; index -= 1) {
    const info = history[index]?.info
    if (!info) continue
    if (info.model?.providerID && info.model?.modelID) return info.model
    if (info.providerID && info.modelID) {
      return { providerID: info.providerID, modelID: info.modelID }
    }
  }
  return undefined
}

function transcript(history: any[]): string {
  const blocks = history
    .filter((message) => {
      if (message?.info?.role !== "user") return true
      return !textParts(message.parts).trimStart().toLowerCase().startsWith("/btw")
    })
    .map((message) => {
      const body = textParts(message.parts).trim()
      if (!body) return ""
      const role = message?.info?.role === "user" ? "User" : "Assistant"
      return `${role}: ${body}`
    })
    .filter(Boolean)

  const joined = blocks.join("\n\n")
  return joined.length <= MAX_CONTEXT_CHARS ? joined : joined.slice(-MAX_CONTEXT_CHARS)
}

export const BtwPlugin = async ({ client }: any) => {
  const running = new Set<string>()

  async function run(sessionID: string, question: string) {
    const key = `${sessionID}:${Date.now()}:${Math.random()}`
    running.add(key)
    let childID: string | undefined

    try {
      const history = await messages(client, sessionID)
      const model = deriveModel(history)
      const context = transcript(history)
      const child = await createSession(client)
      childID = child?.id
      if (!childID) throw new Error("OpenCode returned no child session id")

      const request: any = {
        agent: "preset-btw",
        system: BTW_SYSTEM,
        parts: [
          {
            type: "text",
            text: `${context ? `CONVERSATION CONTEXT\n${context}\n\n` : ""}SIDE QUESTION\n${question}`,
          },
        ],
      }
      if (model) request.model = model

      const answer = await prompt(client, childID, request)
      const answerText = textParts(answer?.parts).trim() || "BTW completed without a text response."
      const clipped = answerText.slice(0, MAX_ANSWER_CHARS)

      await prompt(client, sessionID, {
        noReply: true,
        parts: [
          {
            type: "text",
            text: `---\n**BTW: ${question}**\n\n${clipped}\n---`,
          },
        ],
      })
    } catch (error) {
      const detail = error instanceof Error ? error.message : String(error)
      try {
        await prompt(client, sessionID, {
          noReply: true,
          parts: [{ type: "text", text: `---\n**BTW failed:** ${detail}\n---` }],
        })
      } catch {
        console.error("opencode-preset btw:", error)
      }
    } finally {
      running.delete(key)
      if (childID) await deleteSession(client, childID).catch(() => undefined)
    }
  }

  return {
    "command.execute.before": async (input: any, output: any) => {
      if (input.command !== "btw") return

      const question = String(input.arguments ?? "").trim()
      const replacement = question
        ? `BTW dispatched in the background: ${question}\nContinue the current task; do not answer the side question in this session.`
        : "BTW requires a question. Usage: /btw <question>"

      if (Array.isArray(output.parts)) {
        output.parts.splice(0, output.parts.length, { type: "text", text: replacement })
      }

      if (!question) return
      void run(input.sessionID, question)
    },
  }
}

export default BtwPlugin
