// Administrative setup uses the existing Firebase CLI login; never exports credentials.
const { getGlobalDefaultAccount } = require('firebase-tools/lib/auth');
const { requireAuth } = require('firebase-tools/lib/requireAuth');
const { ensure } = require('firebase-tools/lib/ensureApiEnabled');
const { Client } = require('firebase-tools/lib/apiv2');
const project = 'sofra-c03a1';
async function main() {
  const account = getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI login required');
  await requireAuth({project, ...account});
  const action = process.argv[2];
  if (action === 'apis') {
    for (const api of ['firestore.googleapis.com', 'identitytoolkit.googleapis.com']) {
      await ensure(project, api, 'Sofra');
    }
    console.log('Required APIs ready. No billing operation requested.');
    return;
  }
  const client = new Client({urlPrefix:'https://identitytoolkit.googleapis.com', apiVersion:'admin/v2'});
  if (action === 'auth-enable') {
    await client.patch(`/projects/${project}/config`, {
      signIn: {email: {enabled: true, passwordRequired: true}},
    }, {queryParams: {updateMask:'signIn.email'}, skipLog:{reqBody:true,resBody:true}});
  }
  const result = await client.get(`/projects/${project}/config`, {skipLog:{resBody:true}});
  console.log(JSON.stringify({project, email:result.body.signIn?.email, subtype:result.body.subtype,
    authorizedDomains:result.body.authorizedDomains}, null, 2));
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
