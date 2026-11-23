import { CognitoIdentityProviderClient, ListUsersCommand } from '@aws-sdk/client-cognito-identity-provider';
import { createPreSignUpHandler } from './sign-up-rules.mjs';

const client = new CognitoIdentityProviderClient({});

// Only an account that finished email verification owns the address, so an
// unverified sign-up cannot block the real mailbox owner.
async function findVerifiedUsernameByEmail(userPoolId, email) {
  const { Users = [] } = await client.send(new ListUsersCommand({
    UserPoolId: userPoolId, Filter: `email = "${email.replaceAll('"', '')}"`, Limit: 60,
  }));
  const verified = Users.find((user) => user.Attributes?.some(
    (attribute) => attribute.Name === 'email_verified' && attribute.Value === 'true',
  ));
  return verified?.Username ?? null;
}

export const handler = createPreSignUpHandler({
  allowedDomains: (process.env.ALLOWED_EMAIL_DOMAINS ?? '')
    .split(',').map((domain) => domain.trim().toLowerCase()).filter(Boolean),
  findUsernameByEmail: findVerifiedUsernameByEmail,
});
