import { readFile } from 'node:fs/promises';
import { test, before, after } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, getDocs, query, where,
  arrayUnion, arrayRemove, deleteField, serverTimestamp, Timestamp,
} from 'firebase/firestore';
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

// ---- Shared kitchen and community (26 Oct 2026) ----------------------------

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const state = (revision) => ({ revision, data: { schema: 1, name: 'Test', stock: [] }, updatedAt: serverTimestamp() });
const inDays = (d) => Timestamp.fromMillis(Date.now() + d * 86400000);
const join = (code, extra = {}) => ({ members: arrayUnion('bob'), 'names.bob': 'Bob', joinedWith: code, ...extra });

async function sharedKitchen(kid) {
  await assertSucceeds(setDoc(doc(db('alice'), `kitchens/${kid}`), {
    owner: 'alice', members: ['alice'], names: { alice: 'Alice' }, createdAt: serverTimestamp(),
  }));
  await assertSucceeds(setDoc(doc(db('alice'), `kitchens/${kid}/state/current`), state(1)));
  await assertSucceeds(setDoc(doc(db('alice'), 'users/alice/membership/current'), { kitchenId: kid }));
}

test('shared kitchen: invite, join, write together, leave', async () => {
  await env.clearFirestore();
  await sharedKitchen('k1');
  // Nobody else sees it before joining.
  await assertFails(getDoc(doc(db('bob'), 'kitchens/k1')));
  await assertFails(getDoc(doc(db('bob'), 'kitchens/k1/state/current')));
  // A kitchen cannot be created for someone else.
  await assertFails(setDoc(doc(db('bob'), 'kitchens/k9'), {
    owner: 'alice', members: ['alice'], names: { alice: 'A' }, createdAt: serverTimestamp(),
  }));
  // Bob cannot point his membership at a kitchen he is not in.
  await assertFails(setDoc(doc(db('bob'), 'users/bob/membership/current'), { kitchenId: 'k1' }));
  // Only members create invites, for at most a week, with a valid code.
  await assertFails(setDoc(doc(db('bob'), 'invites/ABCDEFGH'), { kitchenId: 'k1', by: 'bob', expiresAt: inDays(7) }));
  await assertFails(setDoc(doc(db('alice'), 'invites/ABCDEFGH'), { kitchenId: 'k1', by: 'alice', expiresAt: inDays(30) }));
  await assertFails(setDoc(doc(db('alice'), 'invites/ABCDEFGI'), { kitchenId: 'k1', by: 'alice', expiresAt: inDays(7) }));
  await assertSucceeds(setDoc(doc(db('alice'), 'invites/ABCDEFGH'), { kitchenId: 'k1', by: 'alice', expiresAt: inDays(7) }));
  // Codes are fetched by exact value, never listed.
  await assertSucceeds(getDoc(doc(db('bob'), 'invites/ABCDEFGH')));
  await assertFails(getDocs(collection(db('bob'), 'invites')));
  // Joining needs a real code; a join may only add yourself.
  await assertFails(updateDoc(doc(db('bob'), 'kitchens/k1'), join('ZZZZZZZZ')));
  await assertFails(updateDoc(doc(db('bob'), 'kitchens/k1'), join('ABCDEFGH', { members: arrayUnion('bob', 'eve') })));
  await assertFails(updateDoc(doc(db('bob'), 'kitchens/k1'), join('ABCDEFGH', { owner: 'bob' })));
  await assertSucceeds(updateDoc(doc(db('bob'), 'kitchens/k1'), join('ABCDEFGH')));
  await assertSucceeds(setDoc(doc(db('bob'), 'users/bob/membership/current'), { kitchenId: 'k1' }));
  // Members share one state document with the same revision guard.
  await assertSucceeds(getDoc(doc(db('bob'), 'kitchens/k1/state/current')));
  await assertSucceeds(setDoc(doc(db('bob'), 'kitchens/k1/state/current'), state(2)));
  await assertFails(setDoc(doc(db('alice'), 'kitchens/k1/state/current'), state(2)));
  await assertSucceeds(setDoc(doc(db('alice'), 'kitchens/k1/state/current'), state(3)));
  await assertFails(getDoc(doc(db('eve'), 'kitchens/k1/state/current')));
  // A member cannot remove someone else; leaving removes only yourself.
  await assertFails(updateDoc(doc(db('bob'), 'kitchens/k1'), { members: arrayRemove('alice'), 'names.alice': deleteField() }));
  await assertSucceeds(updateDoc(doc(db('bob'), 'kitchens/k1'), { members: arrayRemove('bob'), 'names.bob': deleteField() }));
  await assertFails(getDoc(doc(db('bob'), 'kitchens/k1/state/current')));
  await assertSucceeds(deleteDoc(doc(db('bob'), 'users/bob/membership/current')));
});

