// Cognito returns these codes to the app inside UserLambdaValidationException.
export const SIGN_UP_ERRORS = {
  invalidUsername: 'INVALID_USERNAME',
  invalidDomain: 'INVALID_EMAIL_DOMAIN',
  emailTaken: 'EMAIL_TAKEN',
};

const USERNAME_PATTERN = /^[a-z0-9_]{4,20}$/;

export function createPreSignUpHandler({ allowedDomains, findUsernameByEmail }) {
  return async (event) => {
    const username = event.userName.toLowerCase();
    const email = (event.request.userAttributes.email ?? '').trim().toLowerCase();
    if (!USERNAME_PATTERN.test(username)) throw new Error(SIGN_UP_ERRORS.invalidUsername);

    const at = email.lastIndexOf('@');
    if (at <= 0 || !allowedDomains.includes(email.slice(at + 1))) {
      throw new Error(SIGN_UP_ERRORS.invalidDomain);
    }

    const owner = await findUsernameByEmail(event.userPoolId, email);
    if (owner && owner.toLowerCase() !== username) throw new Error(SIGN_UP_ERRORS.emailTaken);
    return event;
  };
}
