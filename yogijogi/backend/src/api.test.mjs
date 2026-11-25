import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHandler, PHOTO_LIMIT, PHOTO_MAX_BYTES } from './api.mjs';

function setup({ withPhotos = true } = {}) {
  const items = new Map();
  const files = new Map();
  const store = {
    async list() { return [...items.values()]; },
    async get(id) { return items.get(id); },
    async create(item) { items.set(item.id, item); },
    async update(id, fields) {
      if (!items.has(id)) return null;
      items.set(id, { ...items.get(id), ...fields });
      return items.get(id);
    },
    async remove(id) { items.delete(id); },
  };
  const photoStorage = {
    async createUpload(key, fields) { return { method: 'PUT', url: `upload:${key}`, headers: {}, fields }; },
    async head(key) { return files.get(key) ?? null; },
    async getUrl(key) { return `photo:${key}`; },
    async remove(key) { files.delete(key); },
  };
  const handler = createHandler(store, {
    environment: 'test', reportsEnabled: true, photoStorage: withPhotos ? photoStorage : null,
  });
  const call = async (method, rawPath, body, userId = 'user-1') => {
    const result = await handler({
      rawPath,
      headers: userId ? { 'x-user-id': userId } : {},
      requestContext: { http: { method } },
      body: body && JSON.stringify(body),
    });
    return { status: result.statusCode, body: JSON.parse(result.body) };
  };
  return { call, files, items };
}

const report = {
  type: '벌레 몬스터', location: '학생회관 (1F)', description: '설명',
  occurredAt: '2026-11-20T08:00:00Z',
};

async function createReport(call) {
  return (await call('POST', '/reports', report)).body;
}

async function addPhoto(call, files, reportId, stored = { contentType: 'image/jpeg', size: 1000 }) {
  const issued = await call('POST', `/reports/${reportId}/photos`, { contentType: 'image/jpeg', size: 1000 });
  assert.equal(issued.status, 201);
  files.set(`reports/${reportId}/${issued.body.photoId}`, stored);
  return call('POST', `/reports/${reportId}/photos/${issued.body.photoId}/complete`);
}

test('attaches an uploaded photo and exposes only its URL', async () => {
  const { call, files } = setup();
  const { id } = await createReport(call);
  const completed = await addPhoto(call, files, id);
  assert.equal(completed.status, 200);
  assert.equal(completed.body.photos.length, 1);
  assert.match(completed.body.photos[0].url, /^photo:reports\//);
  assert.equal(completed.body.photos[0].key, undefined);

  const listed = await call('GET', '/reports');
  assert.equal(listed.body.items[0].photos.length, 1);
});

test('rejects completing an upload that never happened', async () => {
  const { call } = setup();
  const { id } = await createReport(call);
  const issued = await call('POST', `/reports/${id}/photos`, { contentType: 'image/jpeg', size: 1000 });
  const completed = await call('POST', `/reports/${id}/photos/${issued.body.photoId}/complete`);
  assert.equal(completed.status, 404);
});

test('validates photo type, size, and count', async () => {
  const { call, files } = setup();
  const { id } = await createReport(call);
  for (const body of [
    { contentType: 'image/gif', size: 1000 },
    { contentType: 'image/jpeg', size: PHOTO_MAX_BYTES + 1 },
    { contentType: 'image/jpeg', size: 0 },
  ]) {
    assert.equal((await call('POST', `/reports/${id}/photos`, body)).status, 400);
  }
  for (let i = 0; i < PHOTO_LIMIT; i++) await addPhoto(call, files, id);
  const extra = await call('POST', `/reports/${id}/photos`, { contentType: 'image/jpeg', size: 1000 });
  assert.equal(extra.status, 409);
});

test('discards a stored file whose real type is not allowed', async () => {
  const { call, files } = setup();
  const { id } = await createReport(call);
  const completed = await addPhoto(call, files, id, { contentType: 'text/html', size: 10 });
  assert.equal(completed.status, 400);
  assert.equal(files.size, 0);
});

test('deletes a photo from the report and storage', async () => {
  const { call, files } = setup();
  const { id } = await createReport(call);
  const photoId = (await addPhoto(call, files, id)).body.photos[0].id;
  const deleted = await call('DELETE', `/reports/${id}/photos/${photoId}`);
  assert.equal(deleted.status, 200);
  assert.deepEqual(deleted.body.photos, []);
  assert.equal(files.size, 0);
});

test('keeps photos when the report text is edited', async () => {
  const { call, files } = setup();
  const { id } = await createReport(call);
  await addPhoto(call, files, id);
  const edited = await call('PUT', `/reports/${id}`, { ...report, description: '수정' });
  assert.equal(edited.body.photos.length, 1);
});

test('reports photos as unavailable without photo storage', async () => {
  const { call } = setup({ withPhotos: false });
  const { id } = await createReport(call);
  const issued = await call('POST', `/reports/${id}/photos`, { contentType: 'image/jpeg', size: 1000 });
  assert.equal(issued.status, 501);
});

test('records the author and lets only the author edit', async () => {
  const { call } = setup();
  const created = await createReport(call);
  assert.equal(created.authorId, 'user-1');

  const edit = { ...report, description: '수정' };
  assert.equal((await call('PUT', `/reports/${created.id}`, edit, 'user-2')).status, 403);
  assert.equal((await call('PUT', `/reports/${created.id}`, edit, null)).status, 401);
  assert.equal((await call('PUT', `/reports/${created.id}`, edit)).status, 200);
});

test('requires a user to create a report', async () => {
  const { call } = setup();
  assert.equal((await call('POST', '/reports', report, null)).status, 401);
});

test('lets only the author change photos', async () => {
  const { call } = setup();
  const { id } = await createReport(call);
  const body = { contentType: 'image/jpeg', size: 1000 };
  assert.equal((await call('POST', `/reports/${id}/photos`, body, 'user-2')).status, 403);
});

test('lets the author delete a report before handling starts, with its photos', async () => {
  const { call, files } = setup();
  const { id } = await createReport(call);
  await addPhoto(call, files, id);

  assert.equal((await call('DELETE', `/reports/${id}`, undefined, 'user-2')).status, 403);
  assert.equal((await call('DELETE', `/reports/${id}`, undefined, null)).status, 401);
  assert.equal((await call('DELETE', `/reports/${id}`)).status, 200);
  assert.equal((await call('GET', `/reports/${id}`)).status, 404);
  assert.equal(files.size, 0);
});

test('keeps a report once handling has started', async () => {
  const { call, items } = setup();
  const { id } = await createReport(call);
  items.set(id, { ...items.get(id), status: 'in_progress' });
  const deleted = await call('DELETE', `/reports/${id}`);
  assert.equal(deleted.status, 409);
  assert.equal(deleted.body.error, 'report_in_progress');
  assert.equal((await call('GET', `/reports/${id}`)).status, 200);
});