test('expired invites do not open the kitchen', async () => {
  await env.clearFirestore();
  await sharedKitchen('k2');
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'invites/QRSTUVWX'), { kitchenId: 'k2', by: 'alice', expiresAt: inDays(-1) });
  });
  await assertFails(updateDoc(doc(db('bob'), 'kitchens/k2'), join('QRSTUVWX')));
});

test('community recipes, ratings, prices and challenge entries', async () => {
  await env.clearFirestore();
  const recipe = (author) => ({
    author, authorName: 'Alice', title: 'Koshari', cuisine: 'مصري', servings: 4,
    lines: [{ name: 'رز', amount: 1, unit: 'كوب' }], steps: ['اطبخ'], photos: [], createdAt: serverTimestamp(),
  });
  await assertFails(setDoc(doc(db(null), 'communityRecipes/alice-r1'), recipe('alice')));
  await assertFails(setDoc(doc(db('bob'), 'communityRecipes/alice-r1'), recipe('bob')));
  await assertFails(setDoc(doc(db('alice'), 'communityRecipes/alice-r1'), { ...recipe('alice'), photos: [{ path: 'photos/alice/a.webp', by: 'alice' }] }));
  await assertSucceeds(setDoc(doc(db('alice'), 'communityRecipes/alice-r1'), recipe('alice')));
  await assertSucceeds(getDoc(doc(db('bob'), 'communityRecipes/alice-r1')));
  await assertFails(setDoc(doc(db('bob'), 'communityRecipes/alice-r1'), recipe('alice')));

  const rating = (stars) => ({ name: 'Bob', stars, comment: 'حلوة', at: serverTimestamp() });
  await assertFails(setDoc(doc(db('bob'), 'communityRecipes/alice-r1/ratings/eve'), rating(5)));
  await assertFails(setDoc(doc(db('bob'), 'communityRecipes/alice-r1/ratings/bob'), rating(6)));
  await assertSucceeds(setDoc(doc(db('bob'), 'communityRecipes/alice-r1/ratings/bob'), rating(4)));

  const price = (uid) => ({ uid, country: 'EG', area: 'مدينه نصر', ingredientId: 'rice', quantity: 1, unit: 'kg', amount: 40, paidOn: '2026-10-26', createdAt: serverTimestamp() });
  await assertFails(addDoc(collection(db('bob'), 'priceReports'), price('alice')));
  await assertFails(addDoc(collection(db('bob'), 'priceReports'), { ...price('bob'), amount: -1 }));
  await assertSucceeds(addDoc(collection(db('bob'), 'priceReports'), price('bob')));
  await assertSucceeds(getDocs(query(collection(db('alice'), 'priceReports'), where('country', '==', 'EG'), where('area', '==', 'مدينه نصر'))));

  const entry = { name: 'بيت بوب', progress: 2, goal: 4, at: serverTimestamp() };
  await assertFails(setDoc(doc(db('bob'), 'challenges/2026-10-24/entries/alice'), entry));
  await assertFails(setDoc(doc(db('bob'), 'challenges/2026-10-24/entries/bob'), { ...entry, progress: 500 }));
  await assertSucceeds(setDoc(doc(db('bob'), 'challenges/2026-10-24/entries/bob'), entry));
  await assertSucceeds(getDocs(collection(db('alice'), 'challenges/2026-10-24/entries')));
});

test('stories: own, short, text-only, gone within a day', async () => {
  await env.clearFirestore();
  const story = (uid, extra = {}) => ({
    uid, name: 'بيت بوب', text: 'عملنا ملوخية النهارده', dish: 'ملوخية', color: 2, photos: [],
    createdAt: serverTimestamp(), expiresAt: Timestamp.fromMillis(Date.now() + 23 * 3600000), ...extra,
  });
  await assertFails(addDoc(collection(db(null), 'stories'), story('bob')));
  await assertFails(addDoc(collection(db('bob'), 'stories'), story('alice')));
  await assertFails(addDoc(collection(db('bob'), 'stories'), story('bob', { expiresAt: inDays(3) })));
  await assertFails(addDoc(collection(db('bob'), 'stories'), story('bob', { text: 'x'.repeat(201) })));
  await assertFails(addDoc(collection(db('bob'), 'stories'), story('bob', { photos: [{ path: 'photos/bob/a.webp', by: 'bob' }] })));
  const ref = await assertSucceeds(addDoc(collection(db('bob'), 'stories'), story('bob')));
  await assertSucceeds(getDocs(query(collection(db('alice'), 'stories'), where('expiresAt', '>', Timestamp.now()))));
  await assertFails(deleteDoc(doc(db('alice'), `stories/${ref.id}`)));
  await assertSucceeds(deleteDoc(doc(db('bob'), `stories/${ref.id}`)));
});
