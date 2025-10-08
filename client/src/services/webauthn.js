import { startRegistration, startAuthentication } from '@simplewebauthn/browser';
import * as api from './api';

export async function registerBiometric() {
  try {
    const options = await api.getRegisterOptions();
    const credential = await startRegistration(options);
    await api.verifyRegistration(credential, options.challenge);
    return { success: true };
  } catch (error) {
    console.error('WebAuthn registration failed:', error);
    throw error;
  }
}

export async function authenticateBiometric() {
  try {
    const options = await api.getAuthenticateOptions();
    const credential = await startAuthentication(options);
    await api.verifyAuthentication(credential, options.challenge);
    return { success: true };
  } catch (error) {
    console.error('WebAuthn authentication failed:', error);
    throw error;
  }
}

export function isWebAuthnAvailable() {
  return window.PublicKeyCredential !== undefined && navigator.credentials !== undefined;
}
