// Disposable, synthetic accounts only. Does not send emails or inspect existing users.
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, signOut, signInWithEmailAndPassword, deleteUser } from 'firebase/auth';
import { getFirestore, doc, setDoc, getDocFromServer, serverTimestamp, terminate } from 'firebase/firestore';
const require = createRequire(import.meta.url);
const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { Client } = require('firebase-tools/lib/apiv2');
const config = JSON.parse(await readFile(new URL('../../config/firebase-web.js', import.meta.url), 'utf8'));
assert.equal(config.projectId, 'sofra-c03a1');
const apps = [], accounts = [], documents = [];
const password = randomBytes(24).toString('base64url');
try {
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI login required for test cleanup');
  await requireAuth({project: config.projectId, ...account});
  for (let i = 0; i < 2; i++) {
    const app = initializeApp(config, `smoke-${i}-${Date.now()}`);
    apps.push(app);
    const auth = getAuth(app);
    const email = `sofra-smoke-${randomBytes(10).toString('hex')}@example.com`;
    const {user} = await createUserWithEmailAndPassword(auth, email, password);
    accounts.push({auth, user, email});
  }
  const owner = accounts[0];
  const path = `users/${owner.user.uid}/state/current`;
  const ref = doc(getFirestore(apps[0]), path);
  documents.push(path);
  await setDoc(ref, {revision:1, data:{schema:1, name:'Sofra synthetic test', stock:[{id:'rice',quantity:500,zone:'pantry'}]}, updatedAt:serverTimestamp()});
  await signOut(owner.auth);
  await signInWithEmailAndPassword(owner.auth, owner.email, password);
  const restored = (await getDocFromServer(ref)).data();
  assert.equal(restored.data.stock[0].quantity, 500);
  assert.equal(restored.revision, 1);
  await assert.rejects(() => getDocFromServer(doc(getFirestore(apps[1]), path)), e => e.code === 'permission-denied');
  await assert.rejects(() => setDoc(ref, {...restored, updatedAt:serverTimestamp()}), e => e.code === 'permission-denied');
  console.log(JSON.stringify({signup:true,signIn:true,persistence:true,otherAccountBlocked:true,staleWriteBlocked:true}));
} catch (error) {
  console.error(error.code || error.message);
  process.exitCode = 1;
} finally {
  const client = new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
  for (const path of documents) {
    try { await client.delete(`/projects/${config.projectId}/databases/(default)/documents/${path}`, {skipLog:{resBody:true}}); }
    catch { console.error('Synthetic document cleanup failed'); process.exitCode = 1; }
  }
  for (const {auth} of accounts) {
    try { if (auth.currentUser) await deleteUser(auth.currentUser); }
    catch { console.error('Synthetic account cleanup failed'); process.exitCode = 1; }
  }
  for (const app of apps) { await terminate(getFirestore(app)); await deleteApp(app); }
}
