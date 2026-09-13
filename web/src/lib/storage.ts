import { openDB, type DBSchema, type IDBPDatabase } from 'idb'

interface HealthCheckRecord {
  id: string
  checkedAt: string
}

interface HealthCheckDB extends DBSchema {
  healthchecks: {
    key: string
    value: HealthCheckRecord
  }
}

let dbPromise: Promise<IDBPDatabase<HealthCheckDB>> | null = null

function getDB() {
  if (!dbPromise) {
    dbPromise = openDB<HealthCheckDB>('research-app-wt1', 1, {
      upgrade(db) {
        db.createObjectStore('healthchecks', { keyPath: 'id' })
      },
    })
  }
  return dbPromise
}

/**
 * Writes a record to IndexedDB, reads it back, and returns it — proves the
 * SQLite-on-mobile equivalent (local persistence) actually round-trips in
 * this browser. Browser-only: IndexedDB doesn't exist under plain Node.
 */
export async function storageRoundTrip(): Promise<HealthCheckRecord> {
  const db = await getDB()
  const record: HealthCheckRecord = { id: 'wt1-check', checkedAt: new Date().toISOString() }
  await db.put('healthchecks', record)
  const readBack = await db.get('healthchecks', record.id)
  if (!readBack) {
    throw new Error('IndexedDB round-trip failed: wrote a record but could not read it back')
  }
  return readBack
}
