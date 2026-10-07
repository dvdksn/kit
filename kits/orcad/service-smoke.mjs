import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'
import { spawn, spawnSync } from 'node:child_process'
import { setTimeout } from 'node:timers/promises'

const start = '/usr/local/libexec/orcad-start'
const readyPath = join(homedir(), '.orca', 'kit-ready.jsonl')
const service = spawn(start, [], { stdio: 'inherit' })
const cli = '/tmp/orca-smoke/out/cli/index.js'
function pairing(endpoint) {
  const result = spawnSync('orcad', ['pairing-url', ...(endpoint ? [endpoint] : [])], {
    encoding: 'utf8', timeout: 35_000
  })
  assert.equal(result.status, 0, result.stderr)
  return result.stdout.trim()
}
function ready() {
  return JSON.parse(readFileSync(readyPath, 'utf8').trim())
}
function status(code) {
  const result = spawnSync(process.execPath, [cli, 'status', '--pairing-code', code, '--json'], {
    encoding: 'utf8', timeout: 15_000
  })
  assert.equal(result.status, 0, result.stderr)
  assert.notEqual(JSON.parse(result.stdout).ok, false)
}

try {
  const originalPairing = pairing()
  status(originalPairing)
  const originalPid = ready().health.pid
  const duplicate = spawnSync(start, [], { timeout: 3_000 })
  assert.equal(duplicate.status, 0, 'Startup must tolerate an already running service')
  assert.equal(ready().health.pid, originalPid)

  const rewritten = new URL(pairing('ws://127.0.0.1:16800'))
  const offer = JSON.parse(Buffer.from(rewritten.searchParams.get('code'), 'base64url'))
  assert.equal(offer.endpoint, 'ws://127.0.0.1:16800')

  process.kill(originalPid, 'SIGKILL')
  await setTimeout(300)
  pairing()
  assert.notEqual(ready().health.pid, originalPid, 'Service must restart after a crash')
  status(originalPairing)
  console.log('[orcad-service-smoke] startup, idempotence, crash recovery, saved pairing: PASS')
} finally {
  service.kill('SIGTERM')
  await Promise.race([
    new Promise(resolve => service.once('exit', resolve)),
    setTimeout(5_000).then(() => service.kill('SIGKILL'))
  ])
}
