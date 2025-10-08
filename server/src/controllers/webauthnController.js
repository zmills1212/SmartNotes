const {
  generateRegistrationOptions,
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse
} = require('@simplewebauthn/server');
const WebAuthnCredential = require('../models/WebAuthnCredential');
const User = require('../models/User');
const config = require('../config/env');

async function getRegisterOptions(req, res) {
  try {
    const user = await User.findById(req.user.userId);
    const options = await generateRegistrationOptions({
      rpName: config.RP_NAME,
      rpID: config.RP_ID,
      userID: user.id.toString(),
      userName: user.email,
      attestationType: 'none',
      authenticatorSelection: {
        authenticatorAttachment: 'platform',
        requireResidentKey: false,
        userVerification: 'preferred'
      }
    });
    res.json(options);
  } catch (error) {
    console.error('WebAuthn register options error:', error);
    res.status(500).json({ error: 'Failed to generate registration options' });
  }
}

async function verifyRegistration(req, res) {
  try {
    const { credential, challenge } = req.body;
    const verification = await verifyRegistrationResponse({
      response: credential,
      expectedChallenge: challenge,
      expectedOrigin: config.ORIGIN,
      expectedRPID: config.RP_ID
    });
    if (!verification.verified) return res.status(400).json({ error: 'Verification failed' });
    const { credentialPublicKey, credentialID, counter } = verification.registrationInfo;
    await WebAuthnCredential.create({
      user_id: req.user.userId,
      credential_id: Buffer.from(credentialID).toString('base64'),
      public_key: Buffer.from(credentialPublicKey).toString('base64'),
      counter,
      transports: credential.response.transports || []
    });
    res.json({ verified: true });
  } catch (error) {
    console.error('WebAuthn verification error:', error);
    res.status(500).json({ error: 'Registration verification failed' });
  }
}

async function getAuthenticateOptions(req, res) {
  try {
    const credentials = await WebAuthnCredential.findByUserId(req.user.userId);
    if (credentials.length === 0) return res.status(404).json({ error: 'No credentials registered' });
    const options = await generateAuthenticationOptions({
      rpID: config.RP_ID,
      allowCredentials: credentials.map(cred => ({
        id: Buffer.from(cred.credential_id, 'base64'),
        type: 'public-key',
        transports: cred.transports || []
      })),
      userVerification: 'preferred'
    });
    res.json(options);
  } catch (error) {
    console.error('WebAuthn auth options error:', error);
    res.status(500).json({ error: 'Failed to generate authentication options' });
  }
}

async function verifyAuthentication(req, res) {
  try {
    const { credential, challenge } = req.body;
    const credentialId = Buffer.from(credential.id, 'base64').toString('base64');
    const storedCredential = await WebAuthnCredential.findByCredentialId(credentialId);
    if (!storedCredential) return res.status(404).json({ error: 'Credential not found' });
    const verification = await verifyAuthenticationResponse({
      response: credential,
      expectedChallenge: challenge,
      expectedOrigin: config.ORIGIN,
      expectedRPID: config.RP_ID,
      authenticator: {
        credentialID: Buffer.from(storedCredential.credential_id, 'base64'),
        credentialPublicKey: Buffer.from(storedCredential.public_key, 'base64'),
        counter: storedCredential.counter
      }
    });
    if (!verification.verified) return res.status(400).json({ error: 'Authentication failed' });
    await WebAuthnCredential.updateCounter(storedCredential.credential_id, verification.authenticationInfo.newCounter);
    res.json({ verified: true });
  } catch (error) {
    console.error('WebAuthn auth verification error:', error);
    res.status(500).json({ error: 'Authentication verification failed' });
  }
}

module.exports = { getRegisterOptions, verifyRegistration, getAuthenticateOptions, verifyAuthentication };
