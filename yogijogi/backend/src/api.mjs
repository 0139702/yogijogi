import { randomUUID } from 'node:crypto';
import { handleMyReportRequest } from './my_reports.mjs';

function respond(statusCode, body) {
  return {
    statusCode,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify(body),
  };
}

function readReport(event) {
  try {
    const raw = event.isBase64Encoded
      ? Buffer.from(event.body ?? '', 'base64').toString('utf8')
      : event.body;
    const data = JSON.parse(raw);
    const fields = {};
    for (const [name, maxLength] of [['type', 60], ['location', 120], ['description', 1000]]) {
      const value = data?.[name];
      if (typeof value !== 'string' || !value.trim() || value.trim().length > maxLength) {
        return null;
      }
      fields[name] = value.trim();
    }
    if (typeof data.occurredAt !== 'string' || !Number.isFinite(Date.parse(data.occurredAt))) {
      return null;
    }
    return { ...fields, occurredAt: new Date(data.occurredAt).toISOString() };
  } catch {
    return null;
  }
}

export function createHandler(store, { environment, reportsEnabled }) {
  return async (event) => {
    const { method } = event.requestContext.http;
    const path = event.rawPath;
    if (method === 'GET' && path === '/health') {
      return respond(200, { status: 'ok', environment, reportsEnabled });
    }
    const myReportResponse = await handleMyReportRequest(method, path);
    if (myReportResponse) return myReportResponse;
    const match = /^\/reports(?:\/([a-f0-9-]{36}))?$/.exec(path);
    if (!match) return respond(404, { error: 'not_found' });
    if (!reportsEnabled) return respond(403, { error: 'reports_disabled' });

    const [, id] = match;
    try {
      if (method === 'GET' && !id) {
        return respond(200, { items: await store.list() });
      }
      if (method === 'GET' && id) {
        const item = await store.get(id);
        return item ? respond(200, item) : respond(404, { error: 'not_found' });
      }
      if ((method === 'POST' && !id) || (method === 'PUT' && id)) {
        const fields = readReport(event);
        if (!fields) return respond(400, { error: 'invalid_report' });
        const updatedAt = new Date().toISOString();
        if (id) {
          const item = await store.update(id, { ...fields, updatedAt });
          return item ? respond(200, item) : respond(404, { error: 'not_found' });
        }
        const item = {
          ...fields, id: randomUUID(), status: 'received', source: 'user_report',
          createdAt: updatedAt, updatedAt,
        };
        await store.create(item);
        return respond(201, item);
      }
      return respond(405, { error: 'method_not_allowed' });
    } catch (error) {
      console.error('Report storage operation failed', error.name);
      return respond(500, { error: 'internal_error' });
    }
  };
}
