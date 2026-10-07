import { readFile } from 'node:fs/promises'
import { join } from 'node:path'
import { homedir } from 'node:os'
import { setTimeout } from 'node:timers/promises'

const endpoint = process.argv[2]
if (process.argv.length > 3 || (endpoint && !/^wss?:$/.test(new URL(endpoint).protocol))) {
  throw new Error('Usage: orcad pairing-url [ws://host:port]')
}
const readinessPath = join(homedir(), '.orca', 'kit-ready.jsonl')
const deadline = Date.now() + 30_000
while (Date.now() < deadline) {
  try {
    const lines = (await readFile(readinessPath, 'utf8')).trim().split('\n')
    const ready = lines.map(line => JSON.parse(line)).find(item => item.type === 'orca_server_ready')
    if (ready?.health?.pid && ready.pairing?.url) {
      process.kill(ready.health.pid, 0)
      const url = new URL(ready.pairing.url)
      if (endpoint) {
        const offer = JSON.parse(Buffer.from(url.searchParams.get('code'), 'base64url'))
        offer.endpoint = endpoint
        url.searchParams.set('code', Buffer.from(JSON.stringify(offer)).toString('base64url'))
      }
      console.log(url.toString())
      process.exit(0)
    }
  } catch {
    // Startup may not have written a complete ready message yet.
  }
  await setTimeout(200)
}
console.error('Orcad is not ready; check ~/.orca/kit-service.log')
process.exit(1)
