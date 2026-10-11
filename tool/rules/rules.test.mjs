import { readFile } from 'node:fs/promises';
import { test, before, after } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-sofra-rules',
    firestore: { rules: await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => { await env?.cleanup(); });
test('owner alone can read/write and revision must advance exactly once', async () => {
  const path = 'users/alice/state/current';
  const owner = doc(env.authenticatedContext('alice').firestore(), path);
  const other = doc(env.authenticatedContext('bob').firestore(), path);
  const guest = doc(env.unauthenticatedContext().firestore(), path);
  const payload = (revision) => ({ revision, data: { schema: 1, name: 'Test', stock: [] }, updatedAt: serverTimestamp() });
  await assertFails(setDoc(guest, payload(1)));
  await assertFails(setDoc(other, payload(1)));
  await assertSucceeds(setDoc(owner, payload(1)));
  await assertSucceeds(getDoc(owner));
  await assertFails(getDoc(other));
  await assertFails(getDoc(guest));
  await assertFails(setDoc(owner, payload(1)));
  await assertSucceeds(setDoc(owner, payload(2)));
  await assertFails(setDoc(owner, {...payload(3), unexpected: true}));
  await assertFails(setDoc(doc(env.authenticatedContext('alice').firestore(), 'public/data'), payload(1)));
});
