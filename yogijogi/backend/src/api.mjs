import { randomUUID } from 'node:crypto';
import { handleClassroomRequest } from './classrooms.mjs';
import { handleMyReportRequest } from './my_reports.mjs';

export const PHOTO_LIMIT = 3;
export const PHOTO_MAX_BYTES = 5 * 1024 * 1024;
export const PHOTO_TYPES = ['image/jpeg', 'image/png'];

function respond(statusCode, body) {
  return {
    statusCode,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify(body),
  };
}

function readJson(event) {
  try {
    const raw = event.isBase64Encoded
      ? Buffer.from(event.body ?? '', 'base64').toString('utf8')
      : event.body;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function readReport(event) {
  const data = readJson(event);
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
}

function readPhotoRequest(event) {
  const data = readJson(event);
  const { contentType, size } = data ?? {};
  if (!PHOTO_TYPES.includes(contentType)) return null;
  if (!Number.isInteger(size) || size <= 0 || size > PHOTO_MAX_BYTES) return null;
  return { contentType, size };
}

const photoKey = (reportId, photoId) => `reports/${reportId}/${photoId}`;

export function createHandler(store, { environment, reportsEnabled, photoStorage = null }) {
  // Storage keys stay on the server; clients only get a short-lived URL per photo.
  async function present(item, event) {
    const photos = await Promise.all((item.photos ?? []).map(async (photo) => ({
      id: photo.id,
      url: await photoStorage.getUrl(photo.key, event),
      createdAt: photo.createdAt,
    })));
    return { ...item, photos };
  }

  async function handlePhotos(event, method, report, photoId, complete) {
    if (!photoStorage) return respond(501, { error: 'photos_unavailable' });
    const photos = report.photos ?? [];

    if (method === 'POST' && !photoId) {
      if (photos.length >= PHOTO_LIMIT) return respond(409, { error: 'photo_limit_reached' });
      const fields = readPhotoRequest(event);
      if (!fields) return respond(400, { error: 'invalid_photo' });
      const id = randomUUID();
      const upload = await photoStorage.createUpload(photoKey(report.id, id), fields, event);
      return respond(201, { photoId: id, upload });
    }

    if (method === 'POST' && photoId && complete) {
      if (photos.some((photo) => photo.id === photoId)) return respond(200, await present(report, event));
      if (photos.length >= PHOTO_LIMIT) return respond(409, { error: 'photo_limit_reached' });
      const key = photoKey(report.id, photoId);
      const stored = await photoStorage.head(key);
      if (!stored) return respond(404, { error: 'upload_not_found' });
      if (!PHOTO_TYPES.includes(stored.contentType) || stored.size > PHOTO_MAX_BYTES) {
        await photoStorage.remove(key);
        return respond(400, { error: 'invalid_photo' });
      }
      const photo = {
        id: photoId, key, contentType: stored.contentType, size: stored.size,
        createdAt: new Date().toISOString(),
      };
      const item = await store.update(report.id, { photos: [...photos, photo] });
      return item ? respond(200, await present(item, event)) : respond(404, { error: 'not_found' });
    }

    if (method === 'DELETE' && photoId && !complete) {
      const photo = photos.find((candidate) => candidate.id === photoId);
      if (!photo) return respond(404, { error: 'not_found' });
      await photoStorage.remove(photo.key);
      const item = await store.update(report.id, {
        photos: photos.filter((candidate) => candidate.id !== photoId),
      });
      return item ? respond(200, await present(item, event)) : respond(404, { error: 'not_found' });
    }

    return respond(405, { error: 'method_not_allowed' });
  }

  return async (event) => {
    const { method } = event.requestContext.http;
    const path = event.rawPath;
    if (method === 'GET' && path === '/health') {
      return respond(200, { status: 'ok', environment, reportsEnabled });
    }
    const classroomResponse = handleClassroomRequest(method, path);
    if (classroomResponse) return classroomResponse;
    const myReportResponse = await handleMyReportRequest(method, path);
    if (myReportResponse) return myReportResponse;
    const match = /^\/reports(?:\/([a-f0-9-]{36})(?:\/photos(?:\/([a-f0-9-]{36})(\/complete)?)?)?)?$/.exec(path);
    if (!match) return respond(404, { error: 'not_found' });
    if (!reportsEnabled) return respond(403, { error: 'reports_disabled' });

    const [, id, photoId, complete] = match;
    const isPhotoPath = path.includes('/photos');
    try {
      if (isPhotoPath) {
        const report = await store.get(id);
        if (!report) return respond(404, { error: 'not_found' });
        return await handlePhotos(event, method, report, photoId, Boolean(complete));
      }
      if (method === 'GET' && !id) {
        const items = await store.list();
        return respond(200, {
          items: photoStorage ? await Promise.all(items.map((item) => present(item, event))) : items,
        });
      }
      if (method === 'GET' && id) {
        const item = await store.get(id);
        if (!item) return respond(404, { error: 'not_found' });
        return respond(200, photoStorage ? await present(item, event) : item);
      }
      if ((method === 'POST' && !id) || (method === 'PUT' && id)) {
        const fields = readReport(event);
        if (!fields) return respond(400, { error: 'invalid_report' });
        const updatedAt = new Date().toISOString();
        if (id) {
          const item = await store.update(id, { ...fields, updatedAt });
          if (!item) return respond(404, { error: 'not_found' });
          return respond(200, photoStorage ? await present(item, event) : item);
        }
        const item = {
          ...fields, id: randomUUID(), status: 'received', source: 'user_report',
          createdAt: updatedAt, updatedAt,
        };
        await store.create(item);
        return respond(201, photoStorage ? await present(item, event) : item);
      }
      return respond(405, { error: 'method_not_allowed' });
    } catch (error) {
      console.error('Report storage operation failed', error.name);
      return respond(500, { error: 'internal_error' });
    }
  };
}
