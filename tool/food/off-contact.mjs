/** Explicit private runtime contact for OFF; never infer it from a repository URL. */
export function offResearchUserAgent(contactEmail) {
  if (typeof contactEmail !== 'string' || contactEmail.length > 254 ||
      !/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$/.test(contactEmail) ||
      !validParts(contactEmail)) {
    throw new Error('OFF collector requires a valid SOFRA_OFF_CONTACT_EMAIL runtime configuration; no request made.');
  }
  return `SofraResearch/0.1 (${contactEmail})`;
}

function validParts(email) {
  const [local, domain] = email.split('@');
  return local.length <= 64 && !local.startsWith('.') && !local.endsWith('.') &&
    !local.includes('..') && domain.split('.').every(label =>
      /^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$/.test(label));
}
