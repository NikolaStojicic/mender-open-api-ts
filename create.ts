import create from 'openapi-fetch';

const API_URL = 'https://eu.hosted.mender.io/api/management';

const TOKEN = 'Bearer <api_key>';

export const createClient = <T extends object>(path: string) =>
  create<T>({
    baseUrl: API_URL + path,
    headers: {
      Authorization: TOKEN,
      'Content-Type': 'application/json',
    },
  });
