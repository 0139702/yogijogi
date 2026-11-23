import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createPreSignUpHandler, SIGN_UP_ERRORS } from './sign-up-rules.mjs';

function event(userName, email) {
  return { userName, userPoolId: 'pool', request: { userAttributes: { email } } };
}

function handlerWith(existing = {}) {
  return createPreSignUpHandler({
    allowedDomains: ['sungshin.ac.kr'],
    findUsernameByEmail: async (_, email) => existing[email] ?? null,
  });
}

test('accepts a school email with a valid username', async () => {
  const input = event('yogi_123', 'Student@Sungshin.ac.kr');
  assert.equal(await handlerWith()(input), input);
});

test('rejects other email domains, including look-alikes', async () => {
  for (const email of ['a@gmail.com', 'a@evil-sungshin.ac.kr', 'a@sungshin.ac.kr.com', 'sungshin.ac.kr']) {
    await assert.rejects(handlerWith()(event('yogi_123', email)), { message: SIGN_UP_ERRORS.invalidDomain });
  }
});

test('rejects usernames outside 4-20 lowercase letters, digits, underscore', async () => {
  for (const name of ['abc', 'a'.repeat(21), 'yogi-123', '요기조기']) {
    await assert.rejects(handlerWith()(event(name, 'a@sungshin.ac.kr')), { message: SIGN_UP_ERRORS.invalidUsername });
  }
});

test('rejects an email already used by another account', async () => {
  const handler = handlerWith({ 'a@sungshin.ac.kr': 'someone' });
  await assert.rejects(handler(event('yogi_123', 'a@sungshin.ac.kr')), { message: SIGN_UP_ERRORS.emailTaken });
});
